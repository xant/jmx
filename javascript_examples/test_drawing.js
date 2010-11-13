screen = new VideoOutput();
// set screen size
screen.width = 512;
screen.height = 384;

drawer = new DrawPath();
drawer.start();

drawer.outputPin('frame').connect(screen.inputPin('frame'));

drawer.drawCircle();

cnt = 0;
mainloop = function() {
    echo("tick" + cnt++);
    sleep(1);
};

run(mainloop);
