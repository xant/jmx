/**
 * @fileoverview
 * Grab samples from an video input device (Abstract Class)
 */

/**
 * VideoCapture
 * @constructor
 * @param {String} device The device UID.
 *                        Available UIDs can be obtained by calling 
 *                        the {@link VideoCapture#availableDevices} method.
 * @param {String} type The specific implementation type, 
 *                      pass a null value to use the default
 *                      QT-based implementation
 * @base VideoEntity
 * @class grab video samples from an input device
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>device {String}</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li>video {Image}</li>
 *  </ul>
 *
 */
function VideoCapture(device, type)
{
    /* TODO - type selection based on the device */
    if (!type)
        return QtVideoCapture(device);
    else
        echo("Unsupported device type " + type);
    
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
    
    /**
     * Select a specific device
     * @param {String} device the UID of the device to select
     */
    this.selectDevice = function(device) { };
}

/**
 * Return an array containing UIDs for all available devices
 * @returns {Array} an array of UIDs {String} for each available device
 */
VideoCapture.availableDevices = function()
{
    ret = new Array();
    ret = ret.concat(QtVideoCapture.availableDevices());
    /* TODO - add further backends */
    return ret;
}

/**
 * Return the UID of the default device
 * @returns {String} The UID for the default input device
 */
VideoCapture.defaultDevice = function()
{
    return QtVideoCapture.defaultDevice();
}

