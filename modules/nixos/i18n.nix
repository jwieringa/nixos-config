{ config, lib, ... }:

let
  cfg = config.my.i18n;
in
{
  options.my.i18n = {
    enable = lib.mkEnableOption "internationalisation";
  };

  config = lib.mkIf cfg.enable {
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
