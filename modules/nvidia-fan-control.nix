{ config, pkgs, lib, ... }:

let
  
  ##########################
  #  Custom GPU fan curve  #
  ##########################
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
      { min_temperature = 35; max_temperature = 50;  fan_speed = 30;  hysteresis = 3; }
      { min_temperature = 50; max_temperature = 65;  fan_speed = 75;  hysteresis = 3; }
      { min_temperature = 65; max_temperature = 400; fan_speed = 100; hysteresis = 3; }
    ];
  };

  # helper to use for both the file and the trigger
  configFile = pkgs.writeText "nvidia-fan-config.json" (builtins.toJSON fanConfigData);


  ######################################################
  # Script controls case fan, same speed as GPU fan    #
  ######################################################
  nvidia-fan-control-bash = pkgs.writeShellApplication {
    name = "nvidia-pwm4-control";
    runtimeInputs = [ pkgs.jq config.hardware.nvidia.package pkgs.coreutils ];
    text = ''
      CONFIG_PATH="/etc/nvidia-fan-control/config.json"
      PWM_PATH="/sys/class/hwmon/hwmon10/pwm4"
      ENABLE_PATH="/sys/class/hwmon/hwmon10/pwm4_enable"

      cleanup() {
          echo "Exiting: Restoring fan control to motherboard (fallback mode 5)..."
          echo 5 > "$ENABLE_PATH" || true
          exit
      }
      trap cleanup EXIT SIGINT SIGTERM

      [[ ! -f "$CONFIG_PATH" ]] && echo "Config not found" && exit 1
      echo 1 > "$ENABLE_PATH"

      while true; do
          TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null || echo "error")
          
          if [[ "$TEMP" =~ ^[0-9]+$ ]]; then
              # Use --argjson for numeric comparison
              FAN_VALUE=$(jq -r --argjson temp "$TEMP" '
                  .temperature_ranges[] | 
                  select($temp >= .min_temperature and $temp < .max_temperature) | 
                  .fan_speed
              ' "$CONFIG_PATH" | head -n 1)

              if [ -n "$FAN_VALUE" ] && [ "$FAN_VALUE" != "null" ]; then
                  [[ "$FAN_VALUE" -gt 255 ]] && FAN_VALUE=255
                  [[ "$FAN_VALUE" -lt 0 ]] && FAN_VALUE=0
                  echo "$FAN_VALUE" > "$PWM_PATH"
              fi
          fi

          UPDATE_INTERVAL=$(jq -r '.time_to_update' "$CONFIG_PATH")
          sleep "''${UPDATE_INTERVAL:-5}"
      done
    '';
  };


in {
  environment.etc."nvidia-fan-control/config.json".source = configFile;
  
  # runs the program that implements custom GPU fan curve 
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

  # runs the bash script that controls case fan according to config
  systemd.services.nvidia-pwm4-control = {
    description = "NVIDIA GPU PWM4 Fan Control (Bash)";
    after = [ "network.target" "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ configFile ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${nvidia-fan-control-bash}/bin/nvidia-pwm4-control";
      StandardOutput = "journal";
      StandardError = "journal";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };
}
