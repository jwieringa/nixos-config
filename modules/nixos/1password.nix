{
  config,
  lib,
  pkgs,
  currentSystemUser,
  ...
}:

let
  cfg = config.my.onepassword;
in
{
  options.my.onepassword = {
    enable = lib.mkEnableOption "1Password";
  };

  config = lib.mkIf cfg.enable {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ currentSystemUser ];
    };
  };
}
