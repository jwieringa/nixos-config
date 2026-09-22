{ config, lib, ... }:

let
  pluginCacheDir = "${config.home.homeDirectory}/.terraform.d/plugin-cache";
in
{
  home.file.".tfswitch.toml".text = ''
    bin = "/opt/terraform/bin/terraform"
    install = "/opt/terraform/versions"
    product = "terraform"
  '';

  # Share provider binaries across every project instead of downloading a
  # copy into each .terraform directory. This lives in the CLI config file
  # rather than TF_PLUGIN_CACHE_DIR because Terraform reads ~/.terraformrc
  # unconditionally, whereas the environment variable only reaches shells
  # started after a home-manager activation. That gap silently turned the
  # cache off for three weeks and left 11G of duplicated providers behind.
  home.file.".terraformrc".text = ''
    plugin_cache_dir = "${pluginCacheDir}"
  '';

  # Terraform will not create the cache directory itself.
  home.activation.terraformPluginCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${pluginCacheDir}"
  '';
}
