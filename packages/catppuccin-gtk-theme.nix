{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gnome-themes-extra,
  gtk-engine-murrine,
}:
stdenvNoCC.mkDerivation rec {
  pname = "catppuccin-gtk-theme";
  version = "unstable-2023-03-03";

  src = fetchFromGitHub {
    owner = "Fausto-Korpsvart";
    repo = "Catppuccin-GTK-Theme";
    rev = "b8cffe7583876e17cc4558f32d17a072fa04ea9f";
    hash = "sha256-wJnbXXWKX0mcqRYyE1Vs4CrgWXTwfk3kRC2IhKqQ0RI=";
  };

  propagatedUserEnvPkgs = [
    gtk-engine-murrine
  ];

  buildInputs = [
    gnome-themes-extra
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/themes
    mkdir -p $out/share/icons
    cp -a themes/* $out/share/themes
    cp -a icons/* $out/share/icons
    runHook postInstall
  '';
}
