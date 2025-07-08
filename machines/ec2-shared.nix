# Shared configuration for EC2 instances (headless, security-hardened)
{ config, pkgs, lib, currentSystem, currentSystemName, ... }:

{
  # Use stable kernel for better EC2 compatibility
  boot.kernelPackages = pkgs.linuxPackages;

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    # public binary cache that I use for all my derivations. You can keep
    # this, use your own, or toss it. Its typically safe to use a binary cache
    # since the data inside is checksummed.
    settings = {
      substituters = [
        "https://jwieringa-nixos-config.cachix.org"
      ];
      trusted-public-keys = [
        "jwieringa-nixos-config.cachix.org-1:ZR2Yfx0c9A6EQ+i94lgIOwma7LxVIx4eEMEKu5KrX4w="
      ];
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 3;  # Keep only 3 latest generations

  # Define your hostname.
  networking.hostName = "ec2-dev";

  # Set your time zone.
  time.timeZone = "Etc/UTC";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;
  virtualisation.lxd = {
    enable = true;
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  # Enable tailscale. We manually authenticate when we want with
  # "sudo tailscale up". If you don't use tailscale, you should comment
  # out or delete all of this.
  services.tailscale.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.mutableUsers = false;

  # Enable the unfree 1Password packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-gui"
    "1password"
  ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "jason" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    claude-code
    gnumake
    killall
    niv
    xclip
  ];

  # Enable the OpenSSH daemon with security hardening
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;  # Force key-based auth
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      AuthenticationMethods = "publickey";
      X11Forwarding = false;  # Disable X11 forwarding for security
      AllowTcpForwarding = false;  # Disable TCP forwarding
      ClientAliveInterval = 300;  # Keep connections alive
      ClientAliveCountMax = 2;
    };
  };

  # Enable and configure firewall for security
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH only
    allowedUDPPorts = [ ];
    allowPing = true;
    logReversePathDrops = true;
  };

  # Additional security settings
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "65536"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "65536"; }
  ];

  # Fail2ban for SSH protection
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    ignoreIP = [
      "127.0.0.1/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];
  };

  # System monitoring
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxFileSec=1week
  '';
}