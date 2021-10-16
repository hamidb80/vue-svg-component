import unittest, os, macros, macroutils, sugar
import main

macro testgen=
  let svgs = collect newseq:
    for (_, fname) in walkdir "./assets":
      let sn = fname.splitFile
      [sn.dir,sn.name & sn.ext]

  result = newStmtList()

  for svg in svgs:
    result.add superquote do:

      test `svg[1]`:
        const 
          svgpath = `svg[0]` / `svg[1]`
          outpath = "./output" / `svg[1]`
        
        compileSvg2Vue(svgpath, outpath)

        check fileExists outpath
        removeFile outpath

suite "all":
  testgen()