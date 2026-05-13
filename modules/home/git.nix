{ ... }:

{
  programs.git = {
    enable = true;
    userName = "Jason Wieringa";
    userEmail = "jason@wieringa.io";
    aliases = {
      clean = "!git branch --merged | grep  -v '\\*\\|main' | xargs -n 1 -r git branch -d";
      hist = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    ignores = [
      "vendor/bundle"
      ".envrc"
      ".direnv/"
      ".worktrees"
    ];
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
}
