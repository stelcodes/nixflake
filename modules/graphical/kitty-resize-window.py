# Requires single argument, one of: "left" "right" "up" "down"
# Test within kitten shell: kitten resize_window.py left
import sys
from subprocess import DEVNULL
from typing import List
from kittens.tui.handler import kitten_ui


@kitten_ui(allow_remote_control=True, remote_control_password=True)
def main(args: List[str]) -> str:
    direction = args[1] if len(args) > 1 else None
    if direction not in ["left", "right", "up", "down"]:
        raise Exception("Requires single argument: left, right, up, or down")
    direction_to_neighbor = {
        "left": "left",
        "right": "right",
        "up": "top",
        "down": "bottom",
    }
    direction_to_axis = {
        "left": "horizontal",
        "right": "horizontal",
        "up": "vertical",
        "down": "vertical",
    }
    neighbor = direction_to_neighbor[direction]
    axis = direction_to_axis[direction]
    # https://sw.kovidgoyal.net/kitty/remote-control/#kitten-ls
    ls_cmd = ["ls", "--match=neighbor:" + neighbor]
    ls_result = main.remote_control(ls_cmd, capture_output=True)
    increment = "-1" if ls_result.stdout.strip() == b"" else "1"
    # https://sw.kovidgoyal.net/kitty/remote-control/#kitten-resize-window
    resize_cmd = ["resize-window", "--axis=" + axis, "--increment=" + increment]
    main.remote_control(resize_cmd, stderr=DEVNULL)
    return ""
