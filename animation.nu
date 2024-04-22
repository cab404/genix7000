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
  --out: string = "./frames"
  filename: string = "./a good version of the logo.scad"
] {

  mkdir $out
  let tmp = mktemp  -d

  # OpenSCAD exports SVG without colors. We overcome this by
  # 1. Patching `color` function to echo the colors used.
  # 2. Rendering frames for each color separately.
  # 3. Merging all colors of each frame, patching in correct colors and removing stroke.

  print "Rendering to get a list of colors..." -n

  # we will assume that all colors are present in a simple render, and we don't need to go through ALL the frames to get them.
  # but we can
  let colors = (
    openscad $filename
      -o $"($tmp)/_.svg"
      -D `module color(c) {echo(str(c));}`
    e>| lines
    | parse `ECHO: "{color}"`
    | get color
    | uniq
  )

  print " ~ Done"

  print "Colors to export: " $colors

  print "Exporting frames..."

  $colors | par-each { |color|
    print $"Exporting ($color)..."
    (openscad $filename
      -D ('module color(c) {if (c == "' + $color + '") children();}')
      --animate $frames
      --render
      -o $"($tmp)/($color).svg" e>| complete)

    print $"($color) done..."
  }

  print $"Merging frames..."

  # haha a progress bar
  print (0..(($frames - 1) / 5) | each {"_"} | str join) "\r" -n

  0..($frames - 1) | par-each { |frame|
    if ($frame mod 5 == 0) {print -n "λ"}

    let framename = $frame | pad-zeroes;

    # Extracting paths from separate colors we've exported and actually coloring them
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

    # Merging those paths into a single good-enough-for-inkscape SVG
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
  # not sure if that would break if there are even more command line parameters, but it works fine with a thousand frames
  inkscape ...(0..($frames - 1) | each { $'($tmp)/($in).svg' }) --export-type=png -w $export_width -h $export_height
  print " ~ Done"

  print "Moving frames from temporary folder..." -n
  for frame in 0..($frames - 1) {
    mv $'($tmp)/($frame).png' $"($out)/($frame).png"
  }
  print " ~ Done"

  print "Deleting temporary files..." -n
  rm -rf $tmp
  print " ~ Done"

  print $"Exported frames are located in `($out)`"
}
