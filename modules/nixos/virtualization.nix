{ config, lib, ... }:

let
  cfg = config.my.virtualization;
in
{
  options.my.virtualization = {
    docker.enable = lib.mkEnableOption "Docker";
  };

  config = lib.mkIf cfg.docker.enable {
    virtualisation.docker.enable = true;
  };
}
