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
function CoreImageFilter(width, height)
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
CorImageFilter.prototype.drawCirle = function(center, radius, strokeColor, fillColor) {
    // ...
}

/**
 * Draw a polygon.
 * @param {Array} points
 * @param {Color} strokeColor
 * @param {Color} fillColor
 * @addon
 */
CorImageFilter.prototype.drawPolygon = function(points, strokeColor, fillColor) {
    // ...
}

/**
 * Clear the frame.
 * @addon
 */
CorImageFilter.prototype.clear = function() {
    // ...
}

