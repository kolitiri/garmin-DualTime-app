import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

/**
* Main view that pushes the settings menu.
*/
class DualTimeSettingsView extends WatchUi.View {

    public function initialize() {
        View.initialize();
    }

    public function onLayout(dc as Dc) {
        setLayout($.Rez.Layouts.MainLayout(dc));
    }

    public function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }
}

/**
* Delegate of the DualTimeSettingsView view.
* When the onMenu() behavior is received, it pushes the initial settings menu.
*/
class DualTimeSettingsDelegate extends WatchUi.BehaviorDelegate {
    private var screenShape as ScreenShape;

    public function initialize() {
        screenShape = System.getDeviceSettings().screenShape;
        BehaviorDelegate.initialize();
    }

    /**
    * Behaviour triggered when the start button is pressed.
    */
    public function onSelect() as Boolean {
        // Generate the settings menu
        var menu = new WatchUi.Menu2({:title=>new TimezonesMenuTitle("Settings")});

        // Add menu items
        menu.addItem(new WatchUi.MenuItem("Secondary Timezone", null, "secondaryTimezone", {:alignment => WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT}));

        // Get the current state of the negativeDisplay attribute from the storage
        var negativeDisplay = Storage.getValue("negativeDisplay") ? true : false;

        menu.addItem(new WatchUi.ToggleMenuItem("Negative Display", null, "negativeDisplay", negativeDisplay, {:alignment => WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT}));

        // Only show seconds indicator in round shaped watches
        if (screenShape != System.SCREEN_SHAPE_RECTANGLE) {
            // Get the current state of the displaySeconds attribute from the storage
            var displaySeconds = Storage.getValue("displaySeconds") ? true : false;
            menu.addItem(new WatchUi.ToggleMenuItem("Display Seconds", null, "displaySeconds", displaySeconds, {:alignment => WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT}));
        }

        // Push the settings view
        WatchUi.pushView(menu, new DualTimeSettingsAlphabeticalMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}

/**
* Delegate of the menu that was created dynamically in DualTimeSettingsDelegate.onSelect().
* Controls the behaviour that occurs when one of the settings option is selected.
*/
class DualTimeSettingsAlphabeticalMenuDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;

        if (id.equals("negativeDisplay")) {
            // If the 'negativeDisplay' toggle is flipped, change the value in the storage
            var negativeDisplay = Storage.getValue("negativeDisplay") ? false : true;
            Storage.setValue(id as Number, negativeDisplay);

        } else if (id.equals("displaySeconds")) {
            // If the 'displaySeconds' toggle is flipped, change the value in the storage
            var displaySeconds = Storage.getValue("displaySeconds") ? false : true;
            Storage.setValue(id as Number, displaySeconds);

        } else if (id.equals("secondaryTimezone")) {
            // If the 'secondaryTimezone' option is selected, dynamically generate a
            // submenu that groups the available countries by letter.
            var customMenu = new WatchUi.CustomMenu(35, Graphics.COLOR_WHITE, {
                :focusItemHeight=>75,
                :foreground=>new $.Rez.Drawables.MenuForeground(),
                :title=>new TimezonesMenuTitle("Select"),
                :footer=>new TimezonesMenuFooter()
            });

            customMenu.addItem(new CustomItem(1, "A"));
            customMenu.addItem(new CustomItem(2, "B"));
            customMenu.addItem(new CustomItem(3, "C"));
            customMenu.addItem(new CustomItem(4, "D"));
            customMenu.addItem(new CustomItem(5, "E"));
            customMenu.addItem(new CustomItem(6, "F"));
            customMenu.addItem(new CustomItem(7, "G"));
            customMenu.addItem(new CustomItem(8, "H"));
            customMenu.addItem(new CustomItem(9, "I"));
            customMenu.addItem(new CustomItem(10, "J"));
            customMenu.addItem(new CustomItem(11, "K"));
            customMenu.addItem(new CustomItem(12, "L"));
            customMenu.addItem(new CustomItem(13, "M"));
            customMenu.addItem(new CustomItem(14, "N"));
            customMenu.addItem(new CustomItem(15, "O"));
            customMenu.addItem(new CustomItem(16, "P"));
            customMenu.addItem(new CustomItem(17, "Q"));
            customMenu.addItem(new CustomItem(18, "R"));
            customMenu.addItem(new CustomItem(19, "S"));
            customMenu.addItem(new CustomItem(20, "T"));
            customMenu.addItem(new CustomItem(21, "U"));
            customMenu.addItem(new CustomItem(22, "V"));
            customMenu.addItem(new CustomItem(23, "W"));
            customMenu.addItem(new CustomItem(24, "X"));
            customMenu.addItem(new CustomItem(25, "Y"));
            customMenu.addItem(new CustomItem(26, "Z"));

            WatchUi.pushView(customMenu, new DualTimeSettingsMenuDelegate(), WatchUi.SLIDE_UP);
        }
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
* Delegate of the menu that was created dynamically in DualTimeSettingsAlphabeticalMenuDelegate.onSelect().
* Controls the behaviour that occurs when a letter is selected from timezones submenu.
*/
class DualTimeSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;

        // Dynamically generate a submenu with the available countries
        // that start with the selected letter.
        var customMenu = new WatchUi.CustomMenu(35, Graphics.COLOR_WHITE, {
            :focusItemHeight=>75,
            :foreground=>new $.Rez.Drawables.MenuForeground(),
            :title=>new TimezonesMenuTitle("Timezones"),
            :footer=>new TimezonesMenuFooter()
        });

        try {
            // Load the location names from the JSON file
            var locations = new Locations();
            var locationNames = locations.getLocationNames(id);

            var locId = 0;
            for (var i = 0; i < locationNames.size(); i++) {
                customMenu.addItem(new CustomItem(locId, locationNames[i]));
                locId = locId + 1;
            }
        } catch( ex ) {
            ex.printStackTrace();
        }

        WatchUi.pushView(customMenu, new TimezonesMenuDelegate(), WatchUi.SLIDE_UP);
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
* Delegate of the menu that was created dynamically in DualTimeSettingsMenuDelegate.onSelect().
* Controls the behaviour that occurs when one of the countries has been selected in the submenu.
*/
class TimezonesMenuDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) as Void {
        // If a timezone is selected, change the value in the storage and go back to the previous page
        var secondaryTimezone = item.getLabel();

        // Load the location data from the JSON file
        var locations = new Locations();
        var locationData = locations.getLocationData(secondaryTimezone);

        var secondaryTimezoneCode = locationData["timezoneCode"];
        var secondaryTimezoneLatitude = locationData["latitude"];
        var secondaryTimezoneLongtitude = locationData["longtitude"];

        Storage.setValue("secondaryTimezoneCode", secondaryTimezoneCode);
        Storage.setValue("secondaryTimezoneLatitude", secondaryTimezoneLatitude);
        Storage.setValue("secondaryTimezoneLongtitude", secondaryTimezoneLongtitude);

        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        // Don't allow wrapping
        return false;
    }
}

/**
* Custom drawable for menu titles
*/
class TimezonesMenuTitle extends WatchUi.Drawable {

    private var title as String;

    public function initialize(text as String) {
        title = text;
        Drawable.initialize({});
    }

    public function draw(dc as Dc) as Void {
        var labelWidth = dc.getTextWidthInPixels(title, Graphics.FONT_MEDIUM);
        var labelX = dc.getWidth() / 2 - labelWidth / 2;
        var labelY = dc.getHeight() / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(labelX, labelY, Graphics.FONT_MEDIUM, title, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

/**
* Custom drawable for menu footers
*/
class TimezonesMenuFooter extends WatchUi.Drawable {

    public function initialize() {
        Drawable.initialize({});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawLine(0, 0, dc.getWidth(), 0);
    }
}

/**
* Custom item for the timezones submenu
*/
class CustomItem extends WatchUi.CustomMenuItem {

    private var _label as String;

    public function initialize(id as Number, text as String) {
        CustomMenuItem.initialize(id, {});
        _label = text;
    }

    public function draw(dc as Dc) as Void {
        var font = Graphics.FONT_TINY;
        if (isFocused()) {
            font = Graphics.FONT_LARGE;
        }

        if (isSelected()) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.clear();
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, font, _label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawLine(0, 0, dc.getWidth(), 0);
        if (isFocused()) {
            dc.drawLine(0, 1, dc.getWidth(), 1);
            dc.drawLine(0, 2, dc.getWidth(), 2);
            dc.drawLine(0, 3, dc.getWidth(), 3);
        }
        dc.drawLine(0, dc.getHeight() - 1, dc.getWidth(), dc.getHeight() - 1);
        if (isFocused()) {
            dc.drawLine(0, dc.getHeight() - 2, dc.getWidth(), dc.getHeight() - 2);
            dc.drawLine(0, dc.getHeight() - 3, dc.getWidth(), dc.getHeight() - 3);
            dc.drawLine(0, dc.getHeight() - 4, dc.getWidth(), dc.getHeight() - 4);
        }
    }

    public function getLabel() as String {
        return _label;
    }
}
