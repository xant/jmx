/**
 * @fileoverview
 * Base abstract Entity class
 */

/**
 * Entity is the abstract base class for all entities. It maps directly to a JMXEntity class within the JMX Engine
 * @addon
 * @constructor
 * @class
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>name</li>
 *  <li>active</li>
 *  </ul>
 *  <br/>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li>active</li>
 *  </ul>
 *  <br/>
 */
function Entity()
{ 
    /**
     * The name of the entity.
     * @type string
     */
    this.name = "";
    /**
     * The description of the entity (readonly)
     * @type string
     */
    this.description = "";
    /**
     * List containing names of all registered input pins
     * @type array
     */
    this.outputPins = Array();
    /**
     * List containing names of all registered output pins
     * @type array
     */
    this.outputPins = Array();
    /**
     * Determines the 'active' status of the entity
     * @type boolean
     */
    this.active = false;
}

/**
 * Get the input Pin object registered with the provided name
 * @addon
 */
Entity.prototype.inputPin = function(pinName) {
    // ...
}

/**
 * Get the output Pin object registered with the provided name
 * @addon
 */
Entity.prototype.outputPin = function(pinName) {
    // ...
}
