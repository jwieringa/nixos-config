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

    # Resolve through systemd-resolved using DNS-over-TLS to Quad9. The
    # empty fallback list keeps resolved from silently falling back to
    # its compiled-in plaintext servers when Quad9 is unreachable.
    networking.nameservers = [
      "9.9.9.9#dns.quad9.net"
      "149.112.112.112#dns.quad9.net"
    ];
    services.resolved = {
      enable = true;
      dnsovertls = "true";
      fallbackDns = [ ];
    };

    time.timeZone = "Etc/UTC";
  };
}
