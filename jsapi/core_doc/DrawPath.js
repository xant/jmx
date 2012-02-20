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
    /***
     * save
     * TODO: Document
     */
    this.save = function() { }

    /***
     * restore
     * TODO: Document
     */
    this.restore = function() { }

    /***
     * scale
     * TODO: Document
     */
    this.scale = function() { }

    /***
     * rotate
     * TODO: Document
     */
    this.rotate = function() { }

    /***
     * translate
     * TODO: Document
     */
    this.translate = function() { }

    /***
     * transform
     * TODO: Document
     */
    this.transform = function() { }

    /***
     * setTransform
     * TODO: Document
     */
    this.setTransform = function() { }

    /***
     * createLinearGradient
     * TODO: Document
     */
    this.createLinearGradient = function() { }

    /***
     * createRadialGradient
     * TODO: Document
     */
    this.createRadialGradient = function() { }

    /***
     * createPattern
     * TODO: Document
     */
    this.createPattern = function() { }

    /***
     * clearRect
     * TODO: Document
     */
    this.clearRect = function() { }

    /***
     * fillRect
     * TODO: Document
     */
    this.fillRect = function() { }

    /***
     * strokeRect
     * TODO: Document
     */
    this.strokeRect = function() { }

    /***
     * beginPath
     * TODO: Document
     */
    this.beginPath = function() { }

    /***
     * closePath
     * TODO: Document
     */
    this.closePath = function() { }

    /***
     * moveTo
     * TODO: Document
     */
    this.moveTo = function() { }

    /***
     * lineTo
     * TODO: Document
     */
    this.lineTo = function() { }

    /***
     * quadraticCurveTo
     * TODO: Document
     */
    this.quadraticCurveTo = function() { }

    /***
     * bezierCurveTo
     * TODO: Document
     */
    this.bezierCurveTo = function() { }

    /***
     * arcTo
     * TODO: Document
     */
    this.arcTo = function() { }

    /***
     * rect
     * TODO: Document
     */
    this.rect = function() { }

    /***
     * arc
     * TODO: Document
     */
    this.arc = function() { }

    /***
     * fill
     * TODO: Document
     */
    this.fill = function() { }

    /***
     * stroke
     * TODO: Document
     */
    this.stroke = function() { }

    /***
     * clip
     * TODO: Document
     */
    this.clip = function() { }

    /***
     * isPointInPath
     * TODO: Document
     */
    this.isPointInPath = function() { }

    /***
     * drawFocusRing
     * TODO: Document
     */
    this.drawFocusRing = function() { }

    /***
     * drawImage
     * TODO: Document
     */
    this.drawImage = function() { }

    /***
     * strokeText
     * TODO: Document
     */
    this.strokeText = function() { }

    /***
     * measureText
     * TODO: Document
     */
    this.measureText = function() { }

    /***
     * fillText
     * TODO: Document
     */
    this.fillText = function() { }

    /***
     * getImageData
     * TODO: Document
     */
    this.getImageData = function() { }

    /***
     * createImageData
     * TODO: Document
     */
    this.createImageData = function() { }

    /***
     * putImageData
     * TODO: Document
     */
    this.putImageData = function() { }


    /***
     * globalAlpha
     * TODO: Document
     */
    this.globalAlpha = null;

    /***
     * fillStyle
     * TODO: Document
     */
    this.fillStyle = null;

    /***
     * strokeStyle
     * TODO: Document
     */
    this.strokeStyle = null;

    /***
     * globalCompositeOperation
     * TODO: Document
     */
    this.globalCompositeOperation = null;

    /***
     * font
     * TODO: Document
     */
    this.font = null;

    /***
     * lineWidth
     * TODO: Document
     */
    this.lineWidth = null;

    /***
     * shadowColor
     * TODO: Document
     */
    this.shadowColor = null;

    /***
     * shadowOffsetX
     * TODO: Document
     */
    this.shadowOffsetX = null;

    /***
     * shadowOffsetY
     * TODO: Document
     */
    this.shadowOffsetY = null;

    /***
     * shadowBlur
     * TODO: Document
     */
    this.shadowBlur = null;

}


