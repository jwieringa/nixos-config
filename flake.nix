# Credit: https://github.com/mitchellh/nixos-config/blob/06b6eb4aa6f9817605f4d45a33331f4263e02d58/flake.nix

{
  description = "Jason Wieringa's NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other packages
    zig.url = "github:mitchellh/zig-overlay";
    
    # Local flakes
    claude-code.url = "path:./flakes/claude-code";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let
    overlays = [
      inputs.zig.overlays.default

      (final: prev: {
        # gh CLI on stable has bugs.
        gh = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.gh;
        # Add claude-code globally
        claude-code = inputs.claude-code.packages.${prev.system}.default;
      })
    ];

    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
      system = "aarch64-linux";
      user   = "jason";
    };
    
    nixosConfigurations.ec2-aarch64 = mkSystem "ec2-aarch64" {
      system = "aarch64-linux";
      user   = "jason";
    };
  };
}
