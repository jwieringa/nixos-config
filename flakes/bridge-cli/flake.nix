{
  description = "CrunchyBridge CLI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      version = "3.6.7";

      archMap = {
        x86_64-linux = "linux_amd64";
        aarch64-linux = "linux_aarch64";
        x86_64-darwin = "macos_amd64";
        aarch64-darwin = "macos_arm64";
      };

      hashMap = {
        x86_64-linux = "sha256-iLz7uUajf5lUQXocnnYbQvtLzZGeYLWZD+uU4PRHpQs=";
        aarch64-linux = "sha256-nY7+v2hbHdMo9aXCRlsvtFqE+JqjDAoWFmG/hioGAlA=";
        x86_64-darwin = "sha256-hNTqD9MrlRZGagF70ndwVQ8u9/9s8TA2D5R9jWegDvc=";
        aarch64-darwin = "sha256-J5GocvSBCPBI7J29iKOEGaszTULLZ+XMZEUruok/vO0=";
      };

      bridge-cli = pkgs.stdenv.mkDerivation {
        pname = "bridge-cli";
        inherit version;

        src = pkgs.fetchzip {
          url = "https://github.com/CrunchyData/bridge-cli/releases/download/v${version}/cb-v${version}_${archMap.${system}}.zip";
          hash = hashMap.${system};
        };

        installPhase = ''
          mkdir -p $out/bin
          cp cb $out/bin/
          chmod +x $out/bin/cb
        '';

        meta = with pkgs.lib; {
          description = "CLI for CrunchyBridge PostgreSQL";
          homepage = "https://github.com/CrunchyData/bridge-cli";
          license = licenses.asl20;
          mainProgram = "cb";
        };
      };
    in
    {
      packages = {
        default = bridge-cli;
        bridge-cli = bridge-cli;
      };
    });
}
