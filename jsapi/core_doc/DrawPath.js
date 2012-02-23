/**
 * @fileoverview
 * 2D drawing through bezier paths
 */

/**
 * DrawPath
 * @base VideoEntity
 * @constructor
 * @param {int} width The width of the generated frame
 * @param {int} height The height of the generated frame
 * @class Wrapper class for JMXDrawEntity instances.
 * Such objects allow fast 2d-drawing on a video buffer which is sent as output
 */
function DrawPath(width, height)
{
    /**
     * The underlying canvas element
     * @type HTMLCanvasElement
     */
    this.canvas = null;

    /**
     * Draw a circle.
     * @param {Point} center
     * @param {float} radius
     * @param {Color} strokeColor
     * @param {Color} fillColor
     */
    this.drawCircle = function(center, radius, strokeColor, fillColor) {
        // ...
    }

    /**
     * Draw a polygon.
     * @param {Array} points
     * @param {Color} strokeColor
     * @param {Color} fillColor
     */
    this.drawPolygon = function(points, strokeColor, fillColor) {
        // ...
    }

    /**
     * Clear the frame.
     */
    this.clear = function() {
        // ...
    }
    
    /**
     * The frequency of the entity.
     * @type float
     */
    this.frequency = 0;
    
    /**
     * Start the entity
     * @addon
     */
    this.start = function() { }
    
    /**
     * Stop the entity
     */
    this.stop = function() { }
}


