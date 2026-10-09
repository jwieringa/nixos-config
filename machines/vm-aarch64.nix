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

  # Fusion's vmnet-natd DNS forwarder (192.168.195.2) corrupts replies to
  # any query carrying an EDNS0 OPT record, which breaks dig, Go programs
  # such as Tailscale, and anything else that builds its own queries. The
  # guest bypasses it by resolving through systemd-resolved with strict
  # DNS-over-TLS to Quad9. The empty fallback list keeps resolved off its
  # built-in Cloudflare and Google servers.
  networking.nameservers = [
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
  ];
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSOverTLS = true;
      FallbackDNS = [ ];
    };
  };

  # NetworkManager, not dhcpcd, owns enp2s0, and by default it hands the
  # DHCP-supplied natd address to resolved as a per-link DNS server. This
  # stops NetworkManager from passing any DNS to resolved, so resolved
  # only knows about Quad9 and whatever Tailscale registers on its own.
  networking.networkmanager = {
    dns = lib.mkForce "none";
    settings.main.systemd-resolved = false;
  };

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnsupportedSystem = true;

  # open-vm-tools guest integration. The upstream module supports aarch64
  # since NixOS 26.05, so the local fork that used to be needed is gone.
  virtualisation.vmware.guest.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    cachix
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
    gnumake
    killall
    rtk
    wl-clipboard
    xclip
    zig
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
