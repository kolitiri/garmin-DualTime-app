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
            return locationNames.slice(32, 61);

        } else if (id == 4) {
            // D
            return locationNames.slice(61, 65);

        } else if (id == 5) {
            // E
            return locationNames.slice(65, 72);

        } else if (id == 6) {
            // F
            return locationNames.slice(72, 78);

        } else if (id == 7) {
            // G
            return locationNames.slice(78, 93);

        } else if (id == 8) {
            // H
            return locationNames.slice(93, 97);

        } else if (id == 9) {
            // I
            return locationNames.slice(97, 106);

        } else if (id == 10) {
            // J
            return locationNames.slice(106, 110);

        } else if (id == 11) {
            // K
            return locationNames.slice(110, 118);

        } else if (id == 12) {
            // L
            return locationNames.slice(118, 127);

        } else if (id == 13) {
            // M
            return locationNames.slice(127, 148);

        } else if (id == 14) {
            // N
            return locationNames.slice(148, 160);

        } else if (id == 15) {
            // O
            return locationNames.slice(160, 161);

        } else if (id == 16) {
            // P
            return locationNames.slice(161, 173);

        } else if (id == 17) {
            // Q
            return locationNames.slice(173, 174);

        } else if (id == 18) {
            // R
            return locationNames.slice(174, 177);

        } else if (id == 19) {
            // S
            return locationNames.slice(177, 208);

        } else if (id == 20) {
            // T
            return locationNames.slice(208, 219);

        } else if (id == 21) {
            // U
            return locationNames.slice(219, 231);

        } else if (id == 22) {
            // V
            return locationNames.slice(231, 236);

        } else if (id == 23) {
            // W
            return locationNames.slice(236, 237);

        } else if (id == 24) {
            // X
            return [];

        } else if (id == 25) {
            // Y
            return locationNames.slice(237, 238);

        } else if (id == 26) {
            // Z
            return [locationNames[238], locationNames[239]];
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
