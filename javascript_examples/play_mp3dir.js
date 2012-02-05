// Create a new audiofile reader.
// We will use this object to load and play mp3 files
audiofile = new AudioFile();
// Create a new audio output to let the user 'hear' what he plays
output = new AudioOutput();

// get the output pin from the audio file
audioout = audiofile.outputPin('audio');
// and the input pin from the audio output
audioin = output.inputPin('audio');
// and finally connect them
audioin.connect(audioout);

// we also want to make the samples we play available
// to the board for further processing
exportedOut = output.outputPin('currentSample');
//exportPin(exportedOut); // this will register an output pin in the script entity
exportedOut.export();

basepath = '/Users/xant/Documents/Music/Studentessi/'; // XXX - change me
// ok, now we can iterate over mp3 files and play them in sequence
list = lsdir(basepath);
i = 0;
run(function() {
    if (list[i].indexOf('.mp3') >= 0 && !isdir(basepath+list[i])) {
        echo(list[i]);
        audiofile.open(basepath+list[i]);
        audiofile.repeat = false; // we don't want to play always the same file
    }
    while (audiofile.active)
        sleep(0.25);
    if (++i >= list.length)
        quit();
});
echo ("No more files to play!");
// when the script will end, all resources (and entities) will be released
