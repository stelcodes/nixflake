#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3

import subprocess
import json
import sys


def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


try:
    scale_delta_str = sys.argv[1]
    scale_delta = float(scale_delta_str)
    command = ["niri", "msg", "--json", "focused-output"]
    result = subprocess.run(command, capture_output=True, text=True, check=True)
    json_output = result.stdout
    data: dict = json.loads(json_output)
    output_name = data["name"]
    output_scale: float = data["logical"]["scale"]
    new_output_scale = output_scale + scale_delta
    command = ["niri", "msg", "output", output_name, "scale", f"{new_output_scale:.2f}"]
    result = subprocess.run(command, check=True)
except subprocess.CalledProcessError as e:
    print(e.stderr, file=sys.stderr)
    fail(f"Command '{e.cmd}' failed")
except json.JSONDecodeError as e:
    print(e.msg, file=sys.stderr)
    fail("JSON decoding issue")
except IndexError:
    fail("Missing scale delta argument (ex: 0.2, -1)")
except ValueError:
    fail("The argument cannot be converted to a float.")
