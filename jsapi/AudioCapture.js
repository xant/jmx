/**
 * @fileoverview
 * Grab samples from an audio input device (Abstract Class)
 */

/**
 * AudioCapture
 * @constructor
 * @param {String} device The device UID.
 *                        Available UIDs can be obtained by calling 
 *                        the {@link AudioCapture#availableDevices} method.
 * @param {String} type The specific implementation type, 
 *                      pass a null value to use the default
 *                      QT-based implementation
 * @base Entity
 * @class grab audio samples from an input device
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>device {String}</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li>audio {Audio}</li>
 *  </ul>
 *
 */
function AudioCapture(device, type)
{
    /* TODO - type selection based on the device */
    if (!type)
        return QtAudioCapture(device);
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
 * @returns {Array} Array of UDIDs {string} for each available device
 */
AudioCapture.availableDevices = function()
{
    ret = new Array();
    QtKitDevices = QtAudioCapture.availableDevices();
    /* TODO - extra implementations */
    ret = ret.concat(QtKitDevices);
    return ret;
}

/**
 * Return the UID of the default device
 * @returns {String} The UID for the default input device
 */
AudioCapture.defaultDevice = function()
{
    ret = new Array();
    ret.concat(QtAudioCapture.defaultDevice());
    // add further backends here
    return ret;
}

