# DualTime Garmin watch face

This is a Garmin watch face, written in [Monkey-C](https://developer.garmin.com/connect-iq/monkey-c/) that displays the time in two different timezones.

The primary time is the local time at the current location of the device, while the secondary can be configured in the settings.

Features:
1. Dual time display (regional and world time)
2. Reliable world time for over 200 countries, by leveraging Garmin's internal LocalMoment library
3. In device settings that do not require the use of the Garmin Connect application
4. Positive and negative display mode
5. Optional setting to display seconds (only for round watches)
6. Simplistic design inspired by Garmin Fenix6's battery saver mode

### Installation

Install the app from the GarminIQ Connect store [here](https://apps.garmin.com/en-US/apps/a5ce0cb3-4a0e-4855-922e-69ed36fcf560)

### Supported devices

Check the manifest.xml for a list of the supported devices.

Please note, this has only been tested on a real Fenix6 Pro device. The rest of the devices have only been tested through the simulator.

### Useful links
* [API Documentation](https://developer.garmin.com/connect-iq/api-docs/index.html)
* [Core topics](https://developer.garmin.com/connect-iq/core-topics/layouts/)
* [App submission](https://developer.garmin.com/connect-iq/submit-an-app/)
* [Device compatibility](https://developer.garmin.com/connect-iq/compatible-devices/)

### Notes

* Uses Time.localMoment [since API Level 3.3.0]
* Type checking is currently deactivated in monkey.jungle


### Authors

Christos Liontos