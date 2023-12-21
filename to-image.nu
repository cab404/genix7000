#!/usr/bin/env nu

# Export nix logo
def main [
  --num:int        = 7,               # Number of lambdas
  --thick:int      = 20,              # Lambda thickness
  --imgsize:string = "860,860",       # Image size in px
  --offset:string  = "-30,-40",       # Offset of lambda
  --gaps:string    = "-2,-2",         # Offset after clipping. Use for gaps.
  --rotation:int   = 0,               # Rotation of each lambda
  --angle:int      = 30,              # Lambda arm angle
  --camera:string  = "0,0,480,0,0,0", # Image camera
  --clipr:int      = 90,              # Clipping ngon radius
  --cliprot:int    = 90,              # Clipping ngon rotation
  --clipinv:bool   = false,           # Inverse clipping order
  outfile:string   = "mynix.png",     # Image filename
  ...colors:string                    # colors to use, ie "\#cd3535" "\#cd6b35" "\#cdb835"
] {
  let colors = if ($colors|length) > 0 { $colors|each {|it| $it|str replace "\\" ""} } else {
    ["#cd3535", "#cd6b35", "#cdb835", "#35cd62", "#35cdc1", "#3577cd", "#9a35cd"]
  }
  let parameterSets = (mktemp) 
  {
    parameterSets: {
      default: {
        clipr:   $clipr,
        cliprot: $cliprot,
        colors:  $"($colors)",
        foff:    $"($offset|split row ',')",
        gaps:    $"($gaps|split row ',')",
        invclip: $clipinv,
        larm:    $angle,
        lrot:    $rotation,
        num:     $num,
        thick:   $thick
      }
    }
  }|to json|save -f $parameterSets
  if $outfile !~ ".svg$" {
    (openscad
        -o $outfile
        -P default
        -p $parameterSets
        --imgsize $imgsize
        --camera  $camera
        ./genix.scad)
  } else {
    let echOlors = "module color(c) {echo(str(c));}"
    let svg_path_re = "<path(\\n|\\N)*/>"
    let colors = (sh -c $'openscad \
      -o ($outfile) \
      -P default \
      -p ($parameterSets) \
      -D "($echOlors)" \
      --imgsize ($imgsize) \
      --camera  ($camera) \
      ./genix.scad 2>&1 |\
      grep -Po "\"#......\"$" '
     |lines
     |each {|it|$it|from nuon}
     |each {|it|{ color: $it, modu: ("module color(c) {if (c == \"" + $it + "\") children();}")} }
    )
    let colors = ($colors|each {|it| $'openscad \
        -p ($parameterSets) \
        -P default \
        ./genix.scad \
        --export-format svg  \
        -o - \
        -D '($it.modu)' \
        2>/dev/null | \
      sed "s/stroke=\"black\"//g" |
      sed "s/stroke-width=\"0.5\"//g" |
      sed "s/lightgray/($it.color)/g" |
      grep -Pzo '($svg_path_re)' |
      head -c-1
      echo'
    })
    let translation = "(100 100)"
    let svg_image = $'<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg" version="1.1">
  <title>($outfile|str replace "." "")</title>
  <g id="layer1"  transform="translate($translation)">
  ($colors|each {|color|sh -c $color}|str join "")
  </g>
</svg>'
    $svg_image|save -f $outfile
  }
  rm $parameterSets
}
