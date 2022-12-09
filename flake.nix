# Credit: https://github.com/mitchellh/nixos-config/blob/501f9aa0a669479c34d8d036f52a15b04002d259/flake.nix

{
  description = "NixOS systems and tools by jwieringa";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/release-22.11";

    # I don't know if I need this yet, so I've disabled it.
    # We use the unstable nixpkgs repo for some packages.
    # nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";

      # We want home-manager to use the same set of nixpkgs as our system.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let
    mkVM = import ./lib/mkvm.nix;

    # Overlays is the list of overlays we want to apply from flake inputs.
    overlays = [];
  in {
    nixosConfigurations.vm-intel = mkVM "vm-intel" rec {
      inherit nixpkgs home-manager overlays;
      system = "x86_64-linux";
      user   = "jason";
    };

    # Use this to prepare a new VMWare image.
    #
    # $ nix build .#vmwareImage -L
    # $ open ./result/*.vmdk

    # Enable for M1 build?
    # packages.aarch64-linux = {
    #   vmwareImage =
    #     self.nixosConfigurations.vm-aarch64.config.system.build.vmwareImage;
    # };

    packages.x86_64-linux = {
      vmwareImage =
        self.nixosConfigurations.vm-intel.config.system.build.vmwareImage;
    };
  };
}
