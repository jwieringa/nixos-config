{
  description = "claude-code global package";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        claudeCodeBase = {
          pname = "claude-code";
          version = "2.0.5";
          src = ./.;
        };
      in
      {
        packages = {
          # Normal build
          claude-code = pkgs.buildNpmPackage (claudeCodeBase // {
            npmDepsHash = "sha256-TMFNyDcIC7aXwg4JIyy4VRBYJE6DiPq5KSIg4fr2lvo=";
            
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
          });
          
          # Hash getter
          get-hash = pkgs.buildNpmPackage (claudeCodeBase // {
            npmDepsHash = pkgs.lib.fakeHash;
          });
          
          # Default package
          default = self.packages.${system}.claude-code;
        };

        # Create an app that can be run
        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.claude-code;
          name = "claude";
        };

      }
    );
}
