function blank() { printf "\n"; }
function bold() { printf "\033[1m%s\033[0m\n" "$1"; }
function error() { printf "\e[0;31mERROR: %s\e[0m\n" "$1"; read -r; exit 1; }
function success() { printf "\e[0;32m%s\e[0m\n" "$1"; read -r; exit 0; }
function warn() { printf "\e[0;33m%s\e[0m\n" "$1"; }

input="$1"
input_ext="${input##*.}"
bold "Starting audio conversion!"
blank
bold "Input file: $input"
bold "Select output format:"
output_ext="$(printf 'flac\nmp3' | fzf --height 5 || error "Unrecognized output format")"
if [ "$input_ext" = "$output_ext" ]; then
  error "File is already $output_ext"
fi
output="${input%.*}.$output_ext"
if [ -e "$output" ]; then
  error "File already exists: $output"
fi
cmd="ffmpeg -loglevel error -stats -i '$input'"
if [ "$output_ext" = "mp3" ]; then
  cmd="$cmd -b:a 320k"
fi
cmd="$cmd '$output'"
warn "$cmd"
read -rp "Convert? [Y/n]: " response
if [ "$response" != "y" ] && [ "$response" != "Y" ] && [ "$response" != "" ]; then
  error "User aborted conversion"
fi
if eval "$cmd"; then
  success "Conversion succeeded"
else
  error "Conversion failed"
fi
