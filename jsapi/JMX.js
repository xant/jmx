/**
 * @fileoverview
 * This file is loaded at any script-startup.
 * Anything imported from here will be available
 * in any global context being executed
 */

/*Pin.prototype.toString = function() {
    return this.label;
}*/


if (process.argv[0] == 'jmx-cli') {
    global.print = function(str) {
        if (typeof(str) == 'function')
            process.stdout.write(str.toString());
        else
            process.stdout.write(str);
    }

    global.echo = function(str) {
        if (typeof(str) == 'function')
            process.stdout.write(str.toString() + "\n");
        else
            process.stdout.write(str + "\n");
    }
}

//echo("Done initializing JMX Core API");
