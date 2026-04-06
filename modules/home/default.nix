{ ... }:

{
  imports = [
    ./packages.nix
    ./fish.nix
    ./bash.nix
    ./git.nix
    ./neovim.nix
    ./gnome-dconf.nix
    ./go.nix
    ./gpg.nix
    ./direnv.nix
    ./terraform.nix
  ];

  xdg.enable = true;
  home.stateVersion = "24.11";
}
