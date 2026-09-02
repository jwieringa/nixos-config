{ ... }:

{
  programs.direnv = {
    enable = true;
    # Every project shell now evaluates the whole nixos-config flake; cache
    # the result per directory instead of re-running nix on each cd.
    nix-direnv.enable = true;
  };
}
