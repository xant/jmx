/**
 * Movie
 * @addon
 * @constructor
 * @base ThreadedEntity
 * @class
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>brightness</li>
 *  <li>saturation</li>
 *  <li>contrast</li>
 *  <li>alpha</li>
 *  <li>rotation</li>
 *  <li>origin</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li>frame</li>
 *  <li>frameSize</li>
 *  </ul>
 *
 */
function VideoEntity()
{
    /**
     * The brightness of the output frame.
     * @type float
     */
    this.brightness = 0;
    /**
     * The saturation of the output frame.
     * @type float
     */
    this.saturation = 0;
    /**
     * The contrast of the output frame.
     * @type float
     */
    this.contrast = 0;
    /**
     * The alpha of the output frame.
     * @type float
     */
    this.alpha = 0;
    /**
     * The rotation degrees of the output frame.
     * @type float
     */
    this.rotation = 0;
    /**
     * The origin of the output frame.
     * @type Point
     */
    this.origin = 0;
}
