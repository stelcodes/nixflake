import argparse
import os
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(
        prog="video-with-subs", description="Combine video file with subtitle file."
    )
    parser.add_argument(
        "-v",
        "--video",
        required=True,
        type=str,
        dest="video_path",
        help="Video file path",
    )
    parser.add_argument(
        "-s",
        "--subs",
        type=str,
        dest="subs_path",
        help="Subtitle file path",
    )
    parser.add_argument(
        "-k",
        "--keep-subs",
        type=int,
        nargs="*",
        default=[],
        dest="subs_streams",
        help="Subtitle stream indices to keep",
    )
    parser.add_argument(
        "-f",
        "--offset",
        type=float,
        dest="subs_offset",
        default=0.0,
        help="Subtitle offset in seconds",
    )
    parser.add_argument(
        "-K",
        "--keep-audio",
        type=int,
        nargs="*",
        default=[0],
        dest="audio_streams",
        help="Audio stream indices to keep",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        dest="output_path",
        help="Output file path",
    )
    args = parser.parse_args()

    input_args = [
        "-i",
        args.video_path,
    ]
    if args.subs_path:
        if args.subs_offset:
            input_args.append("-itsoffset")
            input_args.append(str(args.subs_offset))
        input_args.append("-i")
        input_args.append(args.subs_path)

    map_args = [
        "-map",
        "0:v:0",
    ]
    for audio_stream in args.audio_streams:
        map_args.append("-map")
        map_args.append(f"0:a:{audio_stream}")
    # Put the subs file first so it becomes s:0 default if given
    if args.subs_path:
        map_args.append("-map")
        map_args.append("1:s:0")
    for subs_stream in args.subs_streams:
        map_args.append("-map")
        map_args.append(f"0:s:{subs_stream}")

    meta_args = [
        "-disposition:v:0",
        "default",
    ]
    audio_count = len(args.audio_streams)
    for audio_index in range(audio_count):
        meta_args.append(f"-disposition:a:{audio_index}")
        meta_args.append("default" if audio_index == 0 else "0")
    subs_count = len(args.subs_streams) + (1 if args.subs_path else 0)
    for subs_index in range(subs_count):
        meta_args.append(f"-disposition:s:{subs_index}")
        meta_args.append("default" if subs_index == 0 else "0")
        meta_args.append(f"-metadata:s:s:{subs_index}")
        meta_args.append("language=eng")
        meta_args.append(f"-metadata:s:s:{subs_index}")
        meta_args.append(f"title=English{'_Alt' if subs_index != 0 else ''}")

    output_path: str = (
        args.output_path or os.path.splitext(args.video_path)[0] + ".vws.mkv"
    )

    ffmpeg_cmd = (
        ["ffmpeg", "-hide_banner"]
        + input_args
        + map_args
        + meta_args
        + ["-c", "copy", output_path]
    )

    print("\n" + " ".join(ffmpeg_cmd) + "\n")
    response = input("Run? [Y/n]")
    if response.lower() != "n":
        ffmpeg_result = subprocess.run(ffmpeg_cmd)
        sys.exit(ffmpeg_result.returncode)


if __name__ == "__main__":
    main()
