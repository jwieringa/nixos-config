{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.i18n;
in
{
  options.my.i18n = {
    enable = lib.mkEnableOption "internationalisation";
  };

  config = lib.mkIf cfg.enable {
    i18n = {
      defaultLocale = "en_US.UTF-8";
      inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5.addons = with pkgs; [
          fcitx5-gtk
        ];
      };
    };
  };
}
