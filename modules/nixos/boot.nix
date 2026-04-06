{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.boot;
in
{
  options.my.boot = {
    enable = lib.mkEnableOption "boot configuration";
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = pkgs.linuxPackages_latest;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 3;

    # VMware, Parallels both only support this being 0 otherwise you see
    # "error switching console mode" on boot.
    boot.loader.systemd-boot.consoleMode = "0";
  };
}
