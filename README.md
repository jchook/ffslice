# ffslice

Extract segments of audio and video files, without re-encoding.

Basically like `substr()` for MPEG-encoded files.

<img src="https://raw.githubusercontent.com/jchook/ffslice/main/assets/ffslice.png" width="480" />


## Usage

```sh
ffslice file.mp4 start [end]
```

You can specify relative start/end points with a leading plus (+) or  minus (-).
For example:

+ `fflsice file.mp4  -30` means "begin at 0:00 and end at 30 seconds from the end of the file"
+ `ffslice file.mp4  1:50 +42` means "begin at 1m 50s, then end 42 seconds after that"
+ `ffslice file.mp4  9:50 1:55:32` means "start at 9m 50s, then end at 1h 55m and 32s"

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
