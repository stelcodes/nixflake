{ pkgs, ... }:
{
  home.file."pictures/wallpaper/2f20c35a7e430a9edcbece0f9c24f280.jpg".source = pkgs.fetchurl {
    url = "https://i.imgur.com/jo5NfMD.jpeg";
    hash = "sha256-iO7ZO5wM4bx13uOtGOWEIjN89bi+jiSe0zNWbKHGTyY=";
  };
  home.stateVersion = "25.05";
}
