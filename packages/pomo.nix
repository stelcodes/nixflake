{
  stdenv,
  lib,
  fetchFromGitHub,
  makeWrapper,
  coreutils,
  libnotify,
}:

stdenv.mkDerivation {
  pname = "pomo-sh";
  version = "unstable-2023-01-26";

  src = fetchFromGitHub {
    owner = "stelcodes";
    repo = "pomo";
    rev = "00ff7861e91c095adf709861029e892344c66dbd";
    sha256 = "FqdePN+o0Txa3F4kHB/R+aUEfsez9YxPmymbLXxrbrg=";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 pomo.sh $out/bin/pomo

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/pomo --prefix PATH : ${
      lib.makeBinPath [
        coreutils
        libnotify
      ]
    }
  '';

  meta = {
    description = "A simple Pomodoro timer written in Bash";
    homepage = "https://github.com/stelcodes/pomo";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = [ ];
    mainProgram = "pomo";
  };
}
