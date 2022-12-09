# This function creates a NixOS system based on our VM setup for a
# particular architecture.
#
# I am only building one architecture, so this function was modified
# to handle only x86_64-linux.
name: { nixpkgs, home-manager, system, user, overlays }:

nixpkgs.lib.nixosSystem rec {
  inherit system;

  modules = [
    # Apply our overlays. Overlays are keyed by system type so we have
    # to go through and apply our system type. We do this first so
    # the overlays are available globally.
    { nixpkgs.overlays = overlays; }

    # For both hardware and machines, I have not yet taken the time
    # to understand what they do exactly. So I've copied them verbatim.
    # One difference, I've only copied for the VMs and arch that I
    # currently use.
    ../hardware/${name}.nix
    ../machines/${name}.nix
    home-manager.nixosModules.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import ../users/${user}/home-manager.nix;
    }

    # We expose some extra arguments so that our modules can parameterize
    # better based on these values.
    {
      config._module.args = {
        currentSystemName = name;
        currentSystem = system;
      };
    }
  ];
}
