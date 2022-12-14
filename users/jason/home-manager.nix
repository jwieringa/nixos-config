{ config, lib, pkgs, ... }:

# TODO: Do I need/use sources.nix?
let sources = import ../../nix/sources.nix; in {
  home.stateVersion = "22.11";

  # xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs.which
    pkgs.bat
    pkgs.fd
    pkgs.fzf
    pkgs.htop
    pkgs.jq
    pkgs.tree
    pkgs.watch
    pkgs.git
    pkgs.tfswitch
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "vim";
    PAGER = "less -FirSwX";
    MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
  };

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
# Credit: https://github.com/mitchellh/nixos-config/blob/9015bdc23b6b372abcad709c0b0e3c59820c5a54/users/mitchellh/config.fish

#-------------------------------------------------------------------------------
# SSH Agent
#-------------------------------------------------------------------------------
function __ssh_agent_is_started -d "check if ssh agent is already started"
    if begin; test -f $SSH_ENV; and test -z "$SSH_AGENT_PID"; end
        source $SSH_ENV > /dev/null
    end
    
    if test -z "$SSH_AGENT_PID"
        return 1
    end
    
    ssh-add -l > /dev/null 2>&1
        if test $status -eq 2
        return 1
    end
end

function __ssh_agent_start -d "start a new ssh agent"
    ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
    chmod 600 $SSH_ENV
    source $SSH_ENV > /dev/null
    ssh-add
end

if not test -d $HOME/.ssh
    mkdir -p $HOME/.ssh
    chmod 0700 $HOME/.ssh
end

if test -d $HOME/.gnupg
    chmod 0700 $HOME/.gnupg
end

if test -z "$SSH_ENV"
    set -xg SSH_ENV $HOME/.ssh/environment
end

if not __ssh_agent_is_started
    __ssh_agent_start
end

#-------------------------------------------------------------------------------
# nixos
#-------------------------------------------------------------------------------

set -l nix_shell_info (
  if test -n "$IN_NIX_SHELL"
    echo -n "<nix-shell> "
  end
)
    '';

  };

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
      hist = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
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

  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-airline
      vim-terraform
      vim-nix
      vim-markdown
      nerdtree
      vim-gitgutter
    ];
    settings = { ignorecase = true; };
    extraConfig = ''
" General Settings
set nocompatible          " Running Vim, not Vi
set number                " Always show line numbers

" Status Bar
set statusline=%t\ %r\ %y\ format:\ %{&ff};\ [%c,%l]  " Format statusbar http://vim.runpaint.org/display/changing-status-line/

" NerdTREE settings
let NERDTreeShowHidden=1             " Show hidden files

" " Mappings
let mapleader = ","                  " Set leader key
map <leader>nt :NERDTree<CR>         " Set NERDTree shortcut
map <leader>ev :e $MYVIMRC<CR>       " Quickly edit the vimrc file
map <leader>sv :so $MYVIMRC<CR>      " Quickly reload the vimrc file
map <leader>cs :noh<cr>
    '';
  };
}
