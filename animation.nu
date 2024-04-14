#!/usr/bin/env nu

def pad-zeroes [
  --len: int = 5
] {
  $in | fill --alignment right --character 0 --width $len 
}

def main [
  --frames: int = 120
  --render_width: int = 120
  --render_height: int = 120
  --export_width: int = 120
  --export_height: int = 120 
  filename: string = "./a good version of the logo.scad"
] {
  # parameters are dumb

  # we will assume that all colors are present in a simple render, and we don't need to go through ALL the frames to get them. 
  # but we can
  let colors = (
    openscad $filename
      -o _nothing.svg
      -D `module color(c) {echo(str(c));}` 
    e>| lines 
    | parse `ECHO: "{color}"`
    | get color
    | uniq
  )

  print "Colors to export: " $colors
  
  let out = "frames"
  mkdir $out

  let tmp = mktemp  -d  

  print "Exporting frames..."

  $colors | par-each { |color|
    print $"Exporting ($color)..."
    (openscad $filename
      -D ('module color(c) {if (c == "' + $color + '") children();}')
      --animate $frames
      -o $"($tmp)/($color).svg" e>| complete)

    print $"($color) done..."
  }

  print $"Merging and post-processing frames..."
  
  # haha a progress bar
  print (0..(($frames - 1) / 5) | each {"_"} | str join) "\r" -n

  0..($frames - 1) | par-each { |frame|
    if ($frame mod 5 == 0) {print -n "|"}
    
    let framename = $frame | pad-zeroes;

    let paths = ($colors 
      | each { |color| {path: $"($tmp)/($color)($framename).svg", color: $color} } 
      | each { if ($in.path | path exists) {[$in]} else {[]} } # no monads?
      | par-each {|mpath| $mpath | each { |d|
        (open $d.path
          | lines
          | drop nth 1 # DTD breaks XML imports in Nushell 
          | str join
          | from xml
          | get content.1
          | reject attributes.stroke
          | reject attributes.stroke-width
          | update attributes.fill $d.color)
      }}
      | flatten
    )
    ({
      tag: "svg",
      attributes: {
        width: $"($render_width)mm",
        height: $"($render_height)mm",
        viewBox: $"-($render_width) -($render_height) ($render_width * 2) ($render_height * 2)"
      },
      content: [
        ...$paths
      ]
    } | to xml | save -f $'($tmp)/($frame).svg')

  }
  print " ~ Done"
  print "Postprocessing with Inkscape..." -n
  inkscape ...(0..($frames - 1) | each { $'($tmp)/($in).svg' }) --export-type=png -w $export_width -h $export_height
  print " ~ Done"
  
  print "Moving frames from temporary folder..." -n
  for frame in 0..($frames - 1) {
    mv $'($tmp)/($frame).png' $"($out)/($frame).png"
  }
  print " ~ Done"

}
