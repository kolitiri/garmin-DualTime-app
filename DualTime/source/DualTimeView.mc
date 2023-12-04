import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

/**
* Main view of the application.
*/
class DualTimeView extends WatchUi.WatchFace {
    private var partialUpdatesAllowed as Boolean;
    private var fullScreenRefresh as Boolean;
    private var isAwake as Boolean;
    private var screenShape as ScreenShape;

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
    var displaySeconds;

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
        screenShape = System.getDeviceSettings().screenShape;
        partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        fullScreenRefresh = true;
        isAwake = true;
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

        // Get displaySeconds setting from storage (watch menu), only for round shaped watches
        if (screenShape != System.SCREEN_SHAPE_RECTANGLE) {
            displaySeconds = Storage.getValue("displaySeconds") ? true : false;
        } else {
            displaySeconds = false;
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

    function onPartialUpdate(dc as Dc) as Void {
        // Called every 1s while on Low Power Mode
        drawSeconds(dc);
    }

    function onUpdate(dc as Dc) as Void {
        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullScreenRefresh = true;

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

        if (partialUpdatesAllowed) {
            // If this device supports partial updates and they are currently
            // allowed run the onPartialUpdate method to draw the seconds indicator.
            onPartialUpdate(dc);
        } else if (isAwake) {
            // Otherwise, if we are out of sleep mode, draw the seconds indicator
            // directly in the full update method.
            drawSeconds(dc);
        }

        fullScreenRefresh = false;
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
            // UPDATE: Seems like this has been fixed in SDK 6.4.1. Changing when.value() -> when
            var local = Time.Gregorian.localMoment(secondaryLocation, when);
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
    * Draws the seconds indicator
    *
    * NOTE! As a side effect, this function can also draw the battery icon.
    * This is due to the fact that depending on the position of the seconds
    * indicator, we might also erase the battery, when we partially update
    * the screen using the clip method.
    */
    function drawSeconds(dc) {

        if (displaySeconds == false) {
            return;
        }

        if (!isAwake) {
            return;
        }

        var clockTime = System.getClockTime();
        var seconds = clockTime.sec.format("%02d").toNumber();
        var arcStart;
        var x1;
        var y1;

        if (!fullScreenRefresh) {
            // If this is a partial screen refresh, we need to clear the previous clipped
            // area (drawn one second earlier) before we start drawing to the new one.
            var prevSeconds = seconds - 1;
            arcStart = 90 - (prevSeconds * 6);
            x1 = widthScreen/2 + widthScreen/2 * Math.sin(Math.toRadians(arcStart + 90));
            y1 = widthScreen/2 + widthScreen/2 * Math.cos(Math.toRadians(arcStart + 90));
            dc.setClip(x1 - 10, y1 - 10, 20, 20);
            dc.setColor(Graphics.COLOR_TRANSPARENT, backgroundColor as Number);
            dc.clear();

            if (prevSeconds < 4 || prevSeconds > 56) {
                // If we are going to clear the area very close to the battery
                // (12:00 +/- 4 seconds) we need to re-draw the battery icon
                drawBattery(
                    dc,
                    widthScreen/2 - (batteryWidth+batteryPinWidth)/2,
                    10
                );
            }
        }

        arcStart = 90 - (seconds * 6);
        x1 = widthScreen/2 + widthScreen/2 * Math.sin(Math.toRadians(arcStart + 90));
        y1 = widthScreen/2 + widthScreen/2 * Math.cos(Math.toRadians(arcStart + 90));

        if (!fullScreenRefresh) {
            dc.setClip(x1 - 10, y1 - 10, 20, 20);
        }

        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);

        // Draw a rectangle enclosing the area that will be partially updated (for debugging)
        //dc.drawRectangle(x1 - 10, y1 - 10, 20, 20);

        // Draw a number of tiny arches to create the illusion of a seconds indicator
        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2, Graphics.ARC_COUNTER_CLOCKWISE, arcStart - 3, arcStart - 1);
        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2, Graphics.ARC_COUNTER_CLOCKWISE, arcStart + 1, arcStart + 3);

        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 1, Graphics.ARC_COUNTER_CLOCKWISE, arcStart - 3, arcStart - 1);
        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 1, Graphics.ARC_COUNTER_CLOCKWISE, arcStart + 1, arcStart + 3);

        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 2, Graphics.ARC_COUNTER_CLOCKWISE, arcStart - 3, arcStart - 1);
        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 2, Graphics.ARC_COUNTER_CLOCKWISE, arcStart + 1, arcStart + 3);

        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 3, Graphics.ARC_COUNTER_CLOCKWISE, arcStart - 3, arcStart - 1);
        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 3, Graphics.ARC_COUNTER_CLOCKWISE, arcStart + 1, arcStart + 3);

        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 4, Graphics.ARC_COUNTER_CLOCKWISE, arcStart - 3, arcStart - 1);
        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 4, Graphics.ARC_COUNTER_CLOCKWISE, arcStart + 1, arcStart + 3);

        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 5, Graphics.ARC_COUNTER_CLOCKWISE, arcStart - 3, arcStart - 1);
        dc.drawArc(widthScreen/2, widthScreen/2, widthScreen/2 - 5, Graphics.ARC_COUNTER_CLOCKWISE, arcStart + 1, arcStart + 3);

        if (!fullScreenRefresh) {
            dc.clearClip();
        }
    }

    /**
    * Draws a vertical divider between the primary and secondary time
    */
    function drawTimeDivider(dc, startingX, height) {
        var dividerUpperCornerX = startingX;
        var dividerUpperCornerY = heightScreen/2 - height/2;

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

    /**
    * Called when the device re-enters sleep mode
    */
    public function onEnterSleep() as Void {
        // Set the isAwake flag to let onUpdate know it should stop rendering the second hand
        isAwake = false;
        WatchUi.requestUpdate();
    }

    /**
    * Called when the device exits sleep mode
    */
    public function onExitSleep() as Void {
        // Set the isAwake flag to let onUpdate know it should render the second hand
        isAwake = true;
    }

    /**
    *  Turns off partial updates
    */
    public function turnPartialUpdatesOff() as Void {
        partialUpdatesAllowed = false;
    }
}


/**
* View delegate that receives watch face events
*/
class DualTimeDelegate extends WatchUi.WatchFaceDelegate {
    private var _view as DualTimeView;

    public function initialize(view as DualTimeView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    /**
    * The onPowerBudgetExceeded callback is called by the system if the onPartialUpdate
    * method exceeds the allowed power budget. If this occurs, the system will stop
    * invoking onPartialUpdate each second, so we notify the view here to let the
    * rendering methods know they should not be rendering a second hand.
    *
    * @param powerInfo Information about the power budget
    */
    public function onPowerBudgetExceeded(powerInfo as WatchFacePowerInfo) as Void {
        // System.println("Average execution time: " + powerInfo.executionTimeAverage);
        // System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
        _view.turnPartialUpdatesOff();
    }
}