/**
 * @fileoverview
 * JS Events (compliant with the homonym w3c HTML5 class spec)
 * check : http://dev.w3.org/html5/event/ for further details
 */

/**
 * Event
 * @class Wrapper class for DOM Event instances
 * @returns
 */
function Event()
{
    this.type = null;
    this.target = null;
    this.eventPhase = null;
    this.bubbles = null;
    this.eventPhase = null;
    this.cancelable = null;
}

