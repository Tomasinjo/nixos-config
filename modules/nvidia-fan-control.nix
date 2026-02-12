{ config, pkgs, lib, ... }:

let
  nvidia-fan-control = pkgs.buildGoModule rec {
    pname = "nvidia-fan-control";
    version = "main";

    src = pkgs.fetchFromGitHub {
      owner = "ZanMax";
      repo = "nvidia-fan-control";
      rev = "main";
      hash = "sha256-2558crqhdYW9PY5Nd2hskjBTiotR9nj0ZjAHyM/l/vo="; 
    };

    vendorHash = "sha256-2558crqhdYW9PY5Nd2hskjBTiotR9nj0ZjAHyM/l/vo=";
    doCheck = false;

    # Using the modern hook
    nativeBuildInputs = [ pkgs.addDriverRunpath ];


    # Force compilation to look at your actual driver version
    buildInputs = [ config.hardware.nvidia.package ];
  };

  fanConfig = {
    time_to_update = 5;
    temperature_ranges = [
      { min_temperature = 0;   max_temperature = 40;  fan_speed = 30;  hysteresis = 3; }
      { min_temperature = 40;  max_temperature = 60;  fan_speed = 40;  hysteresis = 3; }
      { min_temperature = 60;  max_temperature = 80;  fan_speed = 70;  hysteresis = 3; }
      { min_temperature = 80;  max_temperature = 100; fan_speed = 100; hysteresis = 3; }
      { min_temperature = 100; max_temperature = 200; fan_speed = 100; hysteresis = 0; }
    ];
  };

  configFile = pkgs.writeText "config.json" (builtins.toJSON fanConfig);

in {
  systemd.services.nvidia-fan-control = {
    description = "NVIDIA Fan Control Service";
    after = [ "network.target" "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      # Use the direct path to the binary
      ExecStart = "${nvidia-fan-control}/bin/nvidia-fan-control";
      
      RuntimeDirectory = "nvidia_fan_control";
      WorkingDirectory = "/run/nvidia_fan_control";
      
      ExecStartPre = pkgs.writeShellScript "setup-nvidia-fan-config" ''
        ln -sf ${configFile} /run/nvidia_fan_control/config.json
      '';

      Restart = "always";
      User = "root";

      # LOGGING: Helps us see exactly what's failing
      StandardOutput = "journal";
      StandardError = "journal";
    };

    # CRITICAL FIX: Tell the service EXACTLY where to find the real driver
    environment = {
      LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/opengl-driver-32/lib";
    };
  };
}
