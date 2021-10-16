# Package

version       = "0.1.4"
author        = "hamidb80"
description   = "a program to convert svg images to vuejs components"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]


# Dependencies
requires "nim >= 1.5.1"
requires "argparse"
requires "watch_for_files"


task release, "":
  exec "nim c -d:release -o=vuesvg.exe src/main.nim"

task test, "test functionalities":
  exec "nim r tests/tcompile.nim"
  exec "nim c -o=temp.exe  src/main.nim"
  exec "nim r tests/te2e.nim"