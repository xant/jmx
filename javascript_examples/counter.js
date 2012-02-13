output = new OutputPin("count", "Number");

frequencyPin = scriptEntity.inputPin('frequency');

count = 0;

f = function() {
    output.data = count++;
    setTimeout(f, 1000/frequencyPin.data);
}

reset = new InputPin("reset", "Void", function() { count = 0; });

f();
