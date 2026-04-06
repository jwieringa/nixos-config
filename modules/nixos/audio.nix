{ config, lib, ... }:

let
  cfg = config.my.audio;
in
{
  options.my.audio = {
    enable = lib.mkEnableOption "audio via PipeWire";
  };

  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };
}
