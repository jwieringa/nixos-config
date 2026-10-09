# Credit: https://github.com/mitchellh/nixos-config/blob/06b6eb4aa6f9817605f4d45a33331f4263e02d58/flake.nix

{
  description = "Jason Wieringa's NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ruby interpreters for the Rails dev shells (lib/rubyshell). Follows our
    # nixpkgs so Ruby shares one glibc/openssl with the libraries the gems link
    # against; the upstream binary cache has no aarch64-linux builds anyway.
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
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

      # Rails project shells, entered from the app repos via
      # `use flake "$HOME/prj/nixos-config#<project>-<ruby_version>"`.
      rubyshell = import ./lib/rubyshell {
        inherit pkgs;
        inherit (inputs) nixpkgs-ruby;
      };
    in
    {
      nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
        inherit system;
        user = "jason";
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt-rfc-style
            nil
          ];
        };
      }
      // rubyshell.projects;

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

        # `nix flake check` only evaluates the dev shells above; it never
        # builds them, so it cannot tell whether a given Ruby version
        # actually compiles. Building each shell's `inputDerivation`, the
        # target nixpkgs provides for exactly this purpose, forces its
        # buildInputs, including the Ruby toolchain, to be realized. Ruby
        # versions below 3.2 are compiled from source because the upstream
        # binary cache has no aarch64-linux builds for them.
        ruby-shells = pkgs.linkFarm "ruby-shells" (
          pkgs.lib.mapAttrs (_: shell: shell.inputDerivation) rubyshell.projects
        );
      };
    };
}
