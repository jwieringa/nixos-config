{ inputs, ... }:

{ config, lib, pkgs, ... }:

let
  sources = import ../../nix/sources.nix;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (pkgs.writeShellScriptBin "manpager" ''
    cat "$1" | col -bx | bat --language man --style plain
  '');
in {
  xdg.enable = true;

  home.stateVersion = "24.11";

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages installed in the OS available to all projects
  home.packages = [
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
    MANPAGER = "${manpager}/bin/manpager";
  };

  xdg.configFile = {
  };

  # GNOME dconf settings
  dconf.settings = {
    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = lib.hm.gvariant.mkUint32 14400; # 4 hours in seconds
    };
    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 14400; # 4 hours in seconds
    };

    # HiDPI scaling settings
    "org/gnome/desktop/interface" = {
      scaling-factor = lib.hm.gvariant.mkUint32 2;
      text-scaling-factor = 1.0;
    };
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
  };

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" ([
      "source ${sources.theme-bobthefish}/functions/fish_prompt.fish"
      "source ${sources.theme-bobthefish}/functions/fish_right_prompt.fish"
      "source ${sources.theme-bobthefish}/functions/fish_title.fish"
      # (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
      "set -gx PATH /opt/terraform/bin $PATH"
    ]));

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
    };

    plugins = map (n: {
      name = n;
      src  = sources.${n};
    }) [
      "fish-fzf"
      "fish-foreign-env"
      "theme-bobthefish"
    ];
  };

  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
  };

  programs.direnv= {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "Jason Wieringa";
    userEmail = "jason@wieringa.io";
    aliases = {
      clean = "!git branch --merged | grep  -v '\\*\\|main' | xargs -n 1 -r git branch -d";
      hist = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    ignores = [];
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      core.excludesFile = "~/.gitignore_global";
      credential.helper = "store"; # want to make this more secure
      github.user = "jwieringa";
      push.default = "tracking";
      init.defaultBranch = "main";
    };
  };

  programs.go = {
    enable = true;
    goPath = "code/go";
  };
  
  # Add tfswitch configuration file
  home.file.".tfswitch.toml".text = ''
    bin = "/opt/terraform/bin/terraform"
    install = "/opt/terraform/versions"
    product = "terraform"
  '';

  programs.neovim = {
    enable = true;
    vimAlias = true;

    withPython3 = true;

    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects
      conform-nvim
      gitsigns-nvim
      lualine-nvim
    ];

    extraConfig = (import ./vim-config.nix) { inherit sources; };
  };

  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-tty;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };
}
