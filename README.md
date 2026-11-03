# ComparisonGen-Mod

An AviSynth+ function for generating frame comparison images from multiple video sources.

## Features

- Compare multiple video sources simultaneously.
- Support independently aligned starting frames for each source without using Trim() to cut the video clips.
- Select frames based on frame types (I, P, B, PB, IPB).
- Use a shared relative offset across all sources.
- Set a minimum interval between consecutive selected frames.
- Export comparison frames directly as PNG images.
- Preserve the original source frame numbers displayed by LWLinfo() in the exported comparison images.
- Support multiple output filename formats.
- Preserve source overlays and labels.

## Requirements

**Required**
- AviSynth+ (r3573 or later)
- avsresize
- RT_Stats

**Recommended**
- AvsPmod (for editing and testing AviSynth scripts)

## Installation

1. Download ComparisonGen_Mod.avsi.
2. Place it in your preferred AviSynth script directory.
3. Import the script into your .avs file:

Import("ComparisonGen_Mod.avsi")

## Usage

See [ComparisonGen_Example.avs](Examples/ComparisonGen_Example.avs) for a usage example.

## Credits

This project is based on ComparisonGen 1.0.6, with additional modifications and features.

## License

No license specified.
