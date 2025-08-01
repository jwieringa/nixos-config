{
  description = "Development environment with Node.js 10";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Node.js 10 requires an older nixpkgs revision
        oldPkgs = import (fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz";
          sha256 = "0mhqhq21y5vrr1f30qd2bvydv4bbbslvyzclhw0kdxmkgg3z4c92";
        }) { inherit system; };
        
        nodejs = oldPkgs.nodejs-10_x;
        python2 = oldPkgs.python2;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            python2
            gcc
            gnumake
            pkg-config
            # Add other dependencies as needed
          ];
          
          shellHook = ''
            echo "Node.js $(node --version) environment"
            echo "npm $(npm --version)"
          '';
        };
      });
}