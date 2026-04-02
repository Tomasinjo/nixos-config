{ config, pkgs, inputs, vars, ... }:

{
  users.users.${vars.username}.extraGroups = [ 
      "audio"
    ];

  security.rtkit.enable = true; # PulseAudio and PipeWire use this to acquire realtime priority.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
}
