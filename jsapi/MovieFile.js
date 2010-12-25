/**
 * @fileoverview
 * Read frames from video files
 */

/**
 * MovieFile
 * @constructor
 * @param {String} path The path of the movie file.
 * @base VideoEntity
 * @class Abstract class implementing basic functionalities for entities grabbing video frames from movie files.
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
function MovieFile(path, type)
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
}

/**
 * Returns a list of supported video file types
 */
MovieFile.supportedFileTypes = function() {
    ret = new Array();
    ret = ret.concat(QtMovieFile().supporterFileTypes());
    /* TODO - add further file-reader implementations  */
    return ret;
}

