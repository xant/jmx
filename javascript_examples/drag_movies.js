m1 = new MovieFile('/Users/xant/test.mov');
m2 = new MovieFile('/Users/xant/test.mov');

v = new VideoOutput();
mixer = new VideoMixer();
mixer.input.video.connect(m1.output.frame);
mixer.input.video.connect(m2.output.frame);
mixer.output.frame.connect(v.input.frame);

m2.scaleRatio = 0.2;
m1.scaleRatio = 0.2;
m1.origin = new Point(100, 100);
m2.origin = new Point(0, 0);
movies = new Array(m1, m2);

selected_movie = null;
initial_origin = null;

document.addEventListener("mousepressed", function(e) {
    mouse_pressed = new Point(e.screenX, e.screenY);
    for (i in movies) {
        m = movies[i];
        mwidth = m.size.width*m.scaleRatio;
        mheight = m.size.height*m.scaleRatio;
        if (e.screenX >= m.origin.x && e.screenX <= m.origin.x + mwidth &&
            e.screenY >= m.origin.y && e.screenY <= m.origin.y + mheight)

        {
            selected_movie = m;
            initial_origin = m.origin;
            break;
        }
    }
}, false);

document.addEventListener("mousereleased", function(e) {
    mouse_pressed = null;
    selected_movie = null;
    initial_origin = null;
}, false);


document.addEventListener("mousedragged", function(e) {
    if (selected_movie) {
        neworiginx = initial_origin.x + (e.screenX - mouse_pressed.x);
        neworiginy = initial_origin.y + (e.screenY - mouse_pressed.y);
        selected_movie.origin = new Point(neworiginx, neworiginy);
    }
}, false);
