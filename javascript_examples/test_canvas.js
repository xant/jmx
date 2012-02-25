// small example script to test the canvas 2d drawing interface
out = new VideoOutput(640,480);
drawer = new DrawPath(640, 480);
drawer.outputPin('frame').export();
drawer.outputPin('frame').connect(out.inputPin('frame'));
drawer.canvas.getContext("2d").drawImage('/Users/xant/broken-LCD.jpg');
p = new Point(0,0);
//drawer.canvas.strokeText("CIAO", p);

echo(dumpDOM());

while (1) {
    k = rand();
    p.x = rand()%drawer.size.width;
    p.y = rand()%drawer.size.height;
    c = new Color(frand(), frand(), frand(), 0.5);
    b = new Color(frand(), frand(), frand(), 0.5);
    drawer.canvas.getContext("2d").strokeStyle = new Color(frand(), frand(), frand());
    drawer.canvas.getContext("2d").fillStyle = b;
    drawer.canvas.getContext("2d").strokeText("TEST", p.x, p.y);
    drawer.canvas.getContext("2d").arc(rand()%drawer.size.width, rand()%drawer.size.height, 10, 0, 360, 0);
    drawer.canvas.getContext("2d").stroke();
    drawer.canvas.getContext("2d").fill();
    sleep(1/60);
}
