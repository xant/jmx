/**
 * @fileoverview
 * Read frames from video files
 */

/**
 * MovieFile
 * @constructor
 * @base VideoEntity
 * @class Wrapper class for JMXQtMovieEntity objects.
 * Such objects will extract video frames from supported video file types and will provide images on their 'frame' output pin
 * Supported file types can be obtained calling the {@link MovieFile#supportedFileTypes} method
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>path {String}</li>
 *  <li>repeat {Bool}</li>
 *  <li>pause {Bool}</li>
 *  </ul>
 *
 */
function MovieFile()
{
    this.path = "";
    this.repeat = false;
    this.paused = false;

    /**
     * Open movie file at specified path
     * @param {String} path The path of the video file.
     */
    this.open = function(path) {
        // ...
    }

    /**
     * Close the current movie file (if any)
     */
    this.close = function() {
        // ...
    }
}

/**
 * Returns a list of supported video file types
 */
MovieFile.supportedFileTypes = function() {
    // ...
}

