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
    this.r = r;
    /**
     * The green component
     * @type float
     */
    this.g = g;
    /**
     * The blue component
     * @type float
     */
    this.b = b;
    /**
     * The alpha component
     * @type float
     */
    this.a = a;
    // ... 
}
