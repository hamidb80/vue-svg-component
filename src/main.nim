import os,
  xmlparser, xmltree,
  tables, strtabs,
  strutils, strformat, sequtils,
  sugar, std/with

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


proc main(svgPath, outPath: string) =
  let
    svgEl = loadXml svgPath # xml tree
    splittedFname = splitFile svgPath

  # remove/modify attributes
  multiDel svgel.attrs, ["class", "style"]

  var styles = parseStyles svgel.attr "style"
  multiDel styles, ["width", "height", "fill"]

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
  if paramCount() >= 1:
    main paramStr 1, "output/ex.vue"

  else:
    quit "no file input"
