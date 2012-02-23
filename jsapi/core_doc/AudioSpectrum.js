/**
 * @fileoverview
 * Analyze received samples and provide frequency values
 */

/**
 * AudioSpectrum
 * @constructor
 * @param {Array} frequencies An array containing the frequencies we want to be exposed through output pins
 * @base Entity
 * @class Analyze audio samples and provide frequencies
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>audio {Audio}</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li> 1-N frequency pins {Number}</li>
 *  <li>image {Image}</li>
 *  <li>imageSize {Size}</li>
 *  </ul>
 *
 */
function AudioSpectrum(frequencies)
{
    /**
     * Set the frquencies we want to be provided as output pins
     * @param {Array} frequencies  An array containing the frequencies we want to be exposed through output pins
     */
    this.setFrequencies = function(frequencies) { }

    // ...
}

