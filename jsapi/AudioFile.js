/**
 * @fileoverview
 * Read frames from video files (Abstract Class)
 */

/**
 * AudioFile
 * @constructor
 * @param {String} path The path of the Audio file.
 * @param {String} type The specific backend implementation (for instance: CoreAudioFile).
 * @base Entity
 * @class Abstract class implementing basic functionalities for entities grabbing video frames from Audio files.
 * Such objects will extract video frames from supported video file types and will provide images on their 'frame' output pin
 * Supported file types can be obtained calling the {@link AudioFile#supportedFileTypes} method
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>path {String}</li>
 *  <li>repeat {Bool}</li>
 *  <li>pause {Bool}</li>
 *  </ul>
 *
 */
function AudioFile(path, type)
{
    if (!type) {
        // TODO implement type selection
        return CoreAudioFile();
    } else {
        // TODO
    }
    
    /* Documenation Only */
    
    this.path = "";
    this.repeat = false;
    this.paused = false;
    
    /**
     * Open Audio file at specified path
     * @param {String} path The path of the video file.
     */
    this.open = function(path) {
        // ...
    }
    
    /**
     * Close the current Audio file (if any)
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
AudioFile.supportedFileTypes = function() {
    ret = new Array();
    ret = ret.concat(CoreAudioFile().supporterFileTypes());
    /* TODO - add further file-reader implementations  */
    return ret;
}

