#!/usr/bin/env nu

def pad-zeroes [
  --len: int = 5
] {
  $in | fill --alignment right --character 0 --width $len 
}

def main [
  --frames: int = 120
  --width: int = 120
  --height: int = 120
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
  mkdir frames

  print "Exporting frames..."

  $colors | par-each { |color|
    print $"Exporting ($color)..."
    (openscad $filename
      -D ('module color(c) {if (c == "' + $color + '") children();}')
      --export-format svg
      --animate $frames
      -o $"frames/($color).svg" e>| complete)
    # )
    print $"($color) done..."
  }

  print $"Merging and post-processing frames..."
  
  # haha a progress bar
  print (0..(($frames - 1) / 5) | each {"_"} | str join) "\r" -n

  0..($frames - 1) | par-each { |frame|
    if ($frame mod 5 == 0) {print -n "|"}
    
    let framename = $frame | pad-zeroes;

    let paths = ($colors 
      | each { |color| {path: $"frames/($color)($framename).svg", color: $color} } 
      | each { if ($in.path | path exists) {[$in]} else {[]} } # no monads?
      | par-each {|mpath| $mpath | each { |d|
        (open $d.path
          | lines
          | drop nth 1 
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
        width: $"($width)mm",
        height: $"($height)mm",
        viewBox: $"-($width) -($height) ($width * 2) ($height * 2)"
      },
      content: [
        ...$paths
      ]
    } | to xml | save -f $'frames/($frame).svg')

  }
  print " ~ Done"
  print "Postprocessing with Inkscape..." -n
  inkscape ...(0..($frames - 1) | each { $'frames/($in).svg' }) --actions ""
  print " ~ Done"

}
