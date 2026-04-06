{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./nix-settings.nix
    ./audio.nix
    ./virtualization.nix
    ./i18n.nix
    ./1password.nix
    ./openssh.nix
    ./tailscale.nix
  ];

  # Common system defaults
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;
}
