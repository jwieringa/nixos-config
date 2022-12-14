# Credit: https://github.com/mitchellh/nixos-config/blob/501f9aa0a669479c34d8d036f52a15b04002d259/flake.nix

{
  description = "Jason Wieringa's NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-22.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    # This configuration would produce a vmdx for use in VMware.
    #
    # I tried to build a VMware image on Github actions, but they do not yet support
    # nested virtualization (kvm). I'll need a place in CI to build the VM image to
    # enable this workflow.
    #
    # packages.x86_64-linux = {
    # 	vmwareImage = self.nixosConfigurations.vm-intel.config.system.build.vmwareImage;
    # };

    nixosConfigurations.vm-aarch64 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./hardware/vm-aarch64.nix
        ./machines/vm-aarch64.nix
        home-manager.nixosModules.home-manager {
          home-manager.users.jason = import ./users/jason/home-manager.nix;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];
    };
  };
}
