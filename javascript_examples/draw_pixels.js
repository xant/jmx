// example script to test drawing of single pixels
width = 640;
height = 480;

drawer = new DrawPath();

// Uncommend the following block if you want a debug video-output
screen = new VideoOutput(width, height);
// set screen size
drawer.outputPin('frame').connect(screen.inputPin('frame'));

// UNCOMMENT TO ACTIVATE A VIDEO FILTER
/*
filter = new VideoFilter("CIZoomBlur");
drawer.outputPin('frame').connect(filter.inputPin('frame'));
filter.outputPin('frame').connect(screen.inputPin('frame'));
filter.outputPin('frame').export();
*/

// COMMENT THE FOLLOWING TWO LINES IF FILTER HAS BEEN ACTIVATED
drawer.outputPin('frame').export();
drawer.outputPin('frameSize').export();
drawer.inputPin('saturation').export();

cnt = 0;
x = 0;
y = 0;
radius = 20;

function randFloat() {
    return rand()%1000/1000;
}

mainloop = function() {
    //drawer.clear();
    for (i = 0; i < 1000; i++) {
        color = new Color(randFloat(), randFloat(), randFloat(), randFloat());
        point = new Point(rand()%width, rand()%height);
        drawer.drawPixel(point, color);
    }
    sleep(1/60);
};

run(mainloop);
