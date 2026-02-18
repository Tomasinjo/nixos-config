{ config, pkgs, ... }:

let
  # Script to run when game starts
  gameStart = pkgs.writeShellScriptBin "game-start" ''
    # Set CPU to Max Performance
    echo "performance" | sudo ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
    
    # Stop Ollama (frees up CPU and VRAM)
    ${pkgs.docker}/bin/docker stop ollama || true
  '';

  # Script to run when game ends
  gameEnd = pkgs.writeShellScriptBin "game-end" ''
    # Set CPU back to power (lowest performance)
    echo "power" | sudo ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
    
    # Restart Ollama
    ${pkgs.docker}/bin/docker start ollama || true
  '';
in
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true; # Useful for HDR or upscaling
  };
  hardware.graphics.enable32Bit = true;

  # Add scripts to PATH
  environment.systemPackages = [ gameStart gameEnd ];

  # Configure GameMode to use these scripts
  programs.gamemode.enable = true;
  programs.gamemode.settings = {
    custom = {
      start = "${gameStart}/bin/game-start";
      end = "${gameEnd}/bin/game-end";
    };
  };
}
