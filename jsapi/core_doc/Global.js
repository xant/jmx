/**
 * @fileoverview
 * Functions and properties available in the Global object
 */
function Global() {
    /**
     * The JMX Document (w3c DOM Level 3 - compliant)
     * @type Document
     */
    this.document = null;

    /**
     * The scriptEntity owning this global context
     * @type ScriptEntity
     */
    this.scriptEntity = null;
    
    /**
     * print provided string to stdout
     * @param {String} string the string to print out
     */
    this.echo = function(string) {
        // ...
    }

    /**
     * just an alias to echo()
     * @param {String} string the string to print out
     */
    this.print = function(string) {
        
    }

    /** Get a random integer number (uses arc4random())
     * @returns Int
     */
    this.rand = function() {
        
    }

    /** Get a random float number
     * @returns Float
     */
    this.frand = function() {
        
    }

    /**
     * Execute an external javascript file
     * @param {String} path The path of the javascript file to include
     */
    this.include = function(path) {
        
    }

    /**
     * Sleep for the requested amount of time
     * @param {Float} secs the seconds to sleep (accepts fractions of seconds)
     */
    this.sleep = function(secs) {
        
    }

    /**
     * List the content of a directory
     * @param {String} the path of the directory to scan
     * @returns Array of strings
     */
    this.lsdir = function(path) {
        
    }

    /** 
     * Check wether a given path is a directory
     * @param {String} the path to check
     * @returns Bool true if the given path is a directory, false otherwise.
     */
    this.isdir = function(path) {
        
    }

    /**
     * Export a pin through the global scriptEntity object (will be also available on the GUI for connections).
     * Using this method it's possible to expose pins owned by inner entities (not visible on the GUI) so that other 
     * external entities (created throught the GUI or from another script) can connect to them 
     * @param {Pin} the pin to export
     */
    this.exportPin = function(pin) {
        
    }
    
    /**
     * Dump the comple JMX DOM
     * @returns String
     */
    this.dumpDOM = function() {
    }

    /**
     * Take over the main runloop (for the current script) running the provided function in loop until global.quit() is called
     * @param {Function} function The function implementing the runloop
     */
    this.run = function(f) {
    }

    /**
     * Break the current runloop
     */
    this.quit = function() {
    }

    /**
     * Add a call back to the current runloop (the call back will be called until the script will complete its execution)
     * @param {Function} callback The callback to call at each runcycle
     */
    this.addRunLoop = function(callback) {
    }
}


/**
 * ScriptEntity
 * @base Entity
 * @class JMX Entity holding the global javascript context for the running script
 */
function ScriptEntity() {
    /**
     * The frequency of the entity (which also affects the maximum resolution of timers (both intervals and timeouts).
     * @type float
     */
    this.frequency = 0;

    /**
     * Readonly array of all entities created by the script (and children of this entity in the DOM hierarchy)
     * @type Array
     */
    this.entities = null;
}
