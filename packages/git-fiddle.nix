{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  installShellFiles,
  coreutils,
  gawk,
  git,
}:
stdenvNoCC.mkDerivation {

  pname = "git-fiddle";
  version = "unstable-2017-02-03";

  dontConfigure = true;
  dontBuild = true;

  src = fetchFromGitHub {
    owner = "felixSchl";
    repo = "git-fiddle";
    rev = "606086df3bf63b61ae35f195167a798c0a1823f4";
    hash = "sha256-rIx2SjtiRMfKseegdH7NjAATBNFOyqPp+cbmDjMrwxE=";
  };

  nativeBuildInputs = [
    makeWrapper
    installShellFiles
  ];

  # TODO: Patch script to avoid installing _fiddle_seq_editor to $out/bin
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 git-fiddle $out/bin/git-fiddle
    install -Dm755 _fiddle_seq_editor $out/bin/_fiddle_seq_editor
    installManPage man1/git-fiddle.1

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/git-fiddle --prefix PATH : ${
      lib.makeBinPath [
        coreutils
        gawk
        git
      ]
    }
  '';

  meta = {
    description = "Edit commit messages, authors, and timestamps during git-rebase";
    homepage = "https://github.com/felixSchl/git-fiddle";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = [ ];
    mainProgram = "git-fiddle";
  };
}
