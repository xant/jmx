/**
 * @fileoverview
 * This file is loaded at any script-startup.
 * Anything imported from here will be available
 * in any global context being executed
 */

//echo("Initializing JMX Core API");

include("VideoOutput.js");
//echo("Registered class: VideoOutput");
include("VideoFilter.js");
//echo("Registered class: VideoFilter");
include("AudioOutput.js");
//echo("Registered class: AudioOutput");
include("AudioCapture.js");
//echo("Registered class: AudioCapture");
include("VideoCapture.js");
include("MovieFile.js");
include("AudioFile.js");

include("DOM.js"); // DOM related additions

include("jquery.js");
//echo("Done initializing JMX Core API");
