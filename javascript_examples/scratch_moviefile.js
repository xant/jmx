// default video output size 
width = 640;
height = 480;

// open a movie file (change the path to open a different file)
// Note that only video files supported by quicktime can be opened
// (so if you are in doubt, first try opening it with the quicktime player shipped with the system)
m = new MovieFile('/Applications/Adobe Photoshop CS5.1/Samples/CheeziPuffs.mov');
// scale the movie to fit the screen size
m.scaleRatio = (m.size.width > m.size.height)
               ? width / m.size.width
               : height / m.size.height;


// we want to see video frames coming from the movie
v = new VideoOutput(width, height);
v.input.frame.connect(m.output.frame);

// and we want to hear the audio as well
a = new AudioOutput();
a.input.audio.connect(m.output.audio);

// distribute the timeline proporzionally over the output width
step = v.size.width / m.duration;
// initialize the last X coordinate
// (this shouldn't be necessary ... but we want this symbol to be global)
lastX = 0;
moveThreshold = 10; // and set the threshold used to detect movement on the x axis

document.addEventListener("mousemove", function(e) {
    // don't seek the movie if the mouse moved less 
    // than 'moveThreshold' pixels on the horizontal axis
    if (Math.abs(lastX - e.screenX) > moveThreshold) {
        time = e.screenX/step;
        m.seekAbsoluteTime(time);
        lastX = e.screenX;
    }
    // the vertical axis controls the movie saturation
    m.saturation = v.size.height / e.screenY;
}, false);
