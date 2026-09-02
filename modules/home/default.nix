{ ... }:

{
  imports = [
    ./packages.nix
    ./fish.nix
    ./bash.nix
    ./chromium.nix
    ./git.nix
    ./neovim.nix
    ./gnome-dconf.nix
    ./go.nix
    ./gpg.nix
    ./direnv.nix
    ./terraform.nix
    ./ruby.nix
  ];

  xdg.enable = true;
  home.stateVersion = "24.11";
}
