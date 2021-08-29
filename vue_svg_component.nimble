# Package

version       = "0.0.5"
author        = "hamidb80"
description   = "a program to convert svg images to vuejs components"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]


# Dependencies

requires "nim >= 1.5.1"
requires "argparse"
requires "https://github.com/hamidb80/watch_for_files"

