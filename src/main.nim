import os,
  htmlgen, xmlparser, xmltree,
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

# ----------------------------------------------

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

# ----------------------------------------------

func createVueTemplate(svgEl: XmlNode, scripts, styles: string): string =

  let vueFile = newElement("wrapper")
  with vueFile:
    add newXmlTree("template", [svgEl])
    add newXmlTree("script", [newText scripts])
    add newXmlTree("style", [newText styles], {
        "scoped": "scoped"}.toXmlAttributes)

  # replace escaped " with real "
  vuefile.items.toseq.join("\n\n").replace("&quot;", "\"")

proc removeStylesInChildren(xml: XmlNode, styleKeys: openArray[string]) =
  for node in xml:
    if node.attrsLen == 0:
      continue

    multiDel node.attrs, styleKeys

    if node.len != 0:
      removeStylesInChildren(node, styleKeys)

proc compileSvg2Vue*(svgPath, outPath: string) =
  let
    svgEl = loadXml svgPath # xml tree
    splittedFname = splitFile svgPath

  # remove/modify attributes
  var styles = parseStyles svgel.attr "style"
  multiDel styles, ["width", "height", "fill"]
  multiDel svgel.attrs, ["class", "style", "fill"]
  removeStylesInChildren svgEl, ["id", "style", "fill"]

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

proc genHTMLpreview*(files: openArray[string], dest: string) =
  var iconElems: seq[string]
  let destSplitted = splitFile dest

  for path in files:
    iconElems.add `div`(class = "icon-wrapper",
      img(src = relativePath(path, destSplitted.dir), alt = ""),
      `div`(class = "label", path.splitFile.name),
    )

  writeFile dest, html(
    style("""
      body{
        display: flex;
      }

      .icon-wrapper{
        display: flex;
        flex-direction: column;
        align-items: center;
      }
      img{
        width: 64px;
        height: 64px;
      }

      .label{
        font-weight: bold;
        text-align: center;
      }
    """),
    body(iconElems.join)
  )

# ----------------------------------------------

when isMainModule:
  const p = newParser:
    help """
      ..:: Vue svg component ::..
      Author: hamidb80

      Example:
        src/main.nim -s -db='output/db.json' ./assets/ ./output/
      """.strip.unindent 3 * 2

    flag("-s", "--save", help = "save states on every check")
    flag("-w", "--watch", help = "enables watch for changes in traget folder")
    option("-db", "--database", help = "database file path")
    option("-d", "--display", help = "create a icon list html file in given path ||| DO NOT use it with database(-db) or file watcher(-w)")
    option("-t", "--timeinvertal", default = some("1000"),
        help = "timeout after every check in milliseconds [ms]")
    arg("target", help = "folder to watch")
    arg("output", help = "folder to put outputs in")

  try:
    let args = p.parse(commandLineParams())
    let timeout = parseInt args.timeinvertal

    var
      ch: Channel[ChangeFeed]
      active = args.watch
    ch.open


    spawn goWatch(
      args.target,
      unsafeAddr ch,
      unsafeAddr active,
      timeout,
      args.database,
      args.save
    )

    while true:
      sleep timeout

      var
        (av, feed) = ch.tryrecv
        svgsPath: seq[string]

      while av:
        echo fmt"'{feed.path}', {feed.kind}"

        let fname = splitFile feed.path
        if fname.ext != ".svg": continue

        let opath = args.output / fname.name & ".vue"

        if feed.kind in [CFCreate, CFEdit]:
          svgsPath.add feed.path
          compileSvg2Vue feed.path, opath

        else: # CFDelete
          removeFile opath

        (av, feed) = ch.tryrecv

      if args.display != "":
        genHTMLpreview svgsPath, args.display

      svgsPath.setlen 0
      if not active: break

  except ShortCircuit as e:
    if e.flag == "argparse_help":
      echo p.help

  except:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)
