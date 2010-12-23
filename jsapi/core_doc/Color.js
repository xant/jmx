/**
 * @fileoverview
 * RGBA color
 */

/**
 * Color is a wrapper class to JMXColor objects (used within the JMX engine)
 * @constructor
 * @class Wraps a JMXColor object and makes it available to javascript
 */
function Color(r, g, b, a)
{ 
    /**
     * The red component
     * @type float
     */
    this.redComponent = r;
    /**
     * The green component
     * @type float
     */
    this.greenComponent = g;
    /**
     * The blue component
     * @type float
     */
    this.blueComponent = b;
    /**
     * The alpha component
     * @type float
     */
    this.alphaComponent = a;
    // ... 
}
