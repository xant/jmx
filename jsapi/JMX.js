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
        var ret = false;
        if (typeof(str) == 'function')
            ret = process.stdout.write(str.toString());
        else
            ret = process.stdout.write(str);
        return ret;
    }

    global.echo = function(str) {
        var ret = false;
        if (typeof(str) == 'function')
            ret = process.stdout.write(str.toString() + "\n");
        else
            ret = process.stdout.write(str + "\n");
        return ret;
    }
}

//echo("Done initializing JMX Core API");
