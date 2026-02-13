{ config, pkgs, lib, ... }:

let
  # Define the package from GitHub
  nvidia-fan-control = pkgs.buildGoModule rec {
    pname = "nvidia-fan-control";
    version = "2026-02-06"; # date of commit

    src = pkgs.fetchFromGitHub {
      owner = "ZanMax";
      repo = "nvidia-fan-control";
      rev = "7f2315d3eb6af952f88c53168052bb5feed9e019"; # specific commit
      sha256 = "sha256-eNb/H1cQvSXAv853Jkylj/Ew6YaTRsVUY/GzsPC+Evw="; 
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

  fanConfig = builtins.toJSON {
    time_to_update = 5;
    temperature_ranges = [
      { min_temperature = 0; max_temperature = 35; fan_speed = 0; hysteresis = 3; }
      { min_temperature = 35; max_temperature = 55; fan_speed = 30; hysteresis = 3; }
      { min_temperature = 55; max_temperature = 400; fan_speed = 100; hysteresis = 5; }
    ];
  };

in {
#  hardware.nvidia.enable = true;
  environment.etc."nvidia-fan-control/config.json".text = fanConfig;

  systemd.services.nvidia-fan-control = {
    description = "NVIDIA Fan Control Service";
    after = [ "network.target" "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];

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
