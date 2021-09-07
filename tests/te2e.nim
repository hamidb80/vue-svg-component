import 
  unittest, 
  osproc, strutils, os

#FIXME find paths dynamicly
#TODO add test for config file
test "e2e":
  let (output, exitCode) = execCmdEx("./temp.exe ./assets/ ./output/")
  check:
    exitCode == 0
    "chart.svg" in output
    "database.svg" in output

  for (_, fname) in walkdir "output":
    removeFile fname
