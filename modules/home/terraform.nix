{ ... }:

{
  home.file.".tfswitch.toml".text = ''
    bin = "/opt/terraform/bin/terraform"
    install = "/opt/terraform/versions"
    product = "terraform"
  '';
}
