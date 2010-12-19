/**
 * @fileoverview
 * Send received samples to an audio output device
 */

/**
 * AudioOutput
 * @constructor
 * @param {String} type The specific implementation type, 
 *                      pass a null value to use the default
 *                      CoreAudio-based implementation
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
function AudioOutput(type)
{
    if (!type)
        return CoreAudioOutput(device);
    else
        echo("Unsupported device type " + type);
}