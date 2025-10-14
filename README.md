# ffslice

[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/jchook/ffslice/releases)
[![Tests](https://img.shields.io/badge/tests-passing-brightgreen.svg)](test.sh)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A fast, lightweight command-line utility for extracting segments from audio and video files without re-encoding. Built on `ffmpeg`, ffslice provides an intuitive interface for precise media slicing with support for absolute and relative timestamps.

<img src="https://raw.githubusercontent.com/jchook/ffslice/main/assets/ffslice.jpg" width="480" />

## Features

- **Zero re-encoding** - Extract segments instantly using stream copy
- **Flexible time formats** - Support for `HH:MM:SS`, `MM:SS`, or seconds
- **Relative timestamps** - Specify times relative to start or end of file
- **Batch processing** - Forward additional ffmpeg arguments for advanced workflows
- **Directory output** - Auto-generate filenames when specifying output directories

## Usage

```sh
ffslice infile start [end] [outfile] [ffmpeg-args...]
```

### Time Formats

Times can be specified as:
- Seconds: `30`
- Minutes:seconds: `1:30`
- Hours:minutes:seconds: `1:30:45`

### Relative Times

Use `+` or `-` prefixes for relative positioning:
- `+30` - 30 seconds after the start time
- `-30` - 30 seconds before the end of the file

### Examples

**Extract the last 30 seconds:**
```sh
ffslice video.mp4 -30
```

**Extract 42 seconds starting at 1m 50s:**
```sh
ffslice audio.wav 1:50 +42
```

**Extract from 9m 50s to 1h 55m 32s:**
```sh
ffslice recording.mp4 9:50 1:55:32
```

**Specify output file and additional ffmpeg options:**
```sh
ffslice input.mp4 5:00 10:00 output.mp4 -preset ultrafast
```

**Auto-generate filename in a directory:**
```sh
ffslice podcast.mp3 15:30 20:45 ~/clips/
# Creates: ~/clips/podcast-15.30-20.45.mp3
```

## Use Cases

**Content Production:**
- Extract highlights from long-form video content
- Create social media clips from webinars or presentations
- Isolate specific segments for editing workflows

**Audio Processing:**
- Extract individual tracks from live recordings
- Create preview clips from podcasts or audiobooks
- Isolate specific segments for transcription

**Quality Assurance:**
- Extract problematic segments for bug reports
- Create reference clips for A/B testing
- Isolate artifacts for analysis

**Archival & Organization:**
- Split large files into manageable segments
- Extract key moments from recordings
- Create highlights from meetings or lectures

## Installation

### Prerequisites

- `bash` 4.0 or later
- `ffmpeg`

### Install

```sh
# Clone the repository
git clone https://github.com/jchook/ffslice.git
cd ffslice

# Copy to PATH
sudo cp ffslice /usr/local/bin/ffslice
```

Or copy `ffslice` to any directory in your `$PATH`.

## Testing

The project includes a comprehensive test suite:

```sh
./test.sh                 # Run all tests
./test.sh "timetosec"     # Run specific test group
```

## How It Works

ffslice uses `ffmpeg -c copy` to extract segments without re-encoding, which:
- Preserves original quality
- Executes nearly instantaneously
- Avoids generation loss
- Maintains original codec and container format

**Note:** Filenames with colons are automatically converted to dots for compatibility with ffmpeg's protocol detection.

## Dry-Run Mode

Preview the ffmpeg command without execution:

```sh
FFSLICE_DRY_RUN=1 ffslice video.mp4 1:00 2:00
# Outputs: ffmpeg -ss 60 -i video.mp4 -t 60 -c copy video-1.00-2.00.mp4
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
