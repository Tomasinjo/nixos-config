{ config, pkgs, ... }:
let
  secrets = import ../secrets.nix;
in
{
  virtualisation = {
    libvirtd = {
      enable = true;
      allowedBridges = [ "virbr0" ];
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  programs.virt-manager.enable = true;

  users.users.tom.extraGroups = [ "libvirtd" "kvm" ];

  environment.systemPackages = with pkgs; [
    virt-viewer
    virtio-win
    win-spice
  ];

  networking.firewall = {
    extraCommands = ''
      # 1. Create a dedicated chain for our restricted VM
      iptables -N RESTRICTED_VM 2>/dev/null || true
      iptables -F RESTRICTED_VM

      # 2. Route all traffic originating from the VM bridge into this chain.
      # We use -I (insert) at index 1 of the INPUT and FORWARD chains.
      # This ensures our restrictions apply BEFORE libvirt's default "allow all" NAT rules.
      iptables -I INPUT 1 -i virbr3 -j RESTRICTED_VM
      iptables -I FORWARD 1 -i virbr3 -j RESTRICTED_VM

      # 3. Allow return traffic for established connections (so the VM can receive replies)
      iptables -A RESTRICTED_VM -m state --state RELATED,ESTABLISHED -j ACCEPT

      # 4. Allow essential VM-to-Host services (DHCP and DNS)
      iptables -A RESTRICTED_VM -p udp --dport 67 -j ACCEPT
      iptables -A RESTRICTED_VM -p udp --dport 53 -j ACCEPT
      iptables -A RESTRICTED_VM -p tcp --dport 53 -j ACCEPT

      # 5. Allow SCP/SSH to specific local IP
      iptables -A RESTRICTED_VM -d 192.168.10.15 -j ACCEPT

      # 6. Allow specific external IPs
      iptables -A RESTRICTED_VM -d 1.1.1.1 -j ACCEPT
      iptables -A RESTRICTED_VM -d ${secrets.vps_ip} -j ACCEPT

      # 7. Default Policy: DROP everything else originating from the VM
      iptables -A RESTRICTED_VM -j DROP
    '';

    # Clean up our custom rules when the firewall is stopped or reloaded
    extraStopCommands = ''
      # Remove the hooks from INPUT and FORWARD
      iptables -D INPUT -i virbr3 -j RESTRICTED_VM 2>/dev/null || true
      iptables -D FORWARD -i virbr3 -j RESTRICTED_VM 2>/dev/null || true
      
      # Flush and delete the custom chain
      iptables -F RESTRICTED_VM 2>/dev/null || true
      iptables -X RESTRICTED_VM 2>/dev/null || true
    '';
  };
}