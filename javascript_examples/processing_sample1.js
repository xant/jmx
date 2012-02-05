width = 640;
height = 480;

drawer = new DrawPath(width, height);

// comment the following lines if you don't want 
// the output window to be automatically created
output = new VideoOutput(width, height);
drawer.outputPin('frame').connect(output.inputPin('frame'));


// uncomment the following line if you want the outputframe exported on the board
//drawer.outputPin('frame').export();

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

