m = new MovieFile('/Users/xant/sample_iTunes.mov');
v = new VideoOutput(m.size.width, m.size.height);

m.output.frame.connect(v.input.frame);
step = v.size.width / m.duration;

document.addEventListener("mousemove", function(e) {
    time = e.screenX/step;
    m.seekAbsoluteTime(time);
}, false);

