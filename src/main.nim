import os,
  xmlparser, xmltree,
  tables, strtabs,
  strutils, strformat, sequtils,
  sugar, std/with

import 
  argparse,
  watch_for_files, threadpool


type
  cssStyles = Table[string, string]

template multiDel(t: untyped, keys: openArray[string]) =
  for k in keys:
    del t, k

# ---------------------------------------------------------------

func parseStyles(line: string): cssStyles =
  collect:
    for exp in line.split ';':
      if exp != "":
        let assgnment = exp.split ':'
        {assgnment[0].strip: assgnment[1].strip}

func `$`(s: cssStyles, sep = ","): string =
  let temp = collect:
    for k, v in s:
      fmt"{k}: {v}"

  temp.join sep

# ---------------------------------------------------------------

func createVueTemplate(svgEl: XmlNode, scripts, styles: string): string=
  
  let vueFile = newElement("wrapper")
  with vueFile:
    add newXmlTree("template", [svgEl])
    add newXmlTree("script", [newText scripts])
    add newXmlTree("style", [newText styles], {"scoped": "scoped"}.toXmlAttributes)

  # replace escaped " with real "
  vuefile.items.toseq.join("\n\n").replace("&quot;", "\"")


proc compileSvg2Vue(svgPath, outPath: string) =
  let
    svgEl = loadXml svgPath # xml tree
    splittedFname = splitFile svgPath

  # remove/modify attributes
  var styles = parseStyles svgel.attr "style"
  multiDel styles, ["width", "height", "fill"]
  
  multiDel svgel.attrs, ["class", "style"]

  for pel in svgEl.findall "path":
    multiDel pel.attrs, ["id", "style", "fill"]


  writeFile outpath, createVueTemplate(
    svgEl,
    [
      """

        export default {
          name: """, "\"i-" & splittedfname.name & "\",\n",
        """
        }
      """,
    ].join.unindent 4 * 2,

    [
       "\nsvg{\n",
       `$`(styles, ";\n").indent 2,
       "\n}\n"
    ].join
  )
      


when isMainModule:

  var p = newParser:
    help """
      ..:: Vue svg component ::..
      Author: hamidb80

      Example:
        src/main.nim -s -db='output/db.json' ./assets/ ./output/
      """.strip.unindent 3 * 2

    flag("-s", "--save", help="save states on every check")
    option("-db", "--database", help="database file path")
    option("-t", "--timeinvertal", default=some("1000"), help="timeout after every check in milliseconds [ms]")
    arg("watch", help= "folder to watch")
    arg("output", help= "folder to put outputs in")

  try:
    let args = p.parse(commandLineParams())

    var 
      ch: Channel[ChangeFeed]
      active = true
    ch.open

    spawn goWatch(
      args.watch, 
      unsafeAddr ch, 
      unsafeAddr active, 
      parseInt args.timeinvertal, 
      args.database,
      args.save
    )
  
    while true:
      let (av, feed) = ch.tryrecv
      if av:
        echo fmt"'{feed.path}', {feed.kind}"

        let fname = splitFile(feed.path)
        if fname.ext != ".svg": continue

        let opath = args.output / fname.name & ".vue"

        if feed.kind in [CFCreate, CFEdit]:
          compileSvg2Vue feed.path, opath
        else: # CFDelete
          removeFile opath
      
      sleep 100

  except ShortCircuit as e:
    if e.flag == "argparse_help":
      echo p.help


  except:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

