//grabber = new VideoCapture();
screen = new OpenGLScreen();
//screen2 = new OpenGLScreen();
// set screen size
screen.width = 512;
screen.height = 384;
// create a new video layer
movie = new VideoLayer();
movie.open("/Users/xant/test.avi");
movie.saturation = 10.0;
// get pins
input = screen.inputPin('frame');
//input2 = screen2.inputPin('frame');
output = movie.outputPin('frame');
input.connect(output); // connect them
//input2.connect(output); // connect them

//echo("Created Entities: " + screen + " " + movie + " " + input + " " + output);

movie.start(); // start the movie

cnt = 0;

mainloop = function() {
    echo("tick" + cnt++);
    sleep(1);
    if (cnt == 10) {
        movie.open("/Users/xant/test.mov");
    }
    if (cnt == 20)
        quit();
};

run(mainloop);
