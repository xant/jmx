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
}


