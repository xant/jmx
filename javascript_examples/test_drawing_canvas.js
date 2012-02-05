width = 640;
height = 480;

drawer = new DrawPath(width, height);

// UNCOMMENT TO ACTIVATE A VIDEO FILTER
filter = new VideoFilter("CIZoomBlur");
drawer.outputPin('frame').connect(filter.inputPin('frame'));
filter.outputPin('frame').export('filteredFrame');

// COMMENT THE FOLLOWING TWO LINES IF FILTER HAS BEEN ACTIVATED
drawer.outputPin('frame').export();
drawer.outputPin('frameSize').export();
drawer.inputPin('saturation').export();
v = new VideoOutput(width, height);
v.inputPin('frame').connect(filter.outputPin('frame'));

cnt = 0;
x = 0;
y = 0;
radius = 20;

echo(dumpDOM());

/*
elements = drawer.getElementsByTagName('canvas')[0];
canvas = elements[0];
*/
//canvas = drawer.getElementsByTagName('canvas')[0];
canvas = $('canvas:first', drawer).get(0);
ctx = canvas.getContext("2d");

entities = $('Entities').get(0);

mainloop = function() {
    //drawer.clear();
    point = new Point(rand()%width, rand()%height);
    fgColor = new Color(frand(), frand(), frand(), frand());
    bgColor = new Color(frand(), frand(), frand(), frand());
    ctx.strokeStyle = fgColor;
    ctx.fillStyle = bgColor;
    radius = rand()%width/2;
    point1 = new Point(rand()%width, rand()%height);
    point2 = new Point(rand()%width, rand()%height);
    point3 = new Point(rand()%width, rand()%height);
    point4 = new Point(rand()%width, rand()%height);
    point5 = new Point(rand()%width, rand()%height);
    ctx.beginPath();
    ctx.moveTo(point1.x, point1.y);
    ctx.lineTo(point2.x, point2.y);
    ctx.lineTo(point3.x, point3.y);
    ctx.lineTo(point4.x, point4.y);
    ctx.closePath();
    ctx.stroke();
    ctx.fill();

    fgColor = new Color(frand(), frand(), frand(), frand());
    bgColor = new Color(frand(), frand(), frand(), frand());
    ctx.strokeStyle = fgColor;
    ctx.fillStyle = bgColor;
    //ctx.beginPath();
    //ctx.moveTo(point1.x, point1.y);
    ctx.arc(point.x, point.y, radius, 0, 360, 0);
    //canvas.closePath();
    ctx.stroke();
    ctx.fill();
    
    //drawer.rotation = rand()%360;
    //drawer.size = new Size(rand()%width, rand()%height);
    //drawer.origin = new Point(rand()%width, rand()%height);

    sleep(1/drawer.frequency);
};

run(mainloop);
