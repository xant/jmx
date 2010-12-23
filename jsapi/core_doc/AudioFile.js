/**
 * @fileoverview
 * Read samples from audio files
 */

/**
 * AudioFile
 * @constructor
 * @base ThreadedEntity
 * @class Read samples from audio files
 * Supported file types can be obtained calling the {@link AudioFile#supportedFileTypes} method
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>path {String}</li>
 *  <li>repeat {Bool}</li>
 *  <li>pause {Bool}</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li>audio {Audio}</li>
 *  </ul>
 *
 */
function AudioFile()
{
    this.path = "";
    this.repeat = false;
    this.paused = false;

    /**
     * Open audio file at specified path
     */
    this.open = function(path) { }

    /**
     * Close the current audio file (if any)
     */
    this.close = function() { }

    // ... 
}

/**
 * Returns a list of supported audio file types
 */
AudioFile.supportedFileTypes = function() {
    // ...
}
