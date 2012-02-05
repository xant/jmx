// open 2 screens
screen = new VideoOutput(512, 384);
//screen2 = new VideoOutput(512, 384);
// open 2 movie files 
movie = new Movie("/Users/xant/test.avi");
movie2 = new Movie("/Users/xant/test.mov");
// get pins
input = screen.inputPin('frame');
input.sendNotifications = false;
output1 = movie.outputPin('frame');
output1.sendNotifications = false;
output2 = movie2.outputPin('frame');
output2.sendNotifications = false;

// create a videomixer
/*
videomixer = new VideoMixer();
videomixer.inputPin('video').connect(output1);
videomixer.inputPin('video').connect(output2);
*/
// and connect the mixer to the second screen
//screen2.inputPin('frame').connect(videomixer.outputPin('video'));

// start the movies

outputs = new Array(output1, output2);
cnt = 0;
// switch input of the first screen every 2 frames (assuming 25 frames per second)
mainloop = function(pin, list) {
    cnt++;
    pin.connect(list[cnt%2]);
    if (cnt == 100)
        quit();
    sleep((1.0/25 * 2));
}

run(mainloop, input, outputs);
