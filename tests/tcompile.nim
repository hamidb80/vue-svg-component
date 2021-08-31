import unittest
import main

test "compiles":
  const svgpath = "./assets/database.svg"
  compileSvg2Vue(svgpath, "./output/database.vue")