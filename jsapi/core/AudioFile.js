/**
 * AudioFile
 * @addon
 * @constructor
 * @base ThreadedEntity
 * @class
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
}

/**
 * Open audio file at specified path
 * @addon
 */
AudioFile.prototype.open = function(path) {
    // ...
}

/**
 * Close the current audio file (if any)
 * @addon
 */
AudioFile.prototype.close = function() {
    // ...
}




