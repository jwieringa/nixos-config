{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStrings (
      lib.strings.intersperse "\n" ([
        "source ${inputs.theme-bobthefish}/functions/fish_prompt.fish"
        "source ${inputs.theme-bobthefish}/functions/fish_right_prompt.fish"
        "source ${inputs.theme-bobthefish}/functions/fish_title.fish"
        "set -g SHELL ${pkgs.fish}/bin/fish"
        "set -gx PATH /opt/terraform/bin $PATH"
      ])
    );

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

    plugins =
      map
        (n: {
          name = n;
          src = inputs.${n};
        })
        [
          "fish-fzf"
          "fish-foreign-env"
          "theme-bobthefish"
        ];
  };
}
