output = new OutputPin("count", "Point");

frequencyPin = scriptEntity.inputPin('frequency');
frequencyPin.data = 25; // default to 25 points per seconds

width = 640;
height = 480;

f = function() {
    output.data = new Point(rand()%width, rand()%height);
    setTimeout(f, 1000/frequencyPin.data);
}

size = new InputPin("size", "Size", function(s) { width = s.width; height = s.height; });
size = new InputPin("width", "Number", function(w) { width = w; });
size = new InputPin("height", "Number", function(h) { height = h; });

f();

