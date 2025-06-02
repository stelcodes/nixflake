{
  lib,
  buildGoModule,
  fetchFromGitHub,
  runCommand,
  coreutils,
  gnugrep,
  gawk,
}:

buildGoModule rec {
  pname = "ferret-cli";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "MontFerret";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-8DcTqhK0f7YJS69hYsQoX/2+KBAtSC8uLm4XcQgj2l0=";
  };

  vendorHash = "sha256-pt7WBypN2Es22yCqBTUOdEdoPUTR14xcsQ1eDZHFszk=";

  ldflags =
    let
      ferretVersion = lib.readFile (
        runCommand "foo" { } ''
          ${coreutils}/bin/cat ${src}/go.mod \
          | ${gnugrep}/bin/grep 'github.com/MontFerret/ferret v' \
          | ${gawk}/bin/awk -F 'v' '{print $2}' > $out
        ''
      );
    in
    [
      "-X main.version=v${version}"
      "-X github.com/MontFerret/cli/runtime.version=v${ferretVersion}"
    ];

  meta = with lib; {
    description = "Official CLI tool for the Ferret declarative web scraping project";
    homepage = "https://github.com/MontFerret/cli";
    license = licenses.asl20;
    maintainers = with maintainers; [ stelcodes ];
  };
}
