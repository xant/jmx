/**
 * Color is a wrapper class to JMXColor objects (used within the JMX engine)
 * @addon
 * @constructor
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
