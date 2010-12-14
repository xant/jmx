/**
 * MovieFile
 * @addon
 * @constructor
 * @base VideoEntity
 * @class
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>path {String}</li>
 *  <li>repeat {Bool}</li>
 *  <li>pause {Bool}</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  </ul>
 *
 */
function MovieFile()
{
    this.path = "";
    this.repeat = false;
    this.paused = false;
}

/**
 * Open movie file at specified path
 * @addon
 */
MovieFile.prototype.open = function(path) {
    // ...
}

/**
 * Close the current movie file (if any)
 * @addon
 */
MovieFile.prototype.close = function() {
    // ...
}



