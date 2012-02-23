/**
 * @fileoverview
 * HTML5 canvas element
 */

/**
 * HTMLCanvasElement
 * @base Node
 * @constructor
 * @class class compliant to the HTML5 canvas element w3c spec
 */
function HTMLCanvasElement() {
    /**
     * The width of the video output
     * @type int
     */
    this.width;
    /**
     * The height of the video output
     * @type int
     */
    this.height;
    /**
     * Get the underlying drawing context
     * @param {string} type "2d" or "3d" (only "2d" context is supported yet)
     * @returns {CanvasRenderingContext2D}
     */
    this.getContext = function() { }
    
    /**
     * TODO - Document
     */
    this.toDataURL = function() { }

}

