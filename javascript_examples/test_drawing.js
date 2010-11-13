screen = new VideoOutput();
// set screen size
screen.width = 512;
screen.height = 384;

drawer = new DrawPath();
drawer.frequency = 30;
drawer.start();

/*
filter = new VideoFilter("CIZoomBlur");
drawer.outputPin('frame').connect(filter.inputPin('frame'));
filter.outputPin('frame').connect(screen.inputPin('frame'));
*/
drawer.outputPin('frame').connect(screen.inputPin('frame'));
drawer.outputPin('frame').export();

cnt = 0;
x = 0;
y = 0;
radius = 20;

function randFloat() {
    return rand()%1000/1000;
}

mainloop = function() {
    point = new Point(rand()%screen.width/2, rand()%screen.height/2);
    fgColor = new Color(randFloat(), randFloat(), randFloat(), 0.2);
    bgColor = new Color(randFloat(), randFloat(), randFloat(), 0.2);
    radius = rand()%screen.width/2;
    //drawer.clear();
    drawer.drawCircle(point, radius, fgColor, bgColor);
    point1 = new Point(rand()%screen.width, rand()%screen.height);
    point2 = new Point(rand()%screen.width, rand()%screen.height);
    point3 = new Point(rand()%screen.width, rand()%screen.height);
    drawer.drawPolygon(new Array(point1, point2, point3), bgColor, fgColor);
    sleep(1/drawer.frequency);
};

run(mainloop);
