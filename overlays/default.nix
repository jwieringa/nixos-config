{ inputs }:

[
  inputs.zig.overlays.default

  (final: prev: {
    # awscli2 on stable 25.05 is 2.27.2, well behind upstream. Unstable tracks
    # the current release.
    awscli2 = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.awscli2;

    # gh CLI on stable has bugs.
    gh = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.gh;

    # tfswitch on stable (1.4.5) ships an expired HashiCorp PGP key — see
    # warrensbox/terraform-switcher#746. Unstable has 1.17.x with the fix.
    tfswitch = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.tfswitch;

    # CrunchyBridge CLI - packaged from GitHub releases
    bridge-cli =
      let
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
      in
      prev.stdenv.mkDerivation {
        pname = "bridge-cli";
        inherit version;

        src = prev.fetchzip {
          url = "https://github.com/CrunchyData/bridge-cli/releases/download/v${version}/cb-v${version}_${archMap.${prev.system}}.zip";
          hash = hashMap.${prev.system};
        };

        installPhase = ''
          mkdir -p $out/bin
          cp cb $out/bin/
          chmod +x $out/bin/cb
        '';

        meta = {
          description = "CLI for CrunchyBridge PostgreSQL";
          homepage = "https://github.com/CrunchyData/bridge-cli";
          license = prev.lib.licenses.asl20;
          mainProgram = "cb";
        };
      };
  })
]
