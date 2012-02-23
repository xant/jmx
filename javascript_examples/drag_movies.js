m1 = new MovieFile('/Users/xant/test.mov');
m2 = new MovieFile('/Users/xant/test.mov');

m1.origin = new Point(100, 100);
m1.scaleRatio = 0.25;
m2.origin = new Point(0, 0);
m2.scaleRatio = 0.25;

movies = new Array(m1, m2);

v = new VideoOutput(640, 480);;
mixer = new VideoMixer();
mixer.size = v.size;
mixer.input.video.connect(m1.output.frame);
mixer.input.video.connect(m2.output.frame);
mixer.output.frame.connect(v.input.frame);

selected_movie = null;
initial_origin = null;
mouse_pressed = null;

document.addEventListener("mousepressed", function(e) {
    mouse_pressed = new Point(e.screenX, e.screenY);
    for (i in movies) {
        m = movies[i];
        mwidth = m.size.width*m.scaleRatio;
        mheight = m.size.height*m.scaleRatio;
        xedge = m.origin.x + mwidth;
        yedge = m.origin.y + mheight;
        if (e.screenX >= m.origin.x && e.screenX <= xedge &&
            e.screenY >= m.origin.y && e.screenY <= yedge)

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
        mwidth = selected_movie.size.width*selected_movie.scaleRatio;
        mheight = selected_movie.size.height*selected_movie.scaleRatio;
        computedX = initial_origin.x + (e.screenX - mouse_pressed.x);
        computedY = initial_origin.y + (e.screenY - mouse_pressed.y);
        marginX = v.size.width-mwidth-1;
        marginY = v.size.height-mheight-1;
        neworiginX = Math.max(Math.min(computedX, marginX), 0);
        neworiginY = Math.max(Math.min(computedY, marginY), 0); 
        selected_movie.origin = new Point(neworiginX, neworiginY);
    }
}, false);
