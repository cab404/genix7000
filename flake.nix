{
  description = "An icon generator for nix porjects";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }: let pkgs = nixpkgs.legacyPackages.x86_64-linux; in
  {
    packages.x86_64-linux.genix7000 = pkgs.writeScriptBin "genix7000" "${pkgs.openscad}/bin/openscad $@ ${./genix.scad}";
    packages.x86_64-linux.default   = self.packages.x86_64-linux.genix7000;
    packages.x86_64-linux.to-image  = pkgs.writeScriptBin "to-image" ''
      #!${pkgs.nushell}/bin/nu

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
        (${pkgs.openscad}/bin/openscad
              -o $outfile
              -P default
              -p $parameterSets
              --imgsize $imgsize
              --camera  $camera
              ${./genix.scad})
        rm $parameterSets
      }
    '';
  };
}
