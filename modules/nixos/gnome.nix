{
  config,
  lib,
  ...
}:

let
  cfg = config.my.gnome;
in
{
  options.my.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      xkb.layout = "us";
    };

    # GNOME 50 is Wayland-only; the former `gdm.wayland` option was removed.
    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;

    # HiDPI scaling environment variables
    environment.variables = {
      GDK_SCALE = "2";
      GDK_DPI_SCALE = "0.5"; # Counteracts GDK_SCALE for fonts
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    };

    # Enable dconf for GNOME settings management
    programs.dconf.enable = true;
  };
}
