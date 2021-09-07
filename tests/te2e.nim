import 
  unittest, os, osproc,
  sequtils, strutils, sugar

suite "e2e":
  let svgs = collect newseq:
    for (_, fname) in walkdir "output":
      let sn = fname.splitFile
      sn.name & sn.ext


  test "compile all files in the folder":
    let (output, exitCode) = execCmdEx "./temp.exe ./assets/ ./output/"
    check:
      exitCode == 0
      svgs.allIt it in output


  for (_, fname) in walkdir "output":
    removeFile fname