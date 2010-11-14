width = 512;
height = 384;
//screen = new VideoOutput();
// set screen size
//screen.width = width;
//screen.height = height;

drawer = new DrawPath(width, height);
drawer.widht = width;
drawer.height = height;
drawer.start();

// UNCOMMENT TO ACTIVATE A VIDEO FILTER
/*
filter = new VideoFilter("CIZoomBlur");
drawer.outputPin('frame').connect(filter.inputPin('frame'));
filter.outputPin('frame').connect(screen.inputPin('frame'));
filter.outputPin('frame').export();
*/

// COMMENT THE FOLLOWING TWO LINES IF FILTER HAS BEEN ACTIVATED
//drawer.outputPin('frame').connect(screen.inputPin('frame'));
drawer.outputPin('frame').export();
drawer.outputPin('frameSize').export();

cnt = 0;
x = 0;
y = 0;
radius = 20;

function randFloat() {
    return rand()%1000/1000;
}

mainloop = function() {
    //drawer.clear();
    point = new Point(rand()%width/2, rand()%height/2);
    fgColor = new Color(randFloat(), randFloat(), randFloat(), randFloat());
    bgColor = new Color(randFloat(), randFloat(), randFloat(), randFloat());
    radius = rand()%width/2;
    point1 = new Point(rand()%width, rand()%height);
    point2 = new Point(rand()%width, rand()%height);
    point3 = new Point(rand()%width, rand()%height);
    point4 = new Point(rand()%width, rand()%height);
    point5 = new Point(rand()%width, rand()%height);
    drawer.drawCircle(point, radius, fgColor, bgColor);
    drawer.drawPolygon(new Array(point1, point2, point3, point4), bgColor, fgColor);
    sleep(1/drawer.frequency);
};

run(mainloop);
