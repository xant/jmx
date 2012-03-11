width = 640;
height = 480;

m = new MovieFile('/Applications/Adobe Photoshop CS5.1/Samples/CheeziPuffs.mov');
m.scaleRatio = (m.size.width > m.size.height)
               ? width / m.size.width
               : height / m.size.height;

v = new VideoOutput(width, height);
a = new AudioOutput();

m.output.frame.connect(v.input.frame);
m.output.audio.connect(a.input.audio);

step = v.size.width / m.duration;

document.addEventListener("mousemove", function(e) {
    time = e.screenX/step;
    m.seekAbsoluteTime(time);
    m.saturation = v.size.height / e.screenY;
}, false);
