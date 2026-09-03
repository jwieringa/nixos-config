# Composable dev shells for the Rails apps (Iris, kracken).
#
# Scope: Ruby applications backed by PostgreSQL. Every project shell gets the
# Ruby and PostgreSQL layers; the rest are opt-in per project. Other
# databases are out of scope for now, so Captain (MySQL) still uses
# flakes/ruby-ror-with-mysql.
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
    let
      ruby = nixpkgs-ruby.lib.mkRuby {
        inherit pkgs;
        rubyVersion = version;
      };
    in
    # Ruby before 3.2 does not compile with GCC 15, whose default dialect is
    # C23: Onigmo's headers clash with "conflicting types for
    # onig_jis_property". Building those versions as gnu17 restores the
    # dialect GCC 14 used. nixpkgs-ruby pins nixos-25.05 upstream, so its CI
    # never sees GCC 15 and no fix is coming from there. 3.2 and later build
    # unmodified.
    if lib.versionOlder version "3.2" then
      ruby.overrideAttrs (old: {
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "") + " -std=gnu17";
        };
      })
    else
      ruby;

  layers = import ./layers.nix { inherit pkgs; };
  bundlerCache = import ./bundler-cache.nix;

  # Compose a project shell from a Ruby version and its extra layers, with a
  # Bundler install tree shared by every worktree on the same toolchain.
  mkRailsShell =
    {
      project,
      rubyVersion,
      include ? [ ],
    }:
    let
      ruby = rubyFor rubyVersion;
      allLayers = [
        (layers.ruby ruby)
        layers.postgres
      ]
      ++ include;
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
