{ config, pkgs, inputs, vars, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/common.nix
    ../../modules/shell.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/sudo.nix
#    ../../modules/docker/init_base.nix
    ../../modules/utilities.nix
#    ../../modules/printing.nix
#    ../../modules/virtual-machines/virt-manager.nix
    ../../modules/wireshark.nix
    ../../modules/ssh.nix
#    ./intune.nix
  ];


  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Gnome keyring daemon for secrets management
  services.gnome.gnome-keyring.enable = true;

  hardware.bluetooth.enable = true;
  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs; [
    ntfs3g
    dnsmasq
    wireguard-tools
    foot
    xfce.xfce4-terminal
  gnome-keyring
  libsecret 
  ];


  boot.kernelModules = [ "drivetemp" ];  # for reading HDD temps
  users.users.${vars.username}.extraGroups = [ "dialout" ]; # for flashing microcontrolers

  system.stateVersion = "25.11";


  hardware.graphics = {
    enable = true;
  };
  services.xserver.videoDrivers = [ "vmware" ];
  virtualisation.virtualbox.guest.enable = true;
  services.intune.enable = true;

  # Hyprland sometimes needs this for VirtualBox/VMware
  environment.sessionVariables = {
    # Necessary for some Wayland compositors to work in VirtualBox
    WLR_NO_HARDWARE_CURSORS = "1";
    # Tells Hyprland to ignore the lack of a proper HW clock
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    LIBGL_ALWAYS_SOFTWARE = "1";
  };

# Enable the gnome-keyring secrets service
#services.gnome.gnome-keyring.enable = true;

# Allow PAM to unlock the keyring on login
security.pam.services.login.enableGnomeKeyring = true;

programs.nix-ld.enable = true;
programs.nix-ld.libraries = with pkgs; [
  libGL
  glib
  nss
  nspr
  atk
  at-spi2-atk
  libdrm
  mesa
  expat
  libxkbcommon
  xorg.libX11
  xorg.libXcomposite
  xorg.libXdamage
  xorg.libXext
  xorg.libXfixes
  xorg.libXrandr
  # These are the common ones needed by JavaFX/Electron apps
];


}
