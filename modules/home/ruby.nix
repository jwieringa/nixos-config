{ config, lib, ... }:

let
  bundlerCacheDir = "${config.home.homeDirectory}/.cache/bundler";
in
{
  # Global Bundler defaults. The nixos-config#<project>-<ruby> shells export
  # BUNDLE_PATH into ${bundlerCacheDir}/<key>, and an environment variable
  # outranks this file, so the path here only catches shells that have not
  # been migrated. A project-local .bundle/config outranks both, which is why
  # the app repos must not carry one. `clean: false` keeps `bundle install`
  # from pruning gems other worktrees still need from the shared tree.
  #
  # The file is a read-only symlink into the store, so
  # `bundle config set --global ...` fails. Edit this module instead.
  home.file.".bundle/config".text = ''
    ---
    BUNDLE_PATH: "vendor/bundle"
    BUNDLE_CLEAN: "false"
    BUNDLE_FROZEN: "true"
    BUNDLE_WITHOUT: "rubocop:ruby-lsp"
  '';

  # Create the shared root up front so it is there to inspect before the
  # first install.
  home.activation.bundlerCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${bundlerCacheDir}"
  '';
}
