{ inputs }:

[
  inputs.zig.overlays.default

  (
    final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
    in
    {
      # awscli2 on stable 25.05 is 2.27.2, well behind upstream. Unstable tracks
      # the current release.
      awscli2 = inputs.nixpkgs-unstable.legacyPackages.${system}.awscli2;

      # gh CLI on stable has bugs.
      gh = inputs.nixpkgs-unstable.legacyPackages.${system}.gh;

      # tfswitch on stable (1.4.5) ships an expired HashiCorp PGP key — see
      # warrensbox/terraform-switcher#746. Unstable has 1.17.x with the fix.
      tfswitch = inputs.nixpkgs-unstable.legacyPackages.${system}.tfswitch;

      # rtk (Rust Token Killer) - CLI proxy that filters and summarizes
      # command output before it reaches an LLM context. Not in nixpkgs, so we
      # package the upstream GitHub release binaries.
      rtk =
        let
          version = "0.39.0";
          assetMap = {
            x86_64-linux = "rtk-x86_64-unknown-linux-musl.tar.gz";
            aarch64-linux = "rtk-aarch64-unknown-linux-gnu.tar.gz";
            x86_64-darwin = "rtk-x86_64-apple-darwin.tar.gz";
            aarch64-darwin = "rtk-aarch64-apple-darwin.tar.gz";
          };
          hashMap = {
            x86_64-linux = "sha256-BuWCuhmW7wPnakQbmJarp53Rt0bOU50igpbGgbHFQBw=";
            aarch64-linux = "sha256-aP00y/9GhWgmoJLCYdZ7G4C1ee9sigQAwAieFDJecJ0=";
            x86_64-darwin = "sha256-w7siXWnHKhoZD100GzlYv5I8ckKHRifvLZ+ALTdD/1w=";
            aarch64-darwin = "sha256-DRQLq/ulTDcpizLnsq0fIcchebIrvN8Byc1mu5riiFU=";
          };
        in
        prev.stdenv.mkDerivation {
          pname = "rtk";
          inherit version;

          src = prev.fetchurl {
            url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/${assetMap.${system}}";
            hash = hashMap.${system};
          };

          sourceRoot = ".";

          nativeBuildInputs = prev.lib.optionals prev.stdenv.isLinux [ prev.autoPatchelfHook ];
          buildInputs = prev.lib.optionals prev.stdenv.isLinux [ prev.stdenv.cc.cc.lib ];

          installPhase = ''
            runHook preInstall
            install -Dm755 rtk $out/bin/rtk
            runHook postInstall
          '';

          meta = {
            description = "CLI proxy that filters and summarizes output before it reaches an LLM context";
            homepage = "https://github.com/rtk-ai/rtk";
            mainProgram = "rtk";
          };
        };

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
            url = "https://github.com/CrunchyData/bridge-cli/releases/download/v${version}/cb-v${version}_${archMap.${system}}.zip";
            hash = hashMap.${system};
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
    }
  )
]
