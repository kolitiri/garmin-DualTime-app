import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

/**
* Watch face application that displays two different times.
* 
* The primary is the local time at the current location of
* the device, while the secondary can be configured by the
* user from the settings menu in the watch.
* 
* @author Christos Liontos
*/
class DualTime extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Return the initial view of the application
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new DualTimeView() ] as Array<Views or InputDelegates>;
    }

    // Return the settings view of the application
    public function getSettingsView() as Array<Views or InputDelegates>? {
        return [ new $.DualTimeSettingsView(), new $.DualTimeSettingsDelegate() ] as Array<Views or InputDelegates>;
    }
 
    // New application settings have been received. Update the UI
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}

function getApp() as DualTime {
    return Application.getApp() as DualTime;
}
