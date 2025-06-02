{
  writeTextFile,
  babashka-unwrapped,
  lib,
  runtimeShell,
}:
{
  name,
  text,
  runtimeInputs ? [ ],
  checkPhase ? null,
}:
let
  sourceFile = writeTextFile { inherit name text; };
in
writeTextFile {
  name = ".${name}-wrapped";
  executable = true;
  destination = "/bin/${name}";
  text =
    ''
      #!${runtimeShell}
      set -o errexit
      set -o nounset
      set -o pipefail
    ''
    + lib.optionalString (runtimeInputs != [ ]) ''

      export PATH="${lib.makeBinPath runtimeInputs}:$PATH"
    ''
    + ''

      ${babashka-unwrapped}/bin/bb ${sourceFile} "$@"
    '';
}
