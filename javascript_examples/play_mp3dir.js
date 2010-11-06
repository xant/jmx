// Create a new audiolayer.
// We will use this object to load and play mp3 files
audiofile = new AudioLayer();
// Create a new audio output to let the user 'hear' what he plays
output = new AudioOutput();

// get the output pin from the audiolayer
audioout = audiofile.outputPin('audio');
// and the input pin from the audio output
audioin = output.inputPin('audio');
// and finally connect them
audioin.connect(audioout);

// we also want to make the samples we play available
// to the board for further processing
exportedOut = output.outputPin('currentSample');
exportPin(exportedOut); // this will register an output pin in the script entity

basepath = '/Users/xant/Documents/Music/Studentessi/'; // XXX - change me
// ok, now we can iterate over mp3 files and play them in sequence
list = lsdir(basepath);
for (i = 0; i < list.length; i++) {
    if (list[i].indexOf('.mp3') >= 0 && !isdir(basepath+list[i])) {
        echo(list[i]);
        audiofile.open(basepath+list[i]);
        audiofile.repeat = false; // we don't want to play always the same file
        audiofile.start();
        while (1) {
            // if EOF is reached, the layer will be automatically deactivated
            if (!audiofile.active) 
                break; // so we can go ahead to play next file
            sleep(1);
        }
    }
}
echo ("No more files to play!");
// when the script will end, all resources (and entities) will be released
