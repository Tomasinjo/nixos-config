{ config, pkgs, vars, ... }:

{
  fileSystems."${vars.dir.home}/${vars.networking.zenki.hostname}-home" = {
    device = "${vars.username}@${vars.networking.zenki.fqdn}:${vars.dir.home}/"; # if it doesnt mount, run sudo ssh... to add it to root's known hosts
    fsType = "fuse.sshfs";
    options = [
      # Standard SSH options
      "identityfile=${vars.dir.home}/.ssh/id_ed25519"
      "allow_other"         # Allows user access to the root-owned mount
      "default_permissions"
      
      # Connection reliability
      "reconnect"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
      
      # Systemd automount
      "x-systemd.automount" # Mount only when the directory is accessed
      "noauto"              # Don't mount immediately at boot
      "x-systemd.idle-timeout=600" # Unmount after 10 min of inactivity
      "x-systemd.mount-timeout=30"
    ];
  };

  # Allow non-root users to use 'allow_other'
  programs.fuse.userAllowOther = true;

  system.activationScripts.zenkiMountDir = ''
    mkdir -p ${vars.dir.home}/${vars.networking.zenki.hostname}-home
    chown ${vars.username}:users ${vars.dir.home}/${vars.networking.zenki.hostname}-home
  '';

}
