/**
 * @fileoverview
 * Apply a filter to video frames (Abstract Class)
 */

/**
 * VideoFilter
 * @addon
 * @constructor
 * @param {String} filterName the name of the filter
 * @param {String} filterType the type of the filter
 * @base Entity
 * @class
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
function VideoFilter(filterName, filterType)
{
    if (!filterType || filterType == "CoreImage")
        return new CoreImageFilter(filterName);
    
    // The following declarations are here for documentation purposes only
    
    /**
     * The name of the selected filter.
     * When trying to set a new value, the accessor will also try to select that filter 
     * If the filter exists, the new value is assigned to the field, otherwise the old value will be preserved
     * @type string
     */
    this.filter;
    
    /**
     * Select a specific filter.
     * @param {String} filterName The name of the  filter to use.
     *                            A list can be obtained by calling the {@link VideoFilter#availableFilters} method
     */
    this.selectFilter = function(filterName) {
        // ...
    }
}

/**
 * Returns a list of available filters (strings) from all supported backends
 * XXX - at the moment only CoreImageFilter is supported.
 */
VideoFilter.availableFilters = function() {
    // list filters from all implemented backends
    // Core Image
    ret = new Array();
    /* TODO - extra backends */
    ret = ret.concat(CoreImageFilter().availableFilters());
    return ret;
}

