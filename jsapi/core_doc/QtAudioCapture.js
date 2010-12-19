/**
 * @fileoverview
 * Grab samples from a QTKit audio-input device
 */

/**
 * QtAudioCapture
 * @constructor
 * @param {String} device The device UID.
 *                        Available UIDs can be obtained by calling 
 *                        the {@link QtAudioCapture#availableDevices} method.
 * @base AudioCapture
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
function QtAudioCapture(device)
{
    // ...
}

QtAudioCapture.availableDevices = function()
{
    // ...
}


