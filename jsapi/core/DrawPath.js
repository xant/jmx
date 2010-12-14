/**
 * DrawPath
 * @addon
 * @base VideoEntity
 * @constructor
 * @param {int} width The width of the generated frame
 * @param {int} height The height of the generated frame
 * @class
 * Wrapper class for JMXDrawEntity instances.
 */
function DrawPath(width, height)
{

}

/**
 * Draw a circle.
 * @param {Point} center
 * @param {float} radius
 * @param {Color} strokeColor
 * @param {Color} fillColor
 * @addon
 */
DrawPath.prototype.drawCirle = function(center, radius, strokeColor, fillColor) {
    // ...
}

/**
 * Draw a polygon.
 * @param {Array} points
 * @param {Color} strokeColor
 * @param {Color} fillColor
 * @addon
 */
DrawPath.prototype.drawPolygon = function(points, strokeColor, fillColor) {
    // ...
}

/**
 * Clear the frame.
 * @addon
 */
DrawPath.prototype.clear = function() {
    // ...
}

