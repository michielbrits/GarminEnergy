import Toybox.Communications;
import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang; // Nodig voor type definities

class EnergyView extends WatchUi.View {

    var solar = "--";
    var power = "--";
    var error = false;

    function initialize() {
        View.initialize();
    }

    function onShow() {
        fetchData();
    }

    function fetchData() {
        error = false;

        var url = "https://michielserver.com/Garmin/";

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Accept" => "application/json"
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        // De callback moet exact deze 'as' definities hebben
        Communications.makeWebRequest(
            url,
            null,
            options,
            method(:onReceive) // Losse methode is stabieler dan een anonieme functie
        );
    }

    // Door de callback naar een aparte functie te verplaatsen lost de ERROR op
    function onReceive(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode != 200 || data == null || !(data instanceof Dictionary)) {
            error = true;
            WatchUi.requestUpdate();
            return;
        }

        try {
            // Door 'as Dictionary' te gebruiken los je de WARNINGS op regels 54 en 57 op
            var dict = data as Dictionary;

            if (dict.hasKey("solar")) {
                solar = dict["solar"].toString();
            }

            if (dict.hasKey("power")) {
                power = dict["power"].toString();
            }
        }
        catch (ex) {
            error = true;
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var w = dc.getWidth();
        var y = 20;

        if (error) {
            dc.drawText(
                w / 2,
                dc.getHeight() / 2,
                Graphics.FONT_SMALL,
                "No data",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            return;
        }

        dc.drawText(w / 2, y, Graphics.FONT_XTINY, "SOLAR", Graphics.TEXT_JUSTIFY_CENTER);
        y += 25; // Iets meer ruimte voor moderne schermen
        dc.drawText(w / 2, y, Graphics.FONT_LARGE, solar + " W", Graphics.TEXT_JUSTIFY_CENTER);

        y += 50;
        dc.drawText(w / 2, y, Graphics.FONT_XTINY, "POWER", Graphics.TEXT_JUSTIFY_CENTER);
        y += 25;
        dc.drawText(w / 2, y, Graphics.FONT_LARGE, power + " W", Graphics.TEXT_JUSTIFY_CENTER);
    }
}