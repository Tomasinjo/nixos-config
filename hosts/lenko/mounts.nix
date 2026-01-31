{ config, pkgs, ... }:

{

  fileSystems."/home/tom/zenki-home" = {
    device = "tom@zenki:/home/tom/";
    fsType = "fuse.sshfs";
    options = [
      # Standard SSH options
      "identityfile=/home/tom/.ssh/id_ed25519"
      "allow_other"         # Allows user access to the root-owned mount
      "default_permissions"
      
      # Connection reliability
      "reconnect"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
      
      # Systemd automount
      "x-systemd.automount" # Mount only when the directory is accessed
      "noauto"              # Don't mount immediately at boot
      "x-systemd.idle-timeout=3600" # Unmount after 1h of inactivity
      "x-systemd.mount-timeout=30"
    ];
  };

  # Allow non-root users to use 'allow_other'
  programs.fuse.userAllowOther = true;

  system.activationScripts.zenkiMountDir = ''
    mkdir -p /home/tom/zenki-home
    chown tom:users /home/tom/zenki-home
  '';

}
