width = 640;
height = 480;

drawer = new DrawPath(width, height);
drawer.start();

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

/*
elements = drawer.getElementsByTagName('canvas');
canvas = elements[0];
*/
canvas = $('canvas:first').get(0);

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
    canvas.strokeStyle = fgColor;
    canvas.fillStyle = bgColor;
    canvas.arc(point.x, point.y, radius, 0, 360, 0);
    canvas.beginPath();
    canvas.moveTo(point1.x, point1.y);
    canvas.lineTo(point2.x, point2.y);
    canvas.lineTo(point3.x, point3.y);
    canvas.lineTo(point4.x, point4.y);
    canvas.closePath();
    canvas.stroke();
    canvas.fill();
    
    //drawer.rotation = rand()%360;
    //drawer.size = new Size(rand()%width, rand()%height);
    //drawer.origin = new Point(rand()%width, rand()%height);

    sleep(1/drawer.frequency);
};

run(mainloop);
