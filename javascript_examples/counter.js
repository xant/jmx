output = new OutputPin("count", "Number");

scriptEntity.frequency = 1; // default to 1 tick per second (fractions are allowed)

count = 0;

f = function() {
    output.data = count++;
    setTimeout(f, 1000/scriptEntity.frequency);
}

reset = new InputPin("reset", "Void", function() { count = 0; });

f();
