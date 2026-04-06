{
  description = "Development environment with latest Node.js";

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

          # Use the latest Node.js LTS version from nixpkgs
          nodejs = pkgs.nodejs_22;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nodejs
              # Common Node.js development tools
              nodePackages.npm
              nodePackages.yarn
              nodePackages.pnpm
              nodePackages.node-gyp
              nodePackages.typescript
              nodePackages.typescript-language-server
              nodePackages.prettier
              nodePackages.eslint
              nodePackages.nodemon

              # Build dependencies that are often needed
              python3
              gcc
              gnumake
              pkg-config

              # Additional useful tools
              git
              curl
              jq
            ];

            shellHook = ''
              echo "Node.js development environment"
              echo "Node.js: $(node --version)"
              echo "npm: $(npm --version)"
              echo "yarn: $(yarn --version)"
              echo "pnpm: $(pnpm --version)"
              echo ""
              echo "Available tools:"
              echo "  - TypeScript (tsc)"
              echo "  - ESLint"
              echo "  - Prettier"
              echo "  - Nodemon"
              echo "  - node-gyp (for native modules)"
            '';
          };
        }
      );
    };
}
