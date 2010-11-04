//grabber = new VideoCapture();
screen = new OpenGLScreen();
//screen2 = new OpenGLScreen();
// set screen size
screen.width = 512;
screen.height = 384;
// create a new video layer
movie = new VideoLayer();
movie.open("/Users/xant/test.avi");
// get pins
input = screen.inputPin('frame');
//input2 = screen2.inputPin('frame');
output = movie.outputPin('frame');
input.connect(output); // connect them
//input2.connect(output); // connect them

//echo("Created Entities: " + screen + " " + movie + " " + input + " " + output);

movie.start(); // start the movie

/*
outputPins = b.outputPins;
for (i = 0; i < outputPins.length; i++) {
    echo(outputPins[i]);
}
*/
cnt = 0;
while (1) {
    echo("tick" + cnt++);
    sleep(1);
    if (cnt == 10) {
        movie.stop();
        movie.open("/Users/xant/test.mov");
        movie.start();
    }
    if (cnt == 20)
        break;
}
