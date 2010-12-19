/**
 * CoreImageFilter
 * @base Entity
 * @constructor
 * @param {String} filterName The name of the filter.
 * @class Wrapper class for JMXCoreImageFilter entities
 *  <h3>InputPins:</h3>
 *  <ul>
 *  <li>filter {String}</li>
 *  <li>frame {Image}</li>
 *  <li> ... </li>
 *  </ul>
 *  <h3>OutputPins:</h3>
 *  <ul>
 *  <li>frame {Image}</li>
 *  </ul>
 
 */
function CoreImageFilter(filterName)
{

    /**
     * The name of the selected filter.
     * When trying to set a new value, the accessor will also try to select that filter 
     * If the filter exists, the new value is assigned to the field, otherwise the old value will be preserved
     * @type string
     */
    this.filter = '';

    /**
     * Select a specific coreimage filter.
     * @param {String} filterName The name of the coreimage filter to use.
     *                            A list can be obtained by calling the {@link CoreImageFilter#availableFilters} method
     */
    this.selectFilter = function(filterName) {

    // ...
}

    // ...
}

/**
 * Returns a list of available filters (strings).
 */
CoreImageFilter.availableFilters = function() {
    // ...
}


