screen = new VideoOutput();
// set screen size
screen.width = 512;
screen.height = 384;

drawer = new DrawPath();
drawer.start();

drawer.outputPin('frame').connect(screen.inputPin('frame'));

cnt = 0;
x = 0;
y = 0;
radius = 20;

function randFloat() {
    return rand()%1000/1000;
}

mainloop = function() {
    point = new Point(x, y);
    fgColor = new Color(randFloat(), randFloat(), randFloat());
    bgColor = new Color(randFloat(), randFloat(), randFloat());
    drawer.clear();
    drawer.drawCircle(point, radius, fgColor, bgColor);
    x += 10;
    if (x >= screen.width) {
        if (y >= screen.height) {
            x = 0;
            y = 0;
        } else {
            x = 0;
            y += 10;
        }
    }
    sleep(1/25);
};

run(mainloop);
