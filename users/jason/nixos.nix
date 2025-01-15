{ pkgs, inputs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  environment.pathsToLink = [ "/share/fish" ];

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.fish.enable = true;

  users.users.jason = {
    isNormalUser = true;
    home = "/home/jason";
    extraGroups = [ "docker" "lxd" "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$6$2Xl8HyXvIvvKz72N$tH05lpPXk1MiZofDkhZs8W6K.0Xs0p3Xlwh4FO/x.3N.R/BluK3zB/IzrgtPiU9/jm2jPctiEBCLOJs8aFudo.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIqztDzifQPfJgEmrfQtE5XNYHOtQne2fiTREkKSC9u jason"
    ];
  };

  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix { inherit inputs; })
  ];
}
