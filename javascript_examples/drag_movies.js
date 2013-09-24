// open movie files
m1 = new MovieFile('/Users/xant/test.mov');
m2 = new MovieFile('/Users/xant/Downloads/VIDEO0051.3gp');
m3 = new MovieFile('/Users/xant/Documents/Music/black eyed peas/Black Eyed Peas - Let\'s Get It Started.avi');

// set their initial origin and scale them
// (you could want to disable scaling if your movies are small enough)
m1.origin = new Point(0, 0);
m1.scaleRatio = 0.25;
m2.origin = new Point(100, 100);
m2.scaleRatio = 0.25;
m3.origin = new Point(200, 200);
m3.scaleRatio = 0.75;

// keep all movie files into an array
movies = new Array(m1, m2, m3);

// create a video output (size doesn't really matter)
v = new VideoOutput(640, 480);
v.invertYCoordinates = false;

// and create a videomixer so that we can blend the movie files on the same video frame
mixer = new VideoMixer();
mixer.size = v.size; // let's have the videomixer output a frame as big as the output window

// connect the movies to to the mixer
mixer.input.video.connect(m1.output.frame);
mixer.input.video.connect(m2.output.frame);
mixer.input.video.connect(m3.output.frame);
// and the mixer to the video   output
mixer.output.frame.connect(v.input.frame);
mixer.frequency = 90;

// initialize globals to null
selected_movie = null;
initial_origin = null;
mouse_pressed = null;

// track mouseclicks and check if they hit a visible movie
// if it does, let's keep track of it
document.addEventListener("mousedown", function(e) {
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

// if the mouse button is released we don't care about the selected 
// movie anymore and we need to reset our globals
document.addEventListener("mouseup", function(e) {
    mouse_pressed = null;
    selected_movie = null;
    initial_origin = null;
}, false);

// if the mouse is being dragged while a movie is selected
// (AKA: has been hit when the mouse button was pressed)
// we can move the origin of the selected movie to follow the mouse pointer
document.addEventListener("mousemove", function(e) {
    if (selected_movie) {
        // sort out the scaled movie size 
        mwidth = selected_movie.size.width*selected_movie.scaleRatio;
        mheight = selected_movie.size.height*selected_movie.scaleRatio;
        // compute the mouse movement
        // (which is the delta between the current position and the initial one)
        computedX = initial_origin.x + (e.screenX - mouse_pressed.x);
        computedY = initial_origin.y + (e.screenY - mouse_pressed.y);
        // check the frame margin (because we don't want the movie
        // to end up out of the visible area)
        marginX = v.size.width-mwidth-1;
        marginY = v.size.height-mheight-1;
        // compute the new origin
        neworiginX = Math.max(Math.min(computedX, marginX), 0);
        neworiginY = Math.max(Math.min(computedY, marginY), 0);
        // and finally move the movie to the new origin
        selected_movie.origin = new Point(neworiginX, neworiginY);
    }
}, false);
