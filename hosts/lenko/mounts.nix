{ config, pkgs, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  fileSystems."/home/tom/zenki-home" = {
    device = secrets.zenki.ssh.home;
    fsType = "fuse.sshfs";
    options = [
      # Standard SSH options
      "identityfile=/home/tom/.ssh/id_ed25519"
      "allow_other"         # Allows user access to the root-owned mount
      "default_permissions"
      
      # one or more cause issues. This was attempt to better handle instable network
#      "_netdev"              # Marks it as a network device (prevents hangs during boot/shutdown)
#      "intr"                 # Allows operations to be interrupted if they hang
#      "ConnectTimeout=5"     # Don't wait forever to establish connection

      # Connection reliability
      "reconnect"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
      
      # Systemd automount
      "x-systemd.automount" # Mount only when the directory is accessed
      "noauto"              # Don't mount immediately at boot
      "x-systemd.idle-timeout=600" # Unmount after 10 min of inactivity
      "x-systemd.mount-timeout=10"
    ];
  };

  # Allow non-root users to use 'allow_other'
  programs.fuse.userAllowOther = true;

  system.activationScripts.zenkiMountDir = ''
    mkdir -p /home/tom/zenki-home
    chown tom:users /home/tom/zenki-home
  '';

}
