{ lib
, stdenv
, pam
, jansson
, fetchFromGitHub
}:

# https://github.com/furiLabs/pam-parallel
# https://github.com/ChocolateLoverRaj/pam-any/issues/12

stdenv.mkDerivation rec {
  pname = "pam-parallel";
  version = "unstable-2025-04-04";

  src = fetchFromGitHub {
    owner = "FuriLabs";
    repo = "pam-parallel";
    rev = "dd3e86cd7c6caddc44c505013cc2446b307b83fd";
    hash = "sha256-fnxmRF4h73HglngfshTUgvTxjurYw8rO+DOxkToUxNk=";
  };

  buildInputs = [ jansson pam ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    make all

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/security
    install -m 0644 pam_parallel.so $out/lib/security

    runHook postInstall
  '';

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/FuriLabs/pam-parallel";
    description = "PAM module that runs multiple other PAM modules in parallel, succeeding as long as one of them succeeds";
    platforms = platforms.linux;
  };
}
