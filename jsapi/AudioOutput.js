/**
 * @fileoverview
 * Send received samples to an audio output device (Abstract Class)
 */

/**
 * AudioOutput
 * @constructor
 * @param {String} device The device to open.
 * @param {String} type The specific backend implementation (for instance: CoreAudioOutput).
 *                      Pass a null value to use the default backend.
 * @base Entity
 * @class Send audio samples to an output device
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>audio {Audio}</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li>currentSample {Audio}</li>
 *  </ul>
 *
 */
function AudioOutput(device, type)
{
    if (!type)
        // TODO - backend-detection using the provided device
        return CoreAudioOutput(device); // revert to default backend
    else
        echo("Unsupported device type " + type);
}