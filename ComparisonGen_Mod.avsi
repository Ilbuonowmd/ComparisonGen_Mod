
# ============================================================
# ComparisonGen_Mod.avsi
#
# Requirements:
# AviSynth+ >= r3573
# avsresize
# RT_Stats
#
# Features:
# - Independent start frame for each source
# - Shared relative offset between sources
# - Minimum interval between selected offsets
# - Direct PNG export using ImageWriter
# - Original frame numbers in filenames
# - 3 filename formats
# - Preserves LWLinfo() overlay in source clips
# - Reads _PictType from a single-frame clip
# ============================================================


Function ComparisonGen(clip_array c, string_array "image_file", val_array "frame_type", string "pframes_file", int "n", float "offset_coef", string "matrix", string "pixel_type", bool "check_type", val_array "start_frames", int "min_frame_interval", int "filename_format", string "output_dir")
{
    # --------------------------------------------------------
    # BASIC VALIDATION
    # --------------------------------------------------------

    c_size = ArraySize(c)
    c_last = c_size - 1

    Assert(c_size >= 1, "ComparisonGen: at least one clip is required.")

    # --------------------------------------------------------
    # START FRAMES
    # --------------------------------------------------------

    if (Defined(start_frames))
    {
        Assert(ArraySize(start_frames) == c_size, "ComparisonGen: start_frames must match clip count.")
        _starts = start_frames
    }
    else
    {
        _starts = []

        for (i = 0, c_last)
        {
            _starts = ArrayAdd(_starts, 0)
        }
    }

    for (i = 0, c_last)
    {
        Assert(IsInt(_starts[i]) && _starts[i] >= 0 && _starts[i] < FrameCount(c[i]), "ComparisonGen: invalid start_frames value.")
    }

    # --------------------------------------------------------
    # IMAGE NAMES
    # --------------------------------------------------------

    if (Defined(image_file))
    {
        Assert(ArraySize(image_file) == c_size, "ComparisonGen: image_file count must match clips.")
        _names = image_file
    }
    else
    {
        _names = []

        for (i = 0, c_last)
        {
            _names = ArrayAdd(_names, "Source_" + String(i + 1))
        }
    }

    # --------------------------------------------------------
    # FRAME TYPES
    #
    # 1 = I
    # 2 = P
    # 3 = B
    # 4 = PB
    # 5 = IPB
    #
    # Also accepts:
    # "I", "P", "B", "PB", "IPB"
    # --------------------------------------------------------

    if (Defined(frame_type))
    {
        Assert(ArraySize(frame_type) == c_size, "ComparisonGen: frame_type count must match clips.")

        _types = []

        for (i = 0, c_last)
        {
            Assert((IsInt(frame_type[i]) && frame_type[i] >= 1 && frame_type[i] <= 5) || (IsString(frame_type[i]) && (frame_type[i] == "I" || frame_type[i] == "P" || frame_type[i] == "B" || frame_type[i] == "PB" || frame_type[i] == "IPB")), "ComparisonGen: invalid frame_type.")

            if (IsInt(frame_type[i]))
            {
                _types = ArrayAdd(_types, Select(frame_type[i], "", "I", "P", "B", "PB", "IPB"))
            }
            else
            {
                _types = ArrayAdd(_types, frame_type[i])
            }
        }
    }
    else
    {
        _types = ["PB"]

        for (i = 1, c_last)
        {
            _types = ArrayAdd(_types, "B")
        }
    }

    # --------------------------------------------------------
    # CONFIGURATION
    # --------------------------------------------------------

    _matrix = Default(matrix, "709=>rgb")
    _pixel_type = Default(pixel_type, "RGBP")
    _check = Default(check_type, true)
    _n = Default(n, 10)
    _offset_coef = Default(offset_coef, 0.05)
    _interval = Default(min_frame_interval, 1000)
    _format = Default(filename_format, 1)
    _outdir = Default(output_dir, "")

    Assert(_n >= 1, "ComparisonGen: n must be >= 1.")
    Assert(_offset_coef >= 0.0 && _offset_coef < 1.0, "ComparisonGen: offset_coef must be >= 0 and < 1.")
    Assert(_interval >= 1, "ComparisonGen: min_frame_interval must be >= 1.")
    Assert(_format >= 1 && _format <= 3, "ComparisonGen: filename_format must be 1, 2 or 3.")
    Assert(_outdir != "", "ComparisonGen: output_dir must be specified.")

    # --------------------------------------------------------
    # CHECK PIXEL TYPES
    # --------------------------------------------------------

    for (i = 1, c_last)
    {
        Assert(PixelType(c[0]) == PixelType(c[i]), "ComparisonGen: clips must have same pixel type.")
    }

    # --------------------------------------------------------
    # AVAILABLE COMMON OFFSET
    # --------------------------------------------------------

    _max_offset = 2147483647

    for (i = 0, c_last)
    {
        _available = FrameCount(c[i]) - _starts[i] - 1
        _max_offset = Min(_max_offset, _available)
    }

    Assert(_max_offset >= 0, "ComparisonGen: no common frame range available.")

    # --------------------------------------------------------
    # SELECT OFFSETS
    # --------------------------------------------------------

    _offsets = []

    if (Defined(pframes_file))
    {
        Assert(Exist(pframes_file), "ComparisonGen: pframes_file not found.")

        _line_count = RT_FileQueryLines(pframes_file)

        Assert(_line_count > 0, "ComparisonGen: pframes_file is empty.")

        for (i = 0, _line_count - 1)
        {
            _offset = Int(Value(RT_ReadTxtFromFile(pframes_file, 1, i)))

            Assert(_offset >= 0 && _offset <= _max_offset, "ComparisonGen: invalid offset in pframes_file.")

            if (i > 0)
            {
                _previous = _offsets[i - 1]
                Assert(_offset >= _previous + _interval, "ComparisonGen: offsets in pframes_file do not satisfy min_frame_interval.")
            }

            _offsets = ArrayAdd(_offsets, _offset)
        }
    }
    else
    {
        _offset = Int(_max_offset * _offset_coef)

        for (k = 0, _n - 1)
        {
            _found = false

            while (!_found && _offset <= _max_offset)
            {
                _match = true

                if (_check)
                {
                    for (j = 0, c_last)
                    {
                        _frame = _starts[j] + _offset

                        # Read _PictType from the requested frame.
                        _actual_type = _ComparisonGen_GetPictType(c[j], _frame)

                        _ok = false

                        if (_types[j] == "IPB" || (_types[j] == "I" && _actual_type == "I") || (_types[j] == "P" && _actual_type == "P") || (_types[j] == "B" && _actual_type == "B") || (_types[j] == "PB" && (_actual_type == "P" || _actual_type == "B")))
                        {
                            _ok = true
                        }

                        if (!_ok)
                        {
                            _match = false
                        }
                    }
                }

                if (_match)
                {
                    _offsets = ArrayAdd(_offsets, _offset)
                    _found = true
                }
                else
                {
                    _offset = _offset + 1
                }
            }

            Assert(_found, "ComparisonGen: no more matching frames found.")

            # Next search starts at least this many frames later.
            _offset = _offset + _interval
        }
    }

    # --------------------------------------------------------
    # EXPORT PNG
    # --------------------------------------------------------

    for (k = 0, ArraySize(_offsets) - 1)
    {
        _offset = _offsets[k]

        # Validate manually supplied offsets.
        if (_check && Defined(pframes_file))
        {
            _match = true

            for (j = 0, c_last)
            {
                _frame = _starts[j] + _offset

                # Read _PictType from the requested frame.
                _actual_type = _ComparisonGen_GetPictType(c[j], _frame)

                _ok = false

                if (_types[j] == "IPB" || (_types[j] == "I" && _actual_type == "I") || (_types[j] == "P" && _actual_type == "P") || (_types[j] == "B" && _actual_type == "B") || (_types[j] == "PB" && (_actual_type == "P" || _actual_type == "B")))
                {
                    _ok = true
                }

                if (!_ok)
                {
                    _match = false
                }
            }

            Assert(_match, "ComparisonGen: frame type mismatch in pframes_file.")
        }

        for (i = 0, c_last)
        {
            _actual_frame = _starts[i] + _offset

            # Filename formats:
            #
            # 1: 0034.A.Source.png
            # 2: A.Source.0034.png
            # 3: A.Source0034.png

            if (_format == 1)
            {
                _pattern = _outdir + "\\" + "%03d." + _names[i] + ".png"
            }
            else if (_format == 2)
            {
                _pattern = _outdir + "\\" + _names[i] + ".%03d.png"
            }
            else
            {
                _pattern = _outdir + "\\" + _names[i] + "%03d.png"
            }

            # Convert the ORIGINAL source.
            # Do not use Trim() or FrameSel() for export.

            if (IsRGB(c[i]))
            {
                _save = z_ConvertFormat(c[i], pixel_type=_pixel_type, dither_type="error_diffusion")
            }
            else
            {
                _save = z_ConvertFormat(c[i], pixel_type=_pixel_type, colorspace_op=_matrix, resample_filter_uv="spline36", dither_type="error_diffusion")
            }

            # Export using the original source frame number.
            _ComparisonGen_Save(_save, _pattern, _actual_frame)
        }
    }

    Return MessageClip("ComparisonGen: Done. " + String(ArraySize(_offsets)) + " comparison sets.")
}


# ============================================================
# READ PICTURE TYPE FROM A SINGLE FRAME
# ============================================================

Function _ComparisonGen_GetPictType(clip c, int frame_number)
{
    # Make the requested source frame frame 0 of a new clip.
    _single_frame = Trim(c, frame_number, frame_number)

    # Read the frame property from frame 0.
    return propGetString(_single_frame, "_PictType")
}


# ============================================================
# SAVE ONE FRAME
# ============================================================

Function _ComparisonGen_Save(clip c, string filename, int frame_number)
{
    c

    ImageWriter(filename, start=frame_number, end=frame_number, type="png")

    # Force evaluation.
    RT_AverageLuma(ConvertToY(), n=frame_number, w=1, h=1)
}
