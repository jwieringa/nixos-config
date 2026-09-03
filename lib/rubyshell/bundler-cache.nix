# One Bundler install tree per toolchain, shared by every worktree that uses
# the same composed shell. Compiled gem extensions bake the exact /nix/store
# paths of libruby, libpq, ImageMagick, ... into their RUNPATH, so the tree is
# keyed by the Ruby version plus a hash over every store path the shell puts
# in scope. A nixpkgs bump changes those paths, changes the key, and Bundler
# installs into a fresh tree instead of loading stale extensions.
#
# Bundler installs only the gems missing from the current Gemfile.lock and
# reuses the rest, so worktrees with different lockfiles share one tree.
#
# Never run `bundle clean` against a shared tree; it deletes every gem that is
# not in the *current* lockfile. `bundle pristine` is the safe repair.
{
  ruby,
  deps ? [ ],
  cacheRoot ? "$HOME/.cache/bundler",
}:
let
  # toString on a list of derivations is the space-joined outPaths, which
  # tells libffi.dev apart from libffi.out.
  toolchain = toString ([ ruby ] ++ deps);
  key = "${ruby.version}-${builtins.substring 0 12 (builtins.hashString "sha256" toolchain)}";
in
{
  inherit key;

  # Bundler appends ruby/<ABI version> itself; the version prefix is for humans
  # browsing ~/.cache/bundler.
  shellHook = ''
    export BUNDLE_PATH="${cacheRoot}/${key}"
    mkdir -p "$BUNDLE_PATH"
    echo "bundler-cache key=${key} path=$BUNDLE_PATH"
    true
  '';
}
