{
  config,
  lib,
  pkgs,
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
    # The session is Wayland, but this stays on: the VMware guest module
    # defaults `headless` to `!services.xserver.enable`, and headless
    # open-vm-tools drops the host clipboard integration.
    services.xserver = {
      enable = true;
      xkb.layout = "us";
    };

    # GNOME 50 is Wayland-only; the former `gdm.wayland` option was removed.
    # Mutter hands every client the monitor scale, so no GDK_SCALE or
    # similar HiDPI variables are needed.
    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;

    # Run Chromium and Electron apps (1Password) natively on Wayland instead
    # of upscaled through XWayland.
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # This is a dev VM; skip the file indexer and the stock apps it never uses.
    services.gnome.localsearch.enable = false;
    services.gnome.tinysparql.enable = false;
    environment.gnome.excludePackages = with pkgs; [
      decibels
      epiphany
      geary
      gnome-calendar
      gnome-clocks
      gnome-connections
      gnome-contacts
      gnome-maps
      gnome-music
      gnome-tour
      gnome-user-docs
      gnome-weather
      orca
      showtime
      simple-scan
      snapshot
      yelp
    ];

    # Enable dconf for GNOME settings management
    programs.dconf.enable = true;
  };
}
