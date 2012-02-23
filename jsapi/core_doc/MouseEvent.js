/**
 * @fileoverview
 * Mouse events (compliant with the homonym w3c HTML5 spec)
 */

/**
 * MouseEvent
 * @class Represents a mouse event propagated to listeners
 * @base Event
 */
function MouseEvent()
{
    /**
     * TODO - document
     * @type int
     */
    this.screenX = null;
    /**
     * TODO - document
     * @type int
     */
    this.screenY = null;
    /**
     * TODO - document
     * @type int
     */
    this.pageX = null;
    /**
     * TODO - document
     * @type int
     */
    this.pageY = null;
    /**
     * TODO - document
     * @type int
     */
    this.clientX = null;
    /**
     * TODO - document
     * @type int
     */
    this.clientY = null;
}
