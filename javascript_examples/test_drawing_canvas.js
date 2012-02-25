// Example script to test canvas drawing functionalities
// used together with a CIFilter.
// This script also shows how to export pins from the internally-managed
// entities to the board.

width = 640;
height = 480;

drawer = new DrawPath(width, height);
drawer.frquency = 25;

// create a new video filter, connecti it to the drawer and export its output fram to the board
filter = new VideoFilter("CIZoomBlur");
drawer.output.frame.connect(filter.input.frame);
// the following statement will make the output pin available on the board with the name 'filteredFrame'
filter.output.frame.export('filteredFrame'); 

drawer.output.frame.export();
drawer.output.frameSize.export();
drawer.input.saturation.export();
v = new VideoOutput(width, height);
v.input.frame.connect(filter.output.frame);

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

f = function() {
    //drawer.clear();
 
    ctx.fillStyle = 'rgba(0, 0, 0, 0.1)';
    ctx.fillRect(0, 0, width, height);

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
    ctx.beginPath();
    ctx.moveTo(point1.x, point1.y);
    ctx.arc(point.x, point.y, radius, 0, 360, 0);
    ctx.closePath();
    ctx.stroke();
    ctx.fill();
    
    //drawer.rotation = rand()%360;
    //drawer.size = new Size(rand()%width, rand()%height);
    //drawer.origin = new Point(rand()%width, rand()%height);

};

t = setInterval(f, 1000/drawer.frequency); // schedule execution at the current drawer frequency
