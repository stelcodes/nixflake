{ writePythonApplication, ffmpeg }:
writePythonApplication {
  name = "video-with-subs";
  runtimeInputs = [ ffmpeg ];
  text = builtins.readFile ./video-with-subs.py;
}
