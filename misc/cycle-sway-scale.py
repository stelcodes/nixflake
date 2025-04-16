#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3

import subprocess
import json
import sys


def fail(msg):
    print(f"An error occurred while running the command: {msg}")
    sys.exit(1)


# Run the command and capture the output
command = ["swaymsg", "-t", "get_outputs"]
result = subprocess.run(command, capture_output=True, text=True)
if result.returncode != 0:
    fail(result.stderr)
# Parse the JSON output
json_output = result.stdout
data: list[dict] = json.loads(json_output)
# Sort the list of dictionaries by the "id" key
outputs = sorted(data, key=lambda x: x["id"])
if not outputs:
    fail("Not outputs found")
focused_output = outputs[0]
for output in outputs:
    if output["focused"]:
        focused_output = output
        break
old_scale = focused_output["scale"]
new_scale = (round(old_scale * 100) + 15) / 100
if new_scale > 2.2:
    new_scale = 1
print(f"Scaling output {focused_output['name']} from {old_scale} to {new_scale}")
command = ["swaymsg", "output", "-", "scale", str(new_scale)]
result = subprocess.run(command, capture_output=True, text=True)
if result.returncode != 0:
    fail(result.stderr)
