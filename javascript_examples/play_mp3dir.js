audiofile = new AudioLayer();
output = new AudioOutput();
audioout = audiofile.outputPin('audio');
audioin = output.inputPin('audio');
exportedOut = output.outputPin('currentSample');
exportPin(exportedOut); // export the played audio
audioin.connect(audioout); // connect them
basepath = '/Users/xant/Documents/Music/Studentessi/';
list = lsdir(basepath);
for (i = 0; i < list.length; i++) {
    if (list[i].indexOf('.mp3') >= 0 && !isdir(basepath+list[i])) {
        echo(list[i]);
        audiofile.open(basepath+list[i]);
        audiofile.repeat = 0;
        audiofile.start();
        while (1) {
            if (!audiofile.active)
                break;
            sleep(1);
        }
    }
}
echo ("No more files to play!");
