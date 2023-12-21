{
  description = "An icon generator for nix porjects";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }: let pkgs = nixpkgs.legacyPackages.x86_64-linux; in
  {
    packages.x86_64-linux.genix7000 = pkgs.writeScriptBin "genix7000" "${pkgs.openscad}/bin/openscad $@ ${./genix.scad}";
    packages.x86_64-linux.default   = self.packages.x86_64-linux.genix7000;
    packages.x86_64-linux.to-image  = pkgs.writeScriptBin "to-image"
    (builtins.replaceStrings [
      "./genix.scad"
      "openscad"
      "#!/usr/bin/env nu"
    ] [
      "${./genix.scad}"
      "${pkgs.openscad}/bin/openscad"
      "#!${pkgs.nushell}/bin/nu"
    ] (builtins.readFile ./to-image.nu));
  };
}
