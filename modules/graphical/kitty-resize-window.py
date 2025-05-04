# Requires single argument, one of: "left" "right" "up" "down"
# Test within kitten shell: kitten resize_window.py left
from typing import Dict, List, NamedTuple, Tuple
from kittens.tui.handler import kitten_ui

ResizeParams = NamedTuple(
    "ResizeCmd", [("axis", str), ("increment", str), ("neighbor", str)]
)


def ls_cmd(r: ResizeParams) -> List[str]:
    # https://sw.kovidgoyal.net/kitty/remote-control/#kitten-ls
    return [
        "ls",
        "--match=neighbor:" + r.neighbor,
    ]


def resize_cmd(r: ResizeParams) -> List[str]:
    # https://sw.kovidgoyal.net/kitty/remote-control/#kitten-resize-window
    return [
        "resize-window",
        "--axis=" + r.axis,
        "--increment=" + r.increment,
        "--match=neighbor:" + r.neighbor,
    ]


directions: Dict[str, Tuple[ResizeParams, ResizeParams]] = {
    "left": (
        ResizeParams("horizontal", "1", "right"),
        ResizeParams("horizontal", "-1", "left"),
    ),
    "right": (
        ResizeParams("horizontal", "-1", "right"),
        ResizeParams("horizontal", "1", "left"),
    ),
    "up": (
        ResizeParams("vertical", "-1", "top"),
        ResizeParams("vertical", "1", "bottom"),
    ),
    "down": (
        ResizeParams("vertical", "1", "top"),
        ResizeParams("vertical", "-1", "bottom"),
    ),
}


@kitten_ui(allow_remote_control=True)
def main(args: List[str]) -> str:
    direction = args[1]
    # Try first set of resize params
    params = directions[direction][0]
    # To avoid annoying error message flash, check if neighbor exists first
    ls_result = main.remote_control(ls_cmd(params), capture_output=True, text=True)
    if ls_result.stdout.strip() != "":
        main.remote_control(resize_cmd(params))
        return ""
    # If the first set of resize params were invalid, try the next
    params = directions[direction][1]
    ls_result = main.remote_control(ls_cmd(params), capture_output=True, text=True)
    if ls_result.stdout.strip() != "":
        main.remote_control(resize_cmd(params))
        return ""
