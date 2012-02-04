width = 640;
height = 480;

drawer = new DrawPath(width, height);
drawer.start();

// UNCOMMENT TO ACTIVATE A VIDEO FILTER
filter = new VideoFilter("CIZoomBlur");
drawer.outputPin('frame').connect(filter.inputPin('frame'));
filter.outputPin('frame').export('filteredFrame');

// COMMENT THE FOLLOWING TWO LINES IF FILTER HAS BEEN ACTIVATED
drawer.outputPin('frame').export();
drawer.outputPin('frameSize').export();
drawer.inputPin('saturation').export();

audio = new AudioCapture;
audio.start();

spectrum = new AudioSpectrum;
audio.outputPin('audio').connect(spectrum.inputPin('audio'));

output = new VideoOutput(width, height);
output.inputPin('frame').connect(filter.outputPin('frame'));
// Global variables
radius = 50.0;
delay = 16;

function sketchProc(processing) {
  // set canvas size known by processing
  processing.width = width;
  processing.height = height;
  //processing.size( 200, 200 );
  processing.strokeWeight( 10 );
  processing.frameRate( 15 );
  X = width / 2;
  Y = height / 2;
  nX = X;
  nY = Y;  
  // Override draw function, by default it will be called 60 times per second
  processing.draw = function() {
    radius = radius + Math.sin( processing.frameCount / 4 );
          
    // Track circle to new destination
    X+=(nX-X)/delay;
    Y+=(nY-Y)/delay;
    //       
    // Fill canvas grey
    processing.background( 100 );
                 
    // Set fill-color to blue
    processing.fill( 0, 121, 184 );
    
    // Set stroke-color white
    processing.stroke(255); 
                             
    // Draw circle
    processing.ellipse( X, Y, radius, radius ); 
  };
}

//var canvas = $('canvas:first', drawer).get(0);
// attaching the sketchProc function to the canvas
var processingInstance = new Processing(drawer.canvas, sketchProc);

old250 = 0;
pin = filter.inputPin('inputAmount');
pin.data = 0;
spectrum.outputPin('250Hz').connect(function(f) {
    diff = f - old250;
    if (diff > 0.5)
        radius += 10;
    if (diff < 0)
        radius -= 2;

    if (radius < 15)
        radius = 15;
    if (radius > 300)
        radius = 300;
    old250 = f;
    drawer.saturation = f;
    pin.data = f;
});
