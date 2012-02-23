/**
 * @fileoverview
 * Text drawing 
 */

/**
 * TextEntity
 * @base VideoEntity
 * @constructor
 * @param {String} text The initial text (can be omitted)
 * @class Render text into a video frame
 * <h3>InputPins:</h3>
 *  <ul>
 *  <li>fontName</li>
 *  <li>setText</li>
 *  <li>setFontSize</li>
 *  <li>setFontColor</li>
 *  <li>setBackgroundColor</li>
 *  </ul>
 * <h3>OutputPins:</h3>
 *  <ul>
 *  </ul>
 *
 */
function TextEntity(text)
{
    /**
     * Set the text to render
     * @param {String} text
     */
    this.setText = function(text) {
    }

    /**
     * Set the font which must be used when rendering the text
     * @param {String} font string identifier (css font strings are supported)
     */
    this.setFont = function(fontname) {
        // ...
    }

    /**
     * Set the text (font) color
     * @param {Color|String} color the color to use (css color strings are supported)
     */
    this.setFontColor = function(fontColor) {
        // ...
    }

    /**
     * Set the background color
     * @param {Color|String} color the color to use as background when rednedring the font
     */
    this.setBackgroundColor = function() {
        // ...
    }
    
    /**
     * The frequency of the entity.
     * Controls how often the entity will signal the current frame on its 'frame' output pin
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

