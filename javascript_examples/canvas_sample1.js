output = new VideoOutput(800, 450);
var drawer = new DrawPath(800, 450);

drawer.outputPin('frame').connect(output.inputPin('frame'));
var canvas = drawer.canvas;

 //var canvas = document.getElementsByTagName('canvas')[0];
 var context = canvas.getContext('2d');
echo(context);

echo(canvas.height);
echo(canvas.width);
 var lastX = canvas.width * Math.random();
 var lastY = canvas.height * Math.random();
 var hue = 0;
 function line() {
   context.save();
   context.translate(canvas.width/2, canvas.height/2);
   context.scale(0.9, 0.9);
   context.translate(-canvas.width/2, -canvas.height/2);
   context.beginPath();
   context.lineWidth = 5 + Math.random() * 10;
   context.moveTo(lastX, lastY);
   lastX = canvas.width * Math.random();
   lastY = canvas.height * Math.random();
   context.bezierCurveTo(canvas.width * Math.random(),
                         canvas.height * Math.random(),
                         canvas.width * Math.random(),
                         canvas.height * Math.random(),
                         lastX, lastY);

   hue = hue + 10 * Math.random();
   context.strokeStyle = 'hsl(' + hue + ', 50%, 0.5)';
   context.shadowColor = 'white';
   context.shadowBlur = 10;
   context.stroke();
   context.restore();
 }
 setInterval(line, 50);

 function blank() {
   context.fillStyle = 'rgba(0, 0, 0, 0.1)';
   context.fillRect(0, 0, canvas.width, canvas.height);
 }
 setInterval(blank, 40);

