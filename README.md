# ffslice

Extract segments of audio and video files, without re-encoding.

Basically like `substr()` for MPEG-encoded files.


## Usage

```sh
ffslice file.mp4 start [end]
```

You can specify relative start/end points with a leading + or -. For example:

+ `-30` means "start 30 seconds from the end of the video"
+ `1:50 +42` means "start at 1m 50s, then end 42 seconds after that"

## Requirements

This script is written in pure `bash` and it requires `ffmpeg`.

## Example Use Cases

- You have a long live show recording and want to extract one song to send to a friend
- You want to extract a funny scene from your favorite show

## Known Bugs

I use this script frequently to extract segments from MixCloud mixes and YouTube
videos. However, I am certain there are a few edge-case bugs with the start/end
time logic. Feel free to fix it!

## License

MIT.
