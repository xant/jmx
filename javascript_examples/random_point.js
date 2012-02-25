//
// example script which implements a simple entity to generate a new point at random coordinates
// changing the frequency of the scriptEntity will control how often a new point is signaled
//
output = new OutputPin("point", "Point"); // create an output pin of type 'Point'

frequencyPin = scriptEntity.inputPin('frequency');
frequencyPin.data = 25; // default to 25 points per seconds

width = 640;
height = 480;

f = function() {
    output.data = new Point(rand()%width, rand()%height);
    setTimeout(f, 1000/frequencyPin.data);
}

// allow to change the dimensions in which the poin should fall
size = new InputPin("size", "Size", function(s) { width = s.width; height = s.height; });
size = new InputPin("width", "Number", function(w) { width = w; }); // allow to change the width only
size = new InputPin("height", "Number", function(h) { height = h; }); // allow to change the height only

f();

