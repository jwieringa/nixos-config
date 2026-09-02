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
  # copy into each .terraform directory.
  home.sessionVariables.TF_PLUGIN_CACHE_DIR = pluginCacheDir;

  # Terraform will not create the cache directory itself.
  home.activation.terraformPluginCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${pluginCacheDir}"
  '';
}
