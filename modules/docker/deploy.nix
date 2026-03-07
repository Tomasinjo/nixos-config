{ pkgs, ... }:

let
  dockerAutodeployScript = pkgs.writeShellScriptBin "docker-auto-deploy" ''
    if [ "$(date +%w)" -ne 0 ]; then
        echo "Not Sunday, skipping deployment."
        exit 0
    fi

    cd /home/tom/nixos-config || exit 1

    # Fetch latest changes from remote
    git fetch origin master

    # Compare local main with remote main
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/master)

    # If they match, nothing to do!
    if [ "$LOCAL" = "$REMOTE" ]; then
        exit 0
    fi

    echo "Updates found! Pulling from GitHub..."
    # --ff-only prevents the script from hanging if there's a merge conflict
    git pull --ff-only origin master || {
        echo "Git pull failed! You might have uncommitted local changes."
        exit 1
    }

    # Find exactly which docker-compose files changed between the old and new commits
    CHANGED_FILES=$(git diff --name-only "$LOCAL" "$REMOTE" | grep "docker-compose.y*ml" || true)

    # Loop through changed files and deploy them
    for file in $CHANGED_FILES; do
        if [ -f "$file" ]; then
            echo "--> Updating container for: $file"
            docker compose -f "$file" up -d --remove-orphans
        fi
    done

    echo "Deployment complete."
  '';
in
{
  # Available in terminal as `docker-auto-deploy`
  environment.systemPackages = [ dockerAutodeployScript ];

  systemd.services.docker-auto-deploy = {
    description = "Auto pull and deploy Docker Compose updates after backup";
    wantedBy = [ "docker-backup.service" ]; # triggered after backup is finished
    after = [ "docker-backup.service" ];    # but after it is completed
    serviceConfig = {
      Type = "oneshot";
      User = "tom";
      WorkingDirectory = "/home/tom/nixos-config";
      ExecStart = "${dockerAutodeployScript}/bin/docker-auto-deploy";
    };
    path = with pkgs; [ git docker docker-compose openssh ];
  };

}
