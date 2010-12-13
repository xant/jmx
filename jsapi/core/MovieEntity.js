/**
 * MovieEntity
 * @addon
 * @constructor
 * @base VideoEntity
 * @class
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>path</li>
 *  <li>repeat</li>
 *  <li>pause</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  </ul>
 *
 */
function MovieEntity()
{
    this.path = "";
    this.repeat = false;
    this.paused = false;
}

/**
 * Open movie file at specified path
 * @addon
 */
ThreadedEntity.prototype.open = function(path) {
    // ...
}

/**
 * Close the current movie file (if any)
 * @addon
 */
ThreadedEntity.prototype.close = function() {
    // ...
}



