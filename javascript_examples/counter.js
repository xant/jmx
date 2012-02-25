//
// example script which implements a simple counter entity
// changing the frequency of the scriptEntity will control the count rate
//
output = new OutputPin("count", "Number"); // create an output pin

scriptEntity.frequency = 1; // default to 1 tick per second (fractions are allowed)

count = 0;

// timeout function to increment the counter
f = function() {
    output.data = count++;
    // reschedule the timer according to the frequency of the scriptEntity
    setTimeout(f, 1000/scriptEntity.frequency);
}

// create an input pin to allow resetting the counter
reset = new InputPin("reset", "Void", function() { count = 0; });

f();
