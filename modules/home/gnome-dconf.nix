{ lib, ... }:

{
  dconf.settings = {
    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = lib.hm.gvariant.mkUint32 14400; # 4 hours in seconds
    };
    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 14400; # 4 hours in seconds
    };

    # HiDPI scaling settings
    "org/gnome/desktop/interface" = {
      scaling-factor = lib.hm.gvariant.mkUint32 2;
      text-scaling-factor = 1.0;
    };
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };

    # Mutter starts Xwayland with -enable-ei-portal, so any X11 client that
    # injects input through XTest (open-vm-tools' vmusr does) pops GNOME's
    # "Remote Desktop / Allow Remote Interaction" dialog at login. Nothing
    # here needs XTest; clipboard sync uses X selections, not XTest.
    "org/gnome/mutter/wayland" = {
      xwayland-disable-extension = [ "Xtest" ];
    };
  };
}
