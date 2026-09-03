# Composable dev shells for the Rails apps (Iris, Captain, kracken).
#
# A layer is a small mkShell that owns one concern: a service plus its
# autostart hook, or a native library plus the variables a gem's extconf.rb
# needs. A project shell is `mkShell { inputsFrom = layers; }`, which merges
# the package lists and concatenates the hooks. The app repos carry no Nix
# files; their .envrc points at `nixos-config#<project>-<ruby_version>`.
{ pkgs, nixpkgs-ruby }:
let
  inherit (pkgs) lib;

  # Build Ruby against our pkgs rather than letting nixpkgs-ruby import
  # nixpkgs a second time. With `follows` both yield the same store path.
  rubyFor =
    version:
    nixpkgs-ruby.lib.mkRuby {
      inherit pkgs;
      rubyVersion = version;
    };

  layers = import ./layers.nix { inherit pkgs; };
  bundlerCache = import ./bundler-cache.nix;

  # Compose a project shell from a Ruby version and a list of layers, with a
  # Bundler install tree shared by every worktree on the same toolchain.
  mkRailsShell =
    {
      project,
      rubyVersion,
      include,
    }:
    let
      ruby = rubyFor rubyVersion;
      allLayers = [ (layers.ruby ruby) ] ++ include;
      cache = bundlerCache {
        inherit ruby;
        # Hash the layers' inputs, not the composed shell's own buildInputs:
        # the hook below is part of that derivation, so reading its
        # attributes here would recurse infinitely.
        deps = lib.concatMap (l: l.buildInputs ++ l.nativeBuildInputs) allLayers;
      };
    in
    pkgs.mkShell {
      name = "${project}-${rubyVersion}";
      inputsFrom = allLayers;
      # mkShell appends this after every layer hook.
      shellHook = cache.shellHook;
      passthru.bundlerCacheKey = cache.key;
    };

  projects = import ./projects.nix { inherit lib layers mkRailsShell; };
in
{
  inherit layers mkRailsShell projects;
}
