{ config, lib, pkgs, ... }:

# TODO: Do I need/use sources.nix?
let sources = import ../../nix/sources.nix; in {
  # I don't know what this does yet, so I'm disabling it for now.
  #
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  # home.stateVersion = "18.09";

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs.bat
    pkgs.fd
    pkgs.fzf
    pkgs.htop
    pkgs.jq
    pkgs.ripgrep
    pkgs.tree
    pkgs.watch

    pkgs.go
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
  };

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];

    shellAliases = {
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      gp = "git push";
      gs = "git status";
      gt = "git tag";

      pbcopy = "xclip";
      pbpaste = "xclip -o";
    };
  };

  programs.direnv= {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "Jason Wieringa";
    userEmail = "jason@wieringa.io";
    # TODO: Add signing key
    # signing = {
    #   key = "";
    #   signByDefault = true;
    # };
    aliases = {
	    hist = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative # --all";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "jwieringa";
      push.default = "tracking";
      init.defaultBranch = "main";
    };
  };

  programs.go = {
    enable = true;
    goPath = "prj/go";
  };

  programs.vim = {
    enable = true;
  };
}
