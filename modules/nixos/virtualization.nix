{ config, lib, ... }:

let
  cfg = config.my.virtualization;
in
{
  options.my.virtualization = {
    docker.enable = lib.mkEnableOption "Docker";
    lxd.enable = lib.mkEnableOption "LXD";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.docker.enable {
      virtualisation.docker.enable = true;
    })
    (lib.mkIf cfg.lxd.enable {
      virtualisation.lxd.enable = true;
    })
  ];
}
