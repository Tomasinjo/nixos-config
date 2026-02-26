{ config, pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    allowedBridges = [ "virbr0" ];
    
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;

  users.users.tom.extraGroups = [ "libvirtd" "kvm" ];

  environment.systemPackages = with pkgs; [
    virt-viewer
    virtio-win
    win-spice
  ];
}