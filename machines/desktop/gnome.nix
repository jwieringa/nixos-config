{ config, pkgs, lib, currentSystem, currentSystemName,... }: {
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  };

  # HiDPI scaling environment variables
  environment.variables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";  # Counteracts GDK_SCALE for fonts
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  };

  # Enable dconf for GNOME settings management
  programs.dconf.enable = true;
}
