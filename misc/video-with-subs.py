import argparse
import os
from pprint import pprint
from subprocess import run
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
        dest="subs_stream",
        help="Subtitle stream index to keep",
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
        "-o",
        "--output",
        type=str,
        dest="output_path",
        help="Output file path",
    )
    args = parser.parse_args()

    ffmpeg_cmd_raw = [
        "ffmpeg",
        "-hide_banner",
        "-i",
        args.video_path,
        args.subs_offset and "-itsoffset",
        args.subs_offset and str(args.subs_offset),
        args.subs_path and "-i",
        args.subs_path,
        "-map",
        "0:v:0",
        "-map",
        "0:a:0",
        args.subs_path and "-map",
        args.subs_path and "1:s:0",
        args.subs_stream is not None and "-map",
        args.subs_stream is not None and f"0:s:{args.subs_stream}",
        "-disposition:v:0",
        "default",
        "-disposition:a:0",
        "default",
        "-disposition:s:0",
        "default",
        "-metadata:s:s:0",
        "language=eng",
        "-metadata:s:s:0",
        "title=English",
        args.subs_path and args.subs_stream is not None and "-disposition:s:1",
        args.subs_path and args.subs_stream is not None and "0",
        args.subs_path and args.subs_stream is not None and "-metadata:s:s:1",
        args.subs_path and args.subs_stream is not None and "language=eng",
        args.subs_path and args.subs_stream is not None and "-metadata:s:s:1",
        args.subs_path and args.subs_stream is not None and "title=English_Alt",
        "-c",
        "copy",
        args.output_path or os.path.splitext(args.video_path)[0] + ".vws.mkv",
    ]
    ffmpeg_cmd = [x for x in ffmpeg_cmd_raw if isinstance(x, str)]
    pprint(ffmpeg_cmd)
    response = input("Run? [Y/n]")
    if response.lower() != "n":
        ffmpeg_result = run(ffmpeg_cmd)
        sys.exit(ffmpeg_result.returncode)


if __name__ == "__main__":
    main()
