/**
 * @fileoverview
 * Grab samples from an audio input device
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
}

AudioCapture.availableDevices = function()
{
    ret = new Array();
    QtKitDevices = QtAudioCapture.availableDevices();
    /* TODO - extra implementations */
    ret = ret.concat(QtKitDevices);
    return ret;
}


