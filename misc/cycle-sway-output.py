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
found_active = False
next_output = outputs[0]
for output in outputs:
    if found_active:
        next_output = output
        break
    found_active = output["focused"]
print(f"Switching to output: {next_output['name']}")
command = ["swaymsg", "focus", "output", next_output["name"]]
result = subprocess.run(command, capture_output=True, text=True)
if result.returncode != 0:
    fail(result.stderr)
