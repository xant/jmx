screen = new VideoOutput();
// set screen size
screen.width = 512;
screen.height = 384;
// open a new movie file
movie = new MovieFile("/Users/xant/test.avi");
movie.saturation = 10.0;

// create a color-invert filter
colorInvert = new VideoFilter("CIColorInvert");
colorInvertInput = colorInvert.inputPin('frame');
colorInvertOutput = colorInvert.outputPin('frame');

// create a comic-effect filter
comicEffect = new VideoFilter("CIComicEffect");
comicEffectInput = comicEffect.inputPin('frame');
comicEffectOutput = comicEffect.outputPin('frame');

// where to send the output frames
output = screen.inputPin('frame');
// the pin from which we receive frames
input = movie.outputPin('frame');

colorInvertInput.connect(input);
comicEffectInput.connect(colorInvertOutput);
output.connect(comicEffectOutput); // connect them

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
