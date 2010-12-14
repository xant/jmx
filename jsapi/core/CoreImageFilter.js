/**
 * CoreImageFilter
 * @addon
 * @base Entity
 * @constructor
 * @param {String} filterName The name of the filter.
 * @class
 * Wrapper class for JMXPin instances.
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
    // ...
}

/**
 * Returns a list of available filters (strings).
 * @addon
 */
CoreImageFilter.availableFilters = function() {
    // ...
}

/**
 * Select a specific coreimage filter.
 * @param {String} filterName The name of the coreimage filter to use.
 *                            A list can be obtained by calling CoreImageFilter.availableFilter() 
 * @addon
 */
CoreImageFilter.prototype.selectFilter = function(filterName) {
    // ...
}

