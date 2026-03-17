{ pkgs, vars, ... }:

let
  nixosAutodeployScript = pkgs.writeShellScriptBin "nixos-auto-deploy" ''
    # Only run on Sunday (0)
    if [ "$(date +%w)" -ne 0 ]; then
        echo "Not Sunday, skipping deployment."
        exit 0
    fi

    cd ${vars.dir.nixos_config} || exit 1

    # Fetch latest changes from remote
    git fetch origin master

    # Compare local branch with remote branch
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/master)

    # If they match, nothing to do!
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "System is up to date."
        exit 0
    fi

    echo "Updates found! Pulling from GitHub..."
    # --ff-only prevents the script from hanging if there's a merge conflict
    git pull --ff-only origin master || {
        echo "Git pull failed! You might have uncommitted local changes."
        exit 1
    }

    echo "--> Rebuilding NixOS..."
    
    # Run the rebuild. (Add `--flake .` or `--flake .#hostname` if you use flakes)
    sudo nixos-rebuild switch

    echo "Deployment complete."
  '';
in
{
  environment.systemPackages = [ nixosAutodeployScript ];

  systemd.services.nixos-auto-deploy = {
    description = "Auto pull and rebuild NixOS after backup";
    wantedBy = [ "docker-backup.service" ]; # triggered after backup is finished
    after = [ "docker-backup.service" ];    # but after it is completed
    serviceConfig = {
      Type = "oneshot";
      User = vars.username;
      WorkingDirectory = vars.dir.nixos_config;
      ExecStart = "${nixosAutodeployScript}/bin/nixos-auto-deploy";
    };
    path = with pkgs; [ git openssh sudo nix ];
  };
}