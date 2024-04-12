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

  $colors | par-each { |color| 
    (openscad $filename
      -D ('module color(c) {if (c == "' + $color + '") children();}')
      --export-format svg
      --animate $frames
      -o $"frames/($color).svg")
    # )
  }

  0..($frames - 1) | par-each { |frame|
  
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

    inkscape $'frames/($frame).svg' -o $'frames/($frame).svg'

  }

}
