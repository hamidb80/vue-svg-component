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

const
  defaultConfigFileName = "vuesvg.cfg"
  version = block:
    var res: string
    for line in splitlines readfile "./vue_svg_component.nimble":
      if line.startswith "version":
        res = line.splitwhitespace[^1].strip(chars = {'"'})
        break
    res

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
        display: inline-flex;
        flex-wrap: wrap;
      }

      .icon-wrapper{
        display: flex;
        padding: 8px;
        flex-direction: column;
        align-items: center;
      }
      img{
        width: 64px;
        height: 64px;
        border: 1px solid red;
      }

      .label{
        font-weight: bold;
        text-align: center;
      }
    """),
    body(iconElems.join)
  )

# ----------------------------------------------

const p = newParser:
  help [
    """
      ..:: Vue svg component ::..
      Author: hamidb80
      Version: """ & version, """
      
      Example or usage:
        * full usage:
          app  -w  -s  -db='output/db.json'  -p='./preview.html'  './assets/'  './output/'
        * load from config file
          app  -c
      """
  ].mapIt(it.strip.unindent 3 * 2).join "\n"

  flag("-s", "--save", help = "save states on every check")
  flag("-v", "--version", help = "shows the version", shortcircuit = true)
  flag("-w", "--watch", help = "enables watch for changes in traget folder")
  flag("-c", "--config", help = fmt"load from config file named '{defaultConfigFileName}' in the directory",
      shortcircuit = true)
  option("-db", "--database", help = "database file path")
  option("-p", "--preview", help = "create a icon list html file in given path")
  option("-ti", "--timeinvertal", default = some("1000"),
      help = "timeout after every check in milliseconds [ms]")
  arg("target", help = "folder to watch")
  arg("output", help = "folder to put outputs in")


proc run(args: typeof p.parse(newseq[string]())) =
  let
    timeout = parseInt args.timeinvertal
    previewMode = args.preview != ""

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
      somethingNew = false
      (av, feed) = ch.tryrecv

    while av:
      somethingNew = true
      echo fmt"'{feed.path}', {feed.kind}"

      let fname = splitFile feed.path
      if fname.ext != ".svg": continue

      let opath = args.output / fname.name & ".vue"

      if feed.kind in [CFCreate, CFEdit]:
        compileSvg2Vue feed.path, opath
      else:
        removeFile opath # CFDelete

      (av, feed) = ch.tryrecv

    if previewMode and somethingNew:
      genHTMLpreview(
        args.target.walkDir.toseq.filterIt(
            it.path.endsWith "svg").mapIt it.path,
        args.preview
      )
      echo "preview file generated in: ", args.preview

    if not active: break


template runProctected(args): untyped =
  try:
    run args
  except:
    stderr.writeLine "Error: ", getCurrentExceptionMsg()
    quit 1


when isMainModule:
  try:
    let args = p.parse commandLineParams()
    runProctected args

  except ShortCircuit as e:
    case e.flag:
    of "argparse_help":
      echo p.help
    of "version":
      echo version
    of "config":
      runProctected p.parse splitWhitespace readFile defaultConfigFileName
