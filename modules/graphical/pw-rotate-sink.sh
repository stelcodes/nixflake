function with_timeout {
  cmd="$1" # command or function
  timeout="$2" # integer
  (
    eval "$cmd" &
    child=$!
    trap -- "" SIGTERM
    (
      sleep "$timeout"
      kill "$child" 2> /dev/null
    ) &
    wait "$child"
  )
}

function rotate {
  SINKS="$(pw-dump Node)"
  mapfile -t SINK_IDS < <(echo "$SINKS" | jq '.[] | select(.info.props."media.class" == "Audio/Sink") | .id')
  SINK_COUNT=${#SINK_IDS[@]}

  DEFAULT_SINK_NAME="$(pw-dump Metadata | jq -r '.[] | select(.props."metadata.name" == "default")| .metadata[] | select(.key == "default.configured.audio.sink") | .value.name')"
  DEFAULT_SINK_ID=$(echo "$SINKS" | jq -r ".[] | select(.info.props.\"node.name\" | contains(\"$DEFAULT_SINK_NAME\")) | .id")

  printf "SINKS: %s\nSINK COUNT: %s/nDEFAULT_SINK_NAME:%s\nDEFAULT_SINK_ID: %s\n" \
    "${SINK_IDS[@]}" "$SINK_COUNT" "$DEFAULT_SINK_NAME" "$DEFAULT_SINK_ID"

  for i in "${!SINK_IDS[@]}"; do
    if [[ "${SINK_IDS[i]}" = "${DEFAULT_SINK_ID}" ]]; then
      echo "DEFAULT_SINK_INDEX: $i"
      NEXT_SINK_INDEX=$(((i + 1) % SINK_COUNT))
      echo "NEXT_SINK_INDEX: $NEXT_SINK_INDEX"
      NEXT_SINK_ID="${SINK_IDS[$NEXT_SINK_INDEX]}"
      echo "NEXT_SINK_ID: $NEXT_SINK_ID"
      # Setting default in wireplumber also triggers (most?) applications to use the new default instead.
      wpctl set-default "${NEXT_SINK_ID}"
      break
    fi
  done
}

# pw-dump or wpctl hangs all the time so kill attempt after 3 seconds
with_timeout rotate 3
