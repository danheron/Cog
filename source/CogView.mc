import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class CogView extends WatchUi.SimpleDataField {
    private var _chainrings as Array<Number> = [34,50];
    private var _cogs as Array<Number> = [11,12,13,14,15,16,17,19,22,25,28];
    private var _wheelCircumference as Float = 2.096;
    private var _lastValue = "--";
    private var _configError = false;

    function initialize() {
        SimpleDataField.initialize();
        label = "COG";

        if (!readSettings()) {
            _configError = true;
        }
    }

    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        if (_configError) {
            return "CONFIG!";
        }

        var speed = info.currentSpeed;
        var cadence = info.currentCadence;

        if (speed == null || cadence == null || speed == 0 || cadence == 0) {
            return _lastValue;
        }

        // Uncomment this line when running in the simulator
        //cadence = cadence / 2;

        var cog1 = getClosestCog(speed, cadence, _chainrings[0], _wheelCircumference);
        var cog2 = getClosestCog(speed, cadence, _chainrings[1], _wheelCircumference);

        _lastValue = cog1 + (cog2 / 100.0);
        return _lastValue;
    }

    function getClosestCog(speed as Float, cadence as Number, chainring as Number, wheelCircumference as Float) as Number {
        // Calculate expected cog
        var expectedCog = (chainring * wheelCircumference * cadence) / (speed * 60);
        //System.println("S=" + speed + ", C=" + cadence + ", CR=" + chainring + ", WC=" + wheelCircumference + ", Cog=" + expectedCog);

        // Find the closest actual cog that we have
        var diff = 100;
        var actualCog = _cogs[0];
        for (var i = 0; i < _cogs.size(); i++) {
            var cog = _cogs[i];
            if ((cog - expectedCog).abs() < diff) {
                diff = (cog - expectedCog).abs();
                actualCog = cog;
            }
        }

        return actualCog;
    }

    function readSettings() as Boolean {
        // Read chain rings
        var chainrings = readArrayProperty("ChainRings");
        if (chainrings == null) {
            return false;
        }
        _chainrings = chainrings;

        // Read cogs
        var cogs = readArrayProperty("Cogs");
        if (cogs == null) {
            return false;
        }
        _cogs = cogs;

        // Read wheel circumference
        var wheelCircumference = Application.Properties.getValue("WheelCircumference");
        if (wheelCircumference == null) {
            return false;
        }
        _wheelCircumference = wheelCircumference;

        return true;
    }

    function readArrayProperty(key as String) as Array<Number> or Null {
        // Read property
        var propertyValue = Application.Properties.getValue(key);
        if (propertyValue == null) {
            return null;
        }
        var valueString = propertyValue.toString();

        // Parse each value as number into array
        var result = [] as Array<Number>;
        var moreValues = true;
        while (moreValues) {
            var delimiterIndex = valueString.find(";");
            var value = valueString.substring(0, delimiterIndex).toNumber();
            if (value == null) {
                return null;
            }
            result.add(value);
            if (delimiterIndex == null) {
                moreValues = false;
            } else {
                valueString = valueString.substring(delimiterIndex + 1, null);
                delimiterIndex = valueString.find(";");
            }
        }

        // Result should have at least one value
        if (result.size == 0) {
            return null;
        }

        return result;
    }
}