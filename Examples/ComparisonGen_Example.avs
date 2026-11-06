# Import the AVSI script
Import("I:\Software\Tools\ComparisonGen_Mod\ComparisonGen_Mod.avsi")

# Load video sources for comparison
a = LWLibavVideoSource("I:\Test\Test1.mkv")
a = a.LWLinfo(textcolor=$B0C4DE).subtitle("Blu-ray", align=7, y=35, text_color=$B0C4DE)

b = LWLibavVideoSource("I:\Test\Test2.mkv")
b = b.LWLinfo(textcolor=$B0C4DE).subtitle("WEB-DL", align=7, y=35, text_color=$B0C4DE)

c = LWLibavVideoSource("I:\Test\Test3.mkv")
c = c.LWLinfo(textcolor=$B0C4DE).subtitle("HDDVD", align=7, y=35, text_color=$B0C4DE)

# Generate comparison images
ComparisonGen([a, b, c], start_frames=[20, 0, 155], image_file=["BD", "WEB", "HDDVD"], frame_type=["B", "B", "B"], n=7, min_frame_interval=500, check_type=true, filename_format=1, output_dir="I:\Test\Comparison_Output")

# [a, b, c] - Video sources to be compared (e.g. [a, b, c])
# start_frames - Starting frame number for each source (e.g. [0, 100, 250])
# image_file - Filename labels for each source (e.g. ["Source A", "Source B", "Source C"])
# frame_type - Required frame type for each source (e.g. ["I", "P", "B", "PB", "IPB"])
# n - Number of comparison sets to generate (e.g. 10)
# min_frame_interval - Minimum interval between consecutive selected frames (e.g. 5000)
# filename_format - Output filename format (1: 0034.Source.png, 2: Source.0034.png, 3: Source0034.png)
# output_dir - Destination folder for the exported PNG images (e.g. "I:\Comparison_Output")
