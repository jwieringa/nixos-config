{
  description = "Caesars Ambrosia - Vue.js hospitality application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          mkNpmScript =
            name: npmCmd:
            pkgs.writeShellApplication {
              inherit name;
              runtimeInputs = [ pkgs.nodejs_20 ];
              text = "npm run ${npmCmd}";
            };

          scripts = {
            deps = pkgs.writeShellApplication {
              name = "deps";
              runtimeInputs = [ pkgs.yarn ];
              text = "yarn install";
            };
            dev = mkNpmScript "dev" "dev";
            build = mkNpmScript "build" "build";
            test = mkNpmScript "test" "test:unit";
            lint = mkNpmScript "lint" "lint";
          };
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.nodejs_20
              pkgs.yarn
            ]
            ++ builtins.attrValues scripts;

            shellHook = ''
              export PATH="$PWD/node_modules/.bin:$PATH"
              echo "Caesars Ambrosia dev environment"
              echo "Node: $(node --version)"
              echo "Commands: deps, dev, build, test, lint"
            '';
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          mkNpmScript =
            name: npmCmd:
            pkgs.writeShellApplication {
              inherit name;
              runtimeInputs = [ pkgs.nodejs_20 ];
              text = "npm run ${npmCmd}";
            };

          scripts = {
            deps = pkgs.writeShellApplication {
              name = "deps";
              runtimeInputs = [ pkgs.yarn ];
              text = "yarn install";
            };
            dev = mkNpmScript "dev" "dev";
            build = mkNpmScript "build" "build";
            test = mkNpmScript "test" "test:unit";
            lint = mkNpmScript "lint" "lint";
          };

          mkApp = script: {
            type = "program";
            program = "${script}/bin/${script.name}";
          };
        in
        builtins.mapAttrs (_: mkApp) scripts
      );
    };
}
