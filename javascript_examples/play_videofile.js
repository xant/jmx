screen = new OpenGLScreen();
// set screen size
screen.width = 512;
screen.height = 384;
// create a new video layer
movie = new VideoLayer();
movie.open("/Users/xant/test.avi");
movie.saturation = 10.0;
// get pins
input = screen.inputPin('frame');
output = movie.outputPin('frame');
input.connect(output); // connect them

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
