screen = new VideoOutput();
// set screen size
screen.width = 512;
screen.height = 384;
// create a new video layer
movie = new VideoLayer();
movie.open("/Users/xant/test.avi"); // and load a movie file
movie.saturation = 10.0;

// create a color-invert filter
colorInvert = new VideoFilter();
colorInvert.filter = "CIColorInvert";
colorInvertInput = colorInvert.inputPin('frame');
colorInvertOutput = colorInvert.outputPin('frame');

// create a comic-effect filter
comicEffect = new VideoFilter();
comicEffect.filter = "CIComicEffect";
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
