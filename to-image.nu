#!/usr/bin/env nu

let dAnimation = "{ rotation: ($rotation - $i) }"

# Export nix logo
def main [
  --num:int           = 7,               # Number of lambdas
  --thick:int         = 20,              # Lambda thickness
  --imgsize:string    = "860,860",       # Image size in px
  --offset:string     = "-30,-40",       # Offset of lambda
  --gaps:string       = "-2,-2",         # Offset after clipping. Use for gaps.
  --rotation:int      = 0,               # Rotation of each lambda
  --angle:int         = 30,              # Lambda arm angle
  --camera:string     = "0,0,480,0,0,0", # Image camera
  --clipr:int         = 90,              # Clipping ngon radius
  --cliprot:int       = 90,              # Clipping ngon rotation
  --clipinv           = false,           # Inverse clipping order
  --fps:int           = 15               # video frame rate
  --duration:int      = 5                # video duration
  --animation:string  = dAnimation       # animation function
  outfile:string      = "mynix.png",     # Image filename
  ...colors:string                       # colors to use, ie "\#cd3535" "\#cd6b35" "\#cdb835"
] {
  let colors = if ($colors|length) > 0 { $colors|each {|it| $it|str replace "\\" ""} } else {
    ["#cd3535", "#cd6b35", "#cdb835", "#35cd62", "#35cdc1", "#3577cd", "#9a35cd"]
  }
  let params = {
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
  let parameterSets = (mktemp) 
  {
    parameterSets: {
      default: $params
    }
  }|to json|save -f $parameterSets
  if $outfile !~ ".svg$" and $outfile !~ ".mp4$" {
    (openscad
        -o $outfile
        -P default
        -p $parameterSets
        --imgsize $imgsize
        --camera  $camera
        ./genix.scad)
  } else if $outfile =~ ".mp4$" {
    let framesDir = (mktemp -d)
    print $framesDir
    let animationScript = $"($framesDir)/genix7000Animation.nu"
    $"
      let angle    = ($angle)
      let camera   = ($camera|to nuon)
      let clipinv  = ($clipinv|to nuon)
      let clipr    = ($clipr)
      let cliprot  = ($cliprot)
      let gaps     = ($gaps|to nuon)
      let imgsize  = ($imgsize|to nuon)
      let num      = ($num)
      let offset   = ($offset|to nuon)
      let rotation = ($rotation)
      let thick    = ($thick)

      def main [i: int] {
        ($animation)|to nuon
      }
    "|save -f $animationScript
    1..($fps * $duration)|each {|i|
      print $i
      let parms = ({
        angle:    $angle,
        camera:   $camera,
        clipinv:  $clipinv
        clipr:    $clipr,
        cliprot:  $cliprot,
        colors:   $colors,
        gaps:     $gaps,
        imgsize:  $imgsize,
        num:      $num,
        offset:   $offset,
        rotation: $rotation,
        thick:    $thick,
      }| merge (/usr/bin/env nu $animationScript $i|from nuon))
      let frameNum = (printf '%010d' $i)
      {
        parameterSets: {
          default: {
            clipr:   $parms.clipr,
            cliprot: $parms.cliprot,
            colors:  $"($parms.colors)",
            foff:    $"($parms.offset|split row ',')",
            gaps:    $"($parms.gaps|split row ',')",
            invclip: $parms.clipinv,
            larm:    $parms.angle,
            lrot:    $parms.rotation,
            num:     $parms.num,
            thick:   $parms.thick
          }
        }
      }|to json|save -f $"($framesDir)/params($frameNum).json"
     (openscad
        -o $"($framesDir)/frame($frameNum).png"
        -P default
        -p $"($framesDir)/params($frameNum).json"
        --imgsize $parms.imgsize
        --camera  $parms.camera
        ./genix.scad)
    }
    nix run github:NixOS/nixpkgs#ffmpeg -- -r $fps -pattern_type glob -i $"'($framesDir)/frame*.png'" $outfile
    rm -rf $framesDir
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
