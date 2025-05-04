# Requires single argument, one of: "left" "right" "up" "down"
# Test within kitten shell: kitten resize_window.py left
from typing import Dict, List, Tuple
from kittens.tui.handler import kitten_ui


def resize_cmd(axis: str, increment: str, neighbor: str) -> List:
    # https://sw.kovidgoyal.net/kitty/remote-control/#kitten-resize-window
    return [
        "resize-window",
        "--axis=" + axis,
        "--increment=" + increment,
        "--match=neighbor:" + neighbor,
    ]


direction_to_args: Dict[str, Tuple[List[str], List[str]]] = {
    "left": (
        resize_cmd("horizontal", "1", "right"),
        resize_cmd("horizontal", "-1", "left"),
    ),
    "right": (
        resize_cmd("horizontal", "-1", "right"),
        resize_cmd("horizontal", "1", "left"),
    ),
    "up": (resize_cmd("vertical", "-1", "top"), resize_cmd("vertical", "1", "bottom")),
    "down": (
        resize_cmd("vertical", "1", "top"),
        resize_cmd("vertical", "-1", "bottom"),
    ),
}


@kitten_ui(allow_remote_control=True)
def main(args: List[str]) -> str:
    direction = args[1]
    first_cmd = direction_to_args[direction][0]
    second_cmd = direction_to_args[direction][1]
    result = main.remote_control(first_cmd)
    if result.returncode != 0:
        main.remote_control(second_cmd)
    return ""
