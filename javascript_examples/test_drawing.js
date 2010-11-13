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
mainloop = function() {
    point = new Point(x, y);
    echo("tick" + cnt++);
    echo (point);
    echo("point " + point.x);
    drawer.drawCircle(point);
    x += 10;
    y += 10;
    sleep(1);
};

run(mainloop);
