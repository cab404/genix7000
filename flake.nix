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
        outfile:string   = "y.png",
        --clipr:string   = "100",
        --cliprot:string = "10",
        --colors:string  = "[\"red\"]",
        --foff:string    = "[37, -16]",
        --gaps:string    = "[3, -5]",
        --invclip:string = "true",
        --larm:string    = "36",
        --lrot:string    = "0",
        --num:string     = "5",
        --thick:string   = "18",
        --camera:string  = "eye_5,50,100,center_0,0,100",
      ] {
        let parameterSets = (mktemp)
        {
          parameterSets: {
            default: {
              clipr:   $clipr,
              cliprot: $cliprot,
              colors:  $colors,
              foff:    $foff,
              gaps:    $gaps,
              invclip: $invclip,
              larm:    $larm,
              lrot:    $lrot,
              num:     $num,
              thick:   $thick
            }
          }
        }|to json|save -f $parameterSets
        (${pkgs.openscad}/bin/openscad
              -o $outfile
              -P default
              -p $parameterSets
              --camera $camera
              ${./genix.scad})
        rm $parameterSets
      }
    '';
  };
}
