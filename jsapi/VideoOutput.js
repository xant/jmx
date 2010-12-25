/**
 * @fileoverview
 * Display video frames (Abstract Class)
 */

/**
 * VideoOutput
 * @addon
 * @constructor
 * @param {int} width The width of the new video output
 * @param {int} height The height of the new video output
 * @param {String} type The specific backend implementation (for instance: OpenGLScreen).
 *                      Pass a null value to use the default backend.
 * @base Entity
 * @class
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>frame {Image}</li>
 *  <li>frameSize {Size}</li>
 *  <li>pause {Bool}</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li>fps {Number}</li>
 *  </ul>
 *
 */
function VideoOutput(width, height, type)
{
    if (!type || type == "OpenGLScreen")
        return new OpenGLScreen(width, height);
    
    /**
     * The width of the video output
     * @type int
     */
    this.width;
    /**
     * The height of the video output
     * @type int
     */
    this.height;
}
