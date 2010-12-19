/**
 * @fileoverview
 * Send received samples to an audio output device
 */

/**
 * AudioOutput
 * @constructor
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
function AudioOutput()
{
    if (!type)
        return CoreAudioOutput(device);
    else
        echo("Unsupported device type " + type);
}