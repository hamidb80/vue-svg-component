import 
  unittest, 
  osproc, strutils, os


test "e2e":
  let (output, exitCode) = execCmdEx("./temp.exe ./assets/ ./output/")
  check:
    exitCode == 0
    "cube.svg" in output
    "database.svg" in output

  for (_, fname) in walkdir "output":
    removeFile fname
