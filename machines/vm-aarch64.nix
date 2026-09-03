{
  config,
  pkgs,
  lib,
  inputs,
  currentSystemName,
  ...
}:

{
  imports = [
    ./hardware/vm-aarch64.nix
    ../modules/nixos
  ];

  # Enable NixOS modules
  my.boot.enable = true;
  my.networking.enable = true;
  my.nix.enable = true;
  my.audio.enable = true;
  my.i18n.enable = true;
  my.openssh.enable = true;
  my.tailscale.enable = true;
  my.onepassword.enable = true;
  my.gnome.enable = true;
  my.virtualization.docker.enable = true;

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Interface is this on M1
  networking.interfaces.ens160.useDHCP = true;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnsupportedSystem = true;

  # open-vm-tools guest integration. The upstream module supports aarch64
  # since NixOS 26.05, so the local fork that used to be needed is gone.
  virtualisation.vmware.guest.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    cachix
    inputs.llm-agents.packages.${pkgs.system}.claude-code
    gnumake
    killall
    rtk
    xclip
    zig

    # For hypervisors that support auto-resizing, this script forces it.
    (writeShellScriptBin "xrandr-auto" ''
      xrandr --output Virtual-1 --auto
    '')

    # Needed for the vmware user tools clipboard to work.
    gtkmm3
  ];

  # Share our host filesystem
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };
}
