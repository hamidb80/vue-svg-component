import os,
  xmlparser, xmltree, 
  tables, strtabs,
  strutils, strformat, sequtils,
  sugar, std/with

type
  cssStyles = Table[string, string]

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

template multiDel(t: untyped, keys: openArray[string])=
  for k in keys:
    del t, k

proc main(fname: string) =
  let
    svgEl = loadXml fname # xml tree
    pathEls = svgEl.findall "path"
    splittedFname = splitFile fname

  var styles = parseStyles svgel.attr "style"
  multiDel svgel.attrs, ["style", "class"]

  # remove them
  multiDel styles, ["width", "height", "fill"]

  for pel in pathels:
    multiDel pel.attrs, ["id", "style", "fill"]

  let vueFile = newElement("wrapper")
  with vueFile:
    add newXmlTree("template", [svgEl])
    add newXmlTree("script", [newText [
      """

        export default {
          name: """, "\"i-" & splittedFname.name & "\",\n",
        """
        }
      """,
    ].join.unindent 4 * 2])
    add newXmlTree("style", [newText [
       "\nsvg{\n",
       `$`(styles, ";\n").indent 2,
       "\n}\n"
    ].join], {"scoped": "scoped"}.toXmlAttributes)

  writeFile fmt"./output/{splittedfname.name}.vue",
      vuefile.items.toseq.join("\n\n").replace("&quot;", "\"")


when isMainModule:
  if paramCount() >= 1:
    main paramStr 1
  else:
    quit "no file input"
