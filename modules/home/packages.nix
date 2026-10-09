{ pkgs, ... }:

let
  manpager = (
    pkgs.writeShellScriptBin "manpager" ''
      cat "$1" | col -bx | bat --language man --style plain
    ''
  );
in
{
  home.packages = [
    pkgs.aws-sso-cli
    pkgs.awscli2
    pkgs.ssm-session-manager-plugin
    pkgs.bat
    pkgs.dig
    pkgs.fd
    pkgs.firefox
    pkgs.fzf
    pkgs.gh
    pkgs.ghostty
    pkgs.git
    pkgs.htop
    pkgs.jq
    pkgs.packer
    pkgs.ripgrep
    pkgs.tfswitch
    pkgs.tree
    pkgs.watch
    pkgs.which
    pkgs.whois
    pkgs.bridge-cli

    # Audio tools for microphone passthrough from macOS host
    pkgs.alsa-utils
    pkgs.sox
  ];

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";
  };
}
