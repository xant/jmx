screen = new VideoOutput();
//screen2 = new OpenGLScreen();
screen.width = 512;
screen.height = 384;
// create a new video layer
movie = new VideoLayer();
movie2 = new VideoLayer();
movie.open("/Users/xant/test.avi");
movie2.open("/Users/xant/test.mov");
// get pins
input = screen.inputPin('frame');
input.sendNotifications = false;
output1 = movie.outputPin('frame');
output1.sendNotifications = false;
output2 = movie2.outputPin('frame');
output2.sendNotifications = false;
//screen2.inputPin('frame').connect(output2);
movie.start(); // start the movie
movie2.start();
outputs = new Array(output1, output2);
cnt = 0;

mainloop = function(pin, list) {
    //echo("tick" + cnt++);
    cnt++;
    pin.connect(list[cnt%2]);
    if (cnt == 1200)
        quit();
    // switch input every 2 frames (assuming 25 frames per second)
    sleep((1.0/25 * 2));
}

run(mainloop, input, outputs);
