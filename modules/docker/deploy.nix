{ config, pkgs, vars, ... }:

let
  deployScript = pkgs.writeShellScriptBin "nixos-auto-deploy" ''
    set -e

    echo "Starting NixOS auto-deploy..."

    # Run git pull as the user (tom) with proper PATH
    echo "Pulling latest changes from GitHub..."
    ${pkgs.git}/bin/git -C ${vars.dir.nixos_config} pull

    echo "Applying new NixOS configuration..."
    /run/wrappers/bin/sudo /run/current-system/sw/bin/nixos-rebuild switch --flake ${vars.dir.nixos_config}

    echo "NixOS auto-deploy completed successfully."
  '';

  # Script that runs after docker-backup and checks if it's Sunday
  sundayCheckScript = pkgs.writeShellScriptBin "nixos-deploy-sunday-check" ''
    if [ "$(date +%w)" -eq 0 ]; then
      echo "Today is Sunday - triggering NixOS auto-deploy..."
      systemctl start nixos-auto-deploy.service
    else
      echo "Not Sunday - skipping auto-deploy"
    fi
  '';
in
{
  environment.systemPackages = [ deployScript ];

  systemd.services.nixos-auto-deploy = {
    description = "Automatic NixOS deployment service";
    serviceConfig = {
      Type = "oneshot";
      User = "${vars.username}";
      Environment = "PATH=/etc/profiles/per-user/${vars.username}/bin:/run/current-system/sw/bin";
      ExecStart = "${deployScript}/bin/nixos-auto-deploy";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
  };

  systemd.services.nixos-auto-deploy-sunday = {
    description = "Check if Sunday and trigger NixOS auto-deploy after backup";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${sundayCheckScript}/bin/nixos-deploy-sunday-check";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
    wantedBy = [ "docker-backup.service" ];
    after = [ "docker-backup.service" ];
  };
}
