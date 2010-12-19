/**
 * ThreadedEntity
 * @addon
 * @constructor
 * @base Entity
 * @class
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>frequency</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li>frequency</li>
 *  </ul>
 *
 */
function ThreadedEntity()
{
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

