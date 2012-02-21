width = 640;
height = 480;

drawer = new DrawPath(width, height);
// the following is necessary to have coordinates matching between mouse events and the canvas context
drawer.canvas.getContext('2d').invertYCoordinates = true; 

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
  processing.frameRate( 25 );
  X = width / 2;
  Y = height / 2;
  nX = X;
  nY = Y;  
  // Override draw function, by default it will be called 60 times per second
  processing.draw = function() {
    radius = radius + Math.sin( processing.frameCount / 4 );
          
    // Track circle to new destination
    X+=(nX-X)/(delay*2);
    Y+=(nY-Y)/(delay*2);
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

  processing.mouseMoved = function() {
      nX = processing.mouseX;
      nY = processing.mouseY;  
  };
}

//var canvas = $('canvas:first', drawer).get(0);
// attaching the sketchProc function to the canvas
var processingInstance = new Processing(drawer.canvas, sketchProc);

