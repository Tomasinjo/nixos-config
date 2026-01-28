{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    (writeShellScriptBin "ud" ''
    STACKS=(
        "/home/tom/apps"
        "/home/tom/apps/arrs"
        "/home/tom/apps/ha"
        "/home/tom/apps/immich"
        "/home/tom/apps/nextcloud"
        "/home/tom/apps/nvr"
        "/home/tom/apps/paperless"
        "/home/tom/apps/unifi"
        "/home/tom/apps/searxng"
    )

    for STACK in "''${STACKS[@]}"; do
        if [ -d "$STACK" ]; then
            echo "Processing stack in $STACK"
            cd "$STACK" || continue
            
            echo "Pulling the latest images..."
            ${pkgs.docker}/bin/docker compose pull
            
            echo "Bringing up the services..."
            ${pkgs.docker}/bin/docker compose up -d
        else
            echo "Directory $STACK does not exist, skipping..."
        fi
    done

    echo "Pruning unused Docker images..."
    ${pkgs.docker}/bin/docker image prune -a -f

    echo "Script execution completed."
    '')
  ];
}