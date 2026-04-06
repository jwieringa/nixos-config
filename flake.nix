# Credit: https://github.com/mitchellh/nixos-config/blob/06b6eb4aa6f9817605f4d45a33331f4263e02d58/flake.nix

{
  description = "Jason Wieringa's NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other packages
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # llm-agents needs its own nixpkgs (requires fetchPnpmDeps not in 25.05)
    llm-agents.url = "github:numtide/llm-agents.nix";
    # Fish plugins (non-flake sources, replacing Niv)
    fish-fzf = {
      url = "github:jethrokuan/fzf";
      flake = false;
    };
    fish-foreign-env = {
      url = "github:oh-my-fish/plugin-foreign-env";
      flake = false;
    };
    theme-bobthefish = {
      url = "github:oh-my-fish/theme-bobthefish";
      flake = false;
    };

    # Treesitter grammars (non-flake sources, replacing Niv)
    tree-sitter-proto = {
      url = "github:mitchellh/tree-sitter-proto";
      flake = false;
    };
    tree-sitter-hcl = {
      url = "github:mitchellh/tree-sitter-hcl";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      overlays = import ./overlays { inherit inputs; };

      mkSystem = import ./lib/mksystem.nix {
        inherit overlays nixpkgs inputs;
      };
    in
    {
      nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
        inherit system;
        user = "jason";
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixfmt-rfc-style
          nil
        ];
      };

      checks.${system} = {
        system-build = self.nixosConfigurations.vm-aarch64.config.system.build.toplevel;

        formatting =
          pkgs.runCommand "check-formatting"
            {
              nativeBuildInputs = [ pkgs.nixfmt-rfc-style ];
            }
            ''
              nixfmt --check ${self} && touch $out
            '';
      };
    };
}
