{ config, lib, ... }:

let
  cfg = config.my.networking;
in
{
  options.my.networking = {
    enable = lib.mkEnableOption "networking configuration";
  };

  config = lib.mkIf cfg.enable {
    networking.hostName = "dev";
    networking.useDHCP = false;
    networking.firewall.enable = false;

    time.timeZone = "Etc/UTC";
  };
}
