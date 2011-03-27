out = new VideoOutput(640,480);
drawer = new DrawPath(640, 480);
drawer.start();
drawer.outputPin('frame').export();
drawer.outputPin('frame').connect(out.inputPin('frame'));
drawer.canvas.drawImage('/Users/xant/broken-LCD.jpg');
p = new Point(0,0);
//drawer.canvas.strokeText("CIAO", p);

echo(dumpDOM());

while (1) {
    k = rand();
    p.x = rand()%drawer.size.width;
    p.y = rand()%drawer.size.height;
    c = new Color(frand(), frand(), frand(), 0.5);
    b = new Color(frand(), frand(), frand(), 0.5);
    drawer.canvas.strokeText("TEST", p, null, c);
    drawer.canvas.strokeStyle = new Color(frand(), frand(), frand());
    drawer.canvas.fillStyle = b;
    drawer.canvas.arc(rand()%drawer.size.width, rand()%drawer.size.height, rand()%drawer.size.height, 0, 360, 0);
    sleep(1/60);
}
