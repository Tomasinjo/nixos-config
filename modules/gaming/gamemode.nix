{ config, pkgs, vars, ... }:

let
  gameStart = pkgs.writeShellScriptBin "game-start" ''
    /run/current-system/sw/bin/systemctl stop docker-ollama.service
  '';

  gameEnd = pkgs.writeShellScriptBin "game-end" ''
    /run/current-system/sw/bin/systemctl start docker-ollama.service
  '';
in
{
  # Add scripts to PATH
  environment.systemPackages = [ gameStart gameEnd ];

  # Configure GameMode to use these scripts
  programs.gamemode.enable = true;
  programs.gamemode.settings = {
    # Disable ioprio optimization (causes errors on this system)
    general = {
      ioprio = "off";
      inhibit_screensaver = 0;
      disable_splitlock = 0;  # Disable split lock mitigation (requires pkexec)
    };
    # Disable CPU pinning (not needed for this system)
    cpu = {
      pin_cores = "no";
      park_cores = "no";
    };
    # Custom scripts for docker-ollama service management
    custom = {
      start = "${gameStart}/bin/game-start";
      end = "${gameEnd}/bin/game-end";
    };
  };

  # Polkit rule to allow gamemode's cpugovctl and procsysctl to run without password
  # Also allow starting/stopping docker-ollama.service for game mode scripts
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "com.feralinteractive.GameMode.governor-helper" ||
           action.id == "com.feralinteractive.GameMode.procsys-helper") &&
          subject.user == "${vars.username}") {
        return polkit.Result.YES;
      }
    });
    
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.user == "${vars.username}") {
        var verb = action.lookup("verb");
        var unit = action.lookup("unit");
        if (unit == "docker-ollama.service" && (verb == "start" || verb == "stop" || verb == "restart")) {
          return polkit.Result.YES;
        }
      }
    });
  '';

  security.sudo.extraRules = [
    {
      users = [ vars.username ];
      commands = [
       { command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference"; options = [ "NOPASSWD" ]; }  # this allows changing the file without password for user
      ];
    }
  ];
}
