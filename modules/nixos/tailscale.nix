{ config, lib, ... }:

let
  cfg = config.my.tailscale;
in
{
  options.my.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;
  };
}
