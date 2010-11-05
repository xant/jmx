screen = new OpenGLScreen();
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
output1 = movie.outputPin('frame');
output2 = movie2.outputPin('frame');
//screen2.inputPin('frame').connect(output2);
movie.start(); // start the movie
movie2.start();
outputs = new Array(output1, output2);
cnt = 0;
while (1) {
    echo("tick" + cnt++);
    input.connect(outputs[cnt%2]);
    if (cnt == 1200)
        break;
    sleep(0.05);
}
