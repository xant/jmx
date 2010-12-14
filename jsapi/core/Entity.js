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
 *  <li>name {String}</li>
 *  <li>active {Bool}</li>
 *  </ul>
 *  <br/>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  <li>active {Bool}</li>
 *  </ul>
 *  <br/>
 */
function Entity()
{ 
    /**
     * The name of the entity.
     * @type String
     */
    this.name = "";
    /**
     * The description of the entity (readonly)
     * @type String
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
 * @param {String} pinName the name of the input pin
 */
Entity.prototype.inputPin = function(pinName) {
    // ...
}

/**
 * Get the output Pin object registered with the provided name
 * @addon
 * @param {String} pinName the name of the output pin
 */
Entity.prototype.outputPin = function(pinName) {
    // ...
}
