hid = new HIDInput("077d:0410");
movie = new MovieFile('/Users/xant/test.mov');
video = new VideoOutput(640, 480);
movie.output.frame.connect(video.input.frame);

// build an array containing all input pins accepting a number
inputPins = new Array();
for (i in movie.input) { if (movie.inputPin(i).type == "Number") inputPins.push(i); }

currentIndex = 0;
currentPin = movie.inputPin(inputPins[currentIndex]);
echo("Current pin: " + currentPin.label);

hid.output.report.connect(function(v) { 
    buttonPressed = v.byteAtIndex(0);
    if (buttonPressed) {
        currentIndex = (currentIndex + 1) % inputPins.length;
        currentPin = movie.inputPin(inputPins[currentIndex]);
        echo("Current pin: " + currentPin.label);
    }
    direction = v.byteAtIndex(1);
    if (direction > 127) {
        currentPin.data -= (256 - direction) / 10;
    } else {
        currentPin.data += direction / 10;
    }
    echo(direction + "  " + currentPin.data);
});
