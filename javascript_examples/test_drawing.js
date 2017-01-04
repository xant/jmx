width = 512;
height = 384;

drawer = new DrawPath(width, height);

// UNCOMMENT TO ACTIVATE A VIDEO FILTER
filter = new VideoFilter("CIZoomBlur");
drawer.outputPin('frame').connect(filter.inputPin('frame'));
filter.outputPin('frame').export('filteredFrame');

// COMMENT THE FOLLOWING TWO LINES IF FILTER HAS BEEN ACTIVATED
drawer.outputPin('frame').export();
drawer.outputPin('frameSize').export();
drawer.inputPin('saturation').export();

cnt = 0;
x = 0;
y = 0;
radius = 20;

echo(dumpDOM());

mainloop = function() {
    //drawer.clear();
    point = new Point(rand()%width/2, rand()%height/2);
    fgColor = new Color(frand(), frand(), frand(), frand());
    bgColor = new Color(frand(), frand(), frand(), frand());
    radius = rand()%width/2;
    point1 = new Point(rand()%width, rand()%height);
    point2 = new Point(rand()%width, rand()%height);
    point3 = new Point(rand()%width, rand()%height);
    point4 = new Point(rand()%width, rand()%height);
    point5 = new Point(rand()%width, rand()%height);
    drawer.drawCircle(point, radius, fgColor, bgColor);
    drawer.drawPolygon(new Array(point1, point2, point3, point4), bgColor, fgColor);
    //drawer.rotation = rand()%360;
    //drawer.size = new Size(rand()%width, rand()%height);
    //drawer.origin = new Point(rand()%width, rand()%height);

    sleep(1/drawer.frequency);
};

addToRunLoop(mainloop, 1/60);
