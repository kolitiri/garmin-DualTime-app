/**
* Loads location related data from the JSON files
* Due to memory limitations in the watch devices, we need to batch the settings
* and never load too many resources (i.e from the JSON files)
*/
class Locations {

    public function initialize() {
    }

    public function getLocationNames(id) {
        // Returns a subset of the country names, depending on the letter selection.
        // Uses location-names.json, which stores all the countries in alphabetical order.
        // NOTE! Do not return a large list because it crashes the settings menu
        var locationNames = WatchUi.loadResource(Rez.JsonData.locationNames);

        if (id == 1) {
            // A
            return locationNames.slice(0, 14);

        } else if (id == 2) {
            // B
            return locationNames.slice(14, 32);

        } else if (id == 3) {
            // C
            return locationNames.slice(32, 53);

        } else if (id == 4) {
            // D
            return locationNames.slice(53, 57);

        } else if (id == 5) {
            // E
            return locationNames.slice(57, 64);

        } else if (id == 6) {
            // F
            return locationNames.slice(64, 71);

        } else if (id == 7) {
            // G
            return locationNames.slice(71, 85);

        } else if (id == 8) {
            // H
            return locationNames.slice(85, 89);

        } else if (id == 9) {
            // I
            return locationNames.slice(89, 98);

        } else if (id == 10) {
            // J
            return locationNames.slice(98, 102);

        } else if (id == 11) {
            // K
            return locationNames.slice(102, 108);

        } else if (id == 12) {
            // L
            return locationNames.slice(108, 117);

        } else if (id == 13) {
            // M
            return locationNames.slice(117, 137);

        } else if (id == 14) {
            // N
            return locationNames.slice(137, 150);

        } else if (id == 15) {
            // O
            return locationNames.slice(150, 151);

        } else if (id == 16) {
            // P
            return locationNames.slice(151, 163);

        } else if (id == 17) {
            // Q
            return locationNames.slice(163, 164);

        } else if (id == 18) {
            // R
            return locationNames.slice(164, 168);

        } else if (id == 19) {
            // S
            return locationNames.slice(168, 200);

        } else if (id == 20) {
            // T
            return locationNames.slice(200, 212);

        } else if (id == 21) {
            // U
            return locationNames.slice(212, 225);

        } else if (id == 22) {
            // V
            return locationNames.slice(225, 229);

        } else if (id == 23) {
            // W
            return locationNames.slice(229, 230);

        } else if (id == 24) {
            // X
            return [];

        } else if (id == 25) {
            // Y
            return locationNames.slice(230, 231);

        } else if (id == 26) {
            // Z
            return [locationNames[231], locationNames[232]];
        }
        
        return [];
    }

    public function getLocationData(locationKey) {
        // Returns location related information from the JSON files
        // NOTE! Handle the resources with care. Loading too many can crash the settings menu
        var locationData1 = WatchUi.loadResource(Rez.JsonData.locationData1);

        if (locationData1.hasKey(locationKey)) {
            return locationData1[locationKey];
        }

        var locationData2 = WatchUi.loadResource(Rez.JsonData.locationData2);
        
        if (locationData2.hasKey(locationKey)) {
            return locationData2[locationKey];
        }

        var locationData3 = WatchUi.loadResource(Rez.JsonData.locationData3);
        
        if (locationData3.hasKey(locationKey)) {
            return locationData3[locationKey];
        }

        return {};
    }
}
