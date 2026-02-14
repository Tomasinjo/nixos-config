{ config, pkgs, lib, ... }:

let
  # Define the package from GitHub
  nvidia-fan-control = pkgs.buildGoModule rec {
    pname = "nvidia-fan-control";
    version = "2026-02-06"; # date of commit

    src = pkgs.fetchFromGitHub {
      owner = "ZanMax";
      repo = "nvidia-fan-control";
      rev = "refs/pull/12/head"; # my pull request, change when merged.
      sha256 = "sha256-OeqbRvagxpWff/Ff3vWGayCcmJh6wKPh22TyP+lENQc="; 
    };

    vendorHash = "sha256-2558crqhdYW9PY5Nd2hskjBTiotR9nj0ZjAHyM/l/vo="; 

    ldflags = [ "-extldflags=-Wl,-z,lazy" ];   # fix for error: undefined symbol: nvmlGpuInstanceGetComputeInstanceProfileInfoV
    buildInputs = [ config.hardware.nvidia.package ];
    
    nativeBuildInputs = [ pkgs.makeWrapper ];

    postInstall = ''
      wrapProgram $out/bin/nvidia-fan-control \
        --prefix LD_LIBRARY_PATH : "${config.hardware.nvidia.package}/lib"
    '';
  };

  fanConfigData = {
    time_to_update = 5;
    temperature_ranges = [
      { min_temperature = 0;  max_temperature = 35;  fan_speed = 0;   hysteresis = 3; }
      { min_temperature = 35; max_temperature = 55;  fan_speed = 30;  hysteresis = 5; }
      { min_temperature = 55; max_temperature = 400; fan_speed = 100; hysteresis = 5; }
    ];
  };

  # helper to use for both the file and the trigger
  configFile = pkgs.writeText "nvidia-fan-config.json" (builtins.toJSON fanConfigData);

in {
  environment.etc."nvidia-fan-control/config.json".source = configFile;

  systemd.services.nvidia-fan-control = {
    description = "NVIDIA Fan Control Service";
    after = [ "network.target" "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ configFile ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${nvidia-fan-control}/bin/nvidia-fan-control";
      WorkingDirectory = "/etc/nvidia-fan-control";
      StandardOutput = "journal";
      StandardError = "journal";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };
}
