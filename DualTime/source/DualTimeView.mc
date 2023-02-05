import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

/**
* Main view of the application.
*/
class DualTimeView extends WatchUi.WatchFace {
    // Default variables
    var defaultTimezone = "United Kingdom";
    var defaultTimezoneCode = "GB";
    var defaultTimezoneLatitude = 51.5;
    var defaultTimezoneLongtitude = -0.0833;
    var timeFormat = "$1$:$2$";

    // System variables
    var is24Hour;

    // Resource variables (From storage or JSON)
    var secondaryTimezoneCode;
    var secondaryTimezoneLatitude;
    var secondaryTimezoneLongtitude;

    // Color variables
    var backgroundColor;
    var foregroundColor;

    // Dimension variables
    var widthScreen;
    var heightScreen;
    var timeDividerWidth = 2;
    var timeDividerMarginRight = 10;
    var batteryWidth = 20;
    var batteryIconHeight = 10;
    var batteryPinWidth = 2;
    var batteryIconPinHeight = 5;
    var primaryTimeMarginRight = 10;
    var secondaryTimeMarginBottom = 3;

    // Font variables
    var primaryTimeFont = Graphics.FONT_SYSTEM_NUMBER_MEDIUM;
    var secondaryTimeFont = Graphics.FONT_TINY;
    var dateFont = Graphics.FONT_XTINY;

    // Other variables
    var timezoneDiffSecs;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // Get screen dimensions
        widthScreen = dc.getWidth();
        heightScreen = dc.getHeight();

        // Get negativeDisplay setting from storage (watch menu)
        var negativeDisplay = Storage.getValue("negativeDisplay") ? true : false;

        // Set the background/foreground colors
        if (negativeDisplay == true) {
            backgroundColor = Graphics.COLOR_BLACK;
            foregroundColor = Graphics.COLOR_WHITE;
        } else {
            backgroundColor = Graphics.COLOR_WHITE;
            foregroundColor = Graphics.COLOR_BLACK;
        }

        is24Hour = System.getDeviceSettings().is24Hour;

        // Get secondaryTimezone settings from storage (watch menu)
        secondaryTimezoneCode = Storage.getValue("secondaryTimezoneCode") ? Storage.getValue("secondaryTimezoneCode") : defaultTimezoneCode;
        secondaryTimezoneLatitude = Storage.getValue("secondaryTimezoneLatitude") ? Storage.getValue("secondaryTimezoneLatitude") : defaultTimezoneLatitude;
        secondaryTimezoneLongtitude = Storage.getValue("secondaryTimezoneLongtitude") ? Storage.getValue("secondaryTimezoneLongtitude") : defaultTimezoneLongtitude;

        // Generate a position object based on the selected secondary timezone
        var secondaryLocation = new Position.Location({
            :latitude  => secondaryTimezoneLatitude,
            :longitude => secondaryTimezoneLongtitude,
            :format    => :degrees,
        });

        timezoneDiffSecs = getLocationTimeOffset(secondaryLocation);
    }

    function onUpdate(dc as Dc) as Void {
        // Clear the screen before updating
        dc.setColor(Graphics.COLOR_TRANSPARENT, backgroundColor as Number);
        dc.clear();

        var clockTime = System.getClockTime();

        // Primary time details
        var primaryTimeString = getPrimaryTimeString(clockTime);
        var primaryTimeStringWidth = dc.getTextWidthInPixels(primaryTimeString, primaryTimeFont);
        var primaryTimeStringHeight = dc.getFontHeight(primaryTimeFont);
        // Device specific pixel offset
        var primaryTimeStringHeightOffset = WatchUi.loadResource(Rez.Strings.primaryTimeStringHeightOffset);

        // Divider details
        var dividerHeight = primaryTimeStringHeight - primaryTimeStringHeightOffset.toNumber();

        // Secondary time details
        var secondaryTimeString = getSecondaryTimeString();
        var secondaryTimeStringWidth = dc.getTextWidthInPixels(secondaryTimeString, secondaryTimeFont);
        var secondaryTimeStringHeight = dc.getFontHeight(secondaryTimeFont);

        // The total printed width (Primary time + Divider + Secondary time)
        var totalPrintedAreaWidth = primaryTimeStringWidth + primaryTimeMarginRight + timeDividerWidth + timeDividerMarginRight + secondaryTimeStringWidth;
        // The starting position in order for the total printed area to be centered in the screen
        var xCoordinateStartingPosition = (widthScreen - totalPrintedAreaWidth)/2;

        // Draw the battery icon at the top
        drawBattery(
            dc,
            widthScreen/2 - (batteryWidth+batteryPinWidth)/2,
            10
        );

        // Draw the primary time
        drawTime(
            dc,
            primaryTimeString,
            xCoordinateStartingPosition,
            heightScreen/2 - primaryTimeStringHeight/2, primaryTimeStringHeight,
            primaryTimeFont
        );

        // Draw the divider
        drawTimeDivider(
            dc,
            xCoordinateStartingPosition + primaryTimeStringWidth + primaryTimeMarginRight,
            dividerHeight
        );

        // Draw the date
        drawDate(
            dc,
            xCoordinateStartingPosition + primaryTimeStringWidth + primaryTimeMarginRight + timeDividerWidth + timeDividerMarginRight + secondaryTimeStringWidth/2,
            heightScreen/2 - dividerHeight/2
        );

        // Draw the secondary time
        drawTime(
            dc,
            secondaryTimeString,
            xCoordinateStartingPosition + primaryTimeStringWidth + primaryTimeMarginRight + timeDividerWidth + timeDividerMarginRight,
            heightScreen/2 + dividerHeight/2 - secondaryTimeStringHeight + secondaryTimeMarginBottom,
            secondaryTimeStringHeight,
            secondaryTimeFont
        );
    }

    /**
    * Converts the hour into 24 hour format.
    */
    function convertTo24HourTimeFormat(hours) {
        if (hours > 12) {
            hours = hours - 12;
        }
        return hours;
    }

    /**
    * Given a location, it returns the UTC time offset
    * (in secs) in that location, as it was today at 00:00.
    */
    function getLocationTimeOffset(secondaryLocation) {
        var epochTimeNow = Time.now();
        var date = Time.Gregorian.info(epochTimeNow, Time.FORMAT_MEDIUM);

        var options = {
            :year   => date.year,
            :month  => date.month,
            :day    => date.day,
            :hour   => 0,
            :min    => 0
        };

        var when = Time.Gregorian.moment(options);

        var secsDiff = 0;
        try {
            // If build with SDK > 4.1.5, localMoment requires a Time.Gregorian.moment as a second argument.
            // However, when the app is running in the watch, localMoment requires a Number (when.value()).
            // For now, the only way to make both the simulator and the watch happy is to build with SDK 4.1.5.
            var local = Time.Gregorian.localMoment(secondaryLocation, when.value());
            // Difference in seconds from 00:00 UTC time (including daylight saving time offset)
            secsDiff = local.getOffset();
        } catch( ex ) {
            ex.printStackTrace();
        }

        return secsDiff;
    }

    /**
    * Calculates the primary time. i.e '21:30'
    */
    function getPrimaryTimeString(clockTime) {
        var hours = clockTime.hour;

        if (!is24Hour) {
            hours = convertTo24HourTimeFormat(hours);
        }

        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        return timeString;
    }

    /**
    * Calculates the secondary time. i.e '21:30'
    */
    function getSecondaryTimeString() {
        var timezoneDiffDuration = new Time.Duration(timezoneDiffSecs.toNumber());

        // Based on today's time offset at this location, calculate the local
        // time, by adding the offset to the current UTC time.
        var epochTimeNow = Time.now();
        var secondaryTimeNow = epochTimeNow.add(timezoneDiffDuration);
        var info = Time.Gregorian.utcInfo(secondaryTimeNow, Time.FORMAT_MEDIUM);
        var hours = info.hour;
        var minutes = info.min;

        if (!is24Hour) {
            hours = convertTo24HourTimeFormat(hours);
        }

        var timeString = secondaryTimezoneCode + " " + Lang.format(timeFormat, [hours.format("%02d"), minutes.format("%02d")]);

        return timeString;
    }

    /**
    * Draws a time string
    */
    function drawTime(dc, timeString, startingX, startingY, height, font) {
        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startingX, startingY, font, timeString, Graphics.TEXT_JUSTIFY_LEFT);
    }

    /**
    * Draws a vertical divider between the primary and secondary time
    */
    function drawTimeDivider(dc, startingX, height) {
        var dividerUpperCornerX = startingX;
        var dividerUpperCornerY = heightScreen/2 - height/2;
        var dividerLowerCornerY = dividerUpperCornerY + height;

        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
        dc.drawRectangle(dividerUpperCornerX, dividerUpperCornerY, timeDividerWidth, height);
    }

    /**
    * Draws the date
    */
    function drawDate(dc, startingX, startingY) {
        var now = Time.now();
        var dateInfo = Time.Gregorian.info(now, Time.FORMAT_LONG);
        var dateStr = Lang.format("$1$ $2$", [dateInfo.day_of_week, dateInfo.day.format("%02d")]);
        var dateStrWidth = dc.getTextWidthInPixels(dateStr, dateFont);
        var dateStrheight = dc.getFontHeight(dateFont);

        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startingX + dateStrWidth/2, startingY + dateStrheight/2, dateFont, dateStr, Graphics.TEXT_JUSTIFY_VCENTER);
    }

    /**
    * Draws the battery icon
    */
    function drawBattery(dc, startingX, startingY) {
        var battery = System.getSystemStats().battery;

        var primaryColor = foregroundColor;
        var lowBatteryColor = Graphics.COLOR_DK_RED;
        var fullBatteryColor = Graphics.COLOR_DK_GREEN;

        var batteryIconPinX = startingX + batteryWidth;
        var batteryIconPinY = startingY + ((batteryIconHeight - batteryIconPinHeight) / 2);

        if(battery < 15.0) {
            primaryColor = lowBatteryColor;
        }

        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(startingX, startingY, batteryWidth, batteryIconHeight);
        dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(batteryIconPinX-1, batteryIconPinY+1, batteryIconPinX-1, batteryIconPinY + batteryIconPinHeight-1);

        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(batteryIconPinX, batteryIconPinY, batteryPinWidth, batteryIconPinHeight);
        dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(batteryIconPinX, batteryIconPinY+1, batteryIconPinX, batteryIconPinY + batteryIconPinHeight-1);

        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(startingX, startingY, (batteryWidth * battery / 100), batteryIconHeight);
        if (battery == 100.0) {
            dc.fillRectangle(batteryIconPinX, batteryIconPinY, batteryPinWidth, batteryIconPinHeight);
        }
    }

    /**
    * Draws some helper lines (Only for debugging)
    */
    function DrawHelperLines(dc) {
        dc.setColor(foregroundColor, Graphics.COLOR_DK_RED);
        dc.drawLine(0, widthScreen/2, widthScreen, widthScreen/2);
        dc.drawLine(widthScreen/2, 0, widthScreen/2, heightScreen);
    }
}
