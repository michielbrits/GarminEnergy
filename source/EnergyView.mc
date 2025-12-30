import Toybox.Communications;
import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;

class EnergyView extends WatchUi.View {

  var solar as Number = 0;
  var consumption as Number = 0;
  var total as Number = 0;
  var error = false;

  var refreshTimer = null;

  function initialize() {
    View.initialize();
  }

  function onShow() as Void {
    fetchData();

    refreshTimer = new Timer.Timer();
    refreshTimer.start(method(:fetchData), 5000, true);
  }

  function onHide() as Void {
    if (refreshTimer != null) {
      refreshTimer.stop();
      refreshTimer = null;
    }
  }

  function fetchData() as Void {
    error = false;

    var url = "https://michielserver.com/Garmin/";

    var options = {
      :method => Communications.HTTP_REQUEST_METHOD_GET,
      :headers => { "Accept" => "application/json" },
      :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
    };

    Communications.makeWebRequest(url, null, options, method(:onReceive));
  }

  function onReceive(responseCode as Number,
                     data as Dictionary or String or Null) as Void {

    if (responseCode != 200 || data == null || !(data instanceof Dictionary)) {
      error = true;
      WatchUi.requestUpdate();
      return;
    }

    try {
      var dict = data as Dictionary;

      // Parse values (expecting JSON keys: solar, consumption)
      if (dict.hasKey("solar")) {
        solar = dict["solar"].toNumber();
      }

      if (dict.hasKey("consumption")) {
        consumption = dict["consumption"].toNumber();
      }

      // Calculate total on-watch: consumption - solar
      total = consumption - solar;

    } catch (ex) {
      error = true;
    }

    WatchUi.requestUpdate();
  }

  function onUpdate(dc) {
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    var w = dc.getWidth();

    // ---- Layout tuning (easy to tweak) ----
    var startY = 20;
    var labelGap = 30;
    var sectionGap = 65;

    var y = startY;

    if (error) {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        w / 2,
        dc.getHeight() / 2,
        Graphics.FONT_SMALL,
        "No data",
        Graphics.TEXT_JUSTIFY_CENTER
      );
      return;
    }

    // ---- SOLAR (GREEN) ----
    dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
    dc.drawText(w / 2, y, Graphics.FONT_XTINY, "SOLAR", Graphics.TEXT_JUSTIFY_CENTER);
    y += labelGap;
    dc.drawText(w / 2, y, Graphics.FONT_LARGE, solar.toString() + " W", Graphics.TEXT_JUSTIFY_CENTER);

    // ---- CONSUMPTION (RED) ----
    y += sectionGap;
    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    dc.drawText(w / 2, y, Graphics.FONT_XTINY, "CONSUMPTION", Graphics.TEXT_JUSTIFY_CENTER);
    y += labelGap;
    dc.drawText(w / 2, y, Graphics.FONT_LARGE, consumption.toString() + " W", Graphics.TEXT_JUSTIFY_CENTER);

    // ---- TOTAL (WHITE) ----
    y += sectionGap;
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(w / 2, y, Graphics.FONT_XTINY, "TOTAL", Graphics.TEXT_JUSTIFY_CENTER);
    y += labelGap;
    dc.drawText(w / 2, y, Graphics.FONT_LARGE, total.toString() + " W", Graphics.TEXT_JUSTIFY_CENTER);
  }
}
