{
  description = "claude-code global package";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        claudeCode = pkgs.buildNpmPackage {
          pname = "claude-code";
          version = "0.2.50";
          src = ./.;
          npmDepsHash = "sha256-+zq83EgOYu1NdOFSahdLnWnvzvOSsmoyYv7Hgf9sAg4=";
          
          # Disable npm build since there's no build script
          dontNpmBuild = true;
          
          # Install phase to make the package globally available
          installPhase = ''
            mkdir -p $out/bin $out/lib/node_modules/@anthropic-ai
            cp -r node_modules/@anthropic-ai/claude-code $out/lib/node_modules/@anthropic-ai/
            chmod +x $out/lib/node_modules/@anthropic-ai/claude-code/cli.js
            cat > $out/bin/claude <<EOF
            #!/usr/bin/env bash
            exec ${pkgs.nodejs_20}/bin/node $out/lib/node_modules/@anthropic-ai/claude-code/cli.js "\$@"
            EOF
            chmod +x $out/bin/claude
          '';
        };
      in rec {
        # Add the default package
        packages.default = claudeCode;
        packages.claude-code = claudeCode;

        # Create an app that can be run
        apps.default = flake-utils.lib.mkApp {
          drv = claudeCode;
          name = "claude";
        };

      }
    );
}
