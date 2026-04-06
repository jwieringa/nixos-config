{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.nix;
in
{
  options.my.nix = {
    enable = lib.mkEnableOption "Nix daemon configuration";
  };

  config = lib.mkIf cfg.enable {
    nix = {
      package = pkgs.nixVersions.latest;
      extraOptions = ''
        experimental-features = nix-command flakes
        keep-outputs = true
        keep-derivations = true
      '';

      settings = {
        substituters = [
          "https://jwieringa-nixos-config.cachix.org"
        ];
        trusted-public-keys = [
          "jwieringa-nixos-config.cachix.org-1:ZR2Yfx0c9A6EQ+i94lgIOwma7LxVIx4eEMEKu5KrX4w="
        ];
      };
    };
  };
}
