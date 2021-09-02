import unittest, os
import main

test "compiles":
  const 
    svgpath = "./assets/database.svg"
    outpath = "./output/database.vue"
  compileSvg2Vue(svgpath, outpath)

  check fileExists outpath
  removeFile outpath