phidget = new PhidgetEncoder();
movie = new MovieFile('/Users/xant/Panorama-tst_5500x768_PhotoJpeg70-60sec.mov');
movie.tileFrame = true;
screen = new VideoOutput(1280,768);
//phidget.outputPin('encoder0_position').connect(movie.inputPin('originX'));
filter = new VideoFilter("CIZoomBlur");
movie.output.frame.connect(filter.input.frame);
filter.output.frame.connect(screen.input.frame);
phidget.output.encoder0.connect(function(v) {
        filter.input.inputAmount.data = Math.abs(v.delta) + 1;
        origin = movie.origin;
        origin.x = v.position;
        movie.origin = origin;
});

center = new Point(100,100);
document.addEventListener("mousemove", function(e) { 
    filter.input.inputCenter.data = new Point(e.screenX, e.screenY);
}, false);


