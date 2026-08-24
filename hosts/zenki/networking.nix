{ config, pkgs, vars, ... }:

{
  networking.hostName = vars.net.zenki.hostname;
  networking.useNetworkd = true;
  networking.useDHCP = false;

  # Enable kernel forwarding for Docker routed supernet
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Rename Interface based on MAC
  systemd.network.links."10-persistent-${vars.net.zenki.interface_name}" = {
    matchConfig.MACAddress = vars.net.zenki.interface_mac;
    linkConfig.Name = vars.net.zenki.interface_name;
  };

  # Configure Physical Interface (Trunk for VLANs)
  systemd.network.networks."10-${vars.net.zenki.interface_name}" = {
    matchConfig.Name = vars.net.zenki.interface_name;
    # Ensure link is up
    linkConfig.RequiredForOnline = "no";
    networkConfig.LinkLocalAddressing = "no";
    # Attach VLANs
    vlan = [
      vars.net.zenki.common-vlan.interface_name
      vars.net.zenki.lab-vlan.interface_name
    ];
  };

  # Configure VLAN 10 Interface
  systemd.network.netdevs."10-${vars.net.sensei.common-vlan.name}" = {
    netdevConfig = {
      Name = vars.net.zenki.common-vlan.interface_name;
      Kind = "vlan";
    };
    vlanConfig.Id = vars.net.sensei.common-vlan.id;
  };

  # IP Configuration for VLAN 10
  systemd.network.networks."20-${vars.net.sensei.common-vlan.name}" = {
    matchConfig.Name = vars.net.zenki.common-vlan.interface_name;
    address = [
      "${vars.net.zenki.common-vlan.ipv4Address}/${vars.net.sensei.common-vlan.ipv4.mask}"
      "${vars.net.zenki.common-vlan.ipv6Address}/${vars.net.sensei.common-vlan.ipv6.mask}"
    ];
    routes = [
      { Gateway = vars.net.sensei.common-vlan.ipv4.gateway; }
      { Gateway = vars.net.sensei.common-vlan.ipv6.gateway; }
    ];
    networkConfig = {
      IPv6AcceptRA = true;
    };
    # DNS settings
    networkConfig.DNS = [ 
      vars.net.sensei.ipv4DNS 
			vars.net.sensei.ipv6DNS 
    ];
  };

  # Configure VLAN 69 Interface (Lab) - Bridge port for virbr69
  systemd.network.netdevs."10-${vars.net.sensei.lab-vlan.name}" = {
    netdevConfig = {
      Name = vars.net.zenki.lab-vlan.interface_name;
      Kind = "vlan";
    };
    vlanConfig.Id = vars.net.sensei.lab-vlan.id;
  };

  # Bridge port configuration for VLAN 69 (no IP - handled by external DHCP on virbr69)
  systemd.network.networks."20-${vars.net.sensei.lab-vlan.name}" = {
    matchConfig.Name = vars.net.zenki.lab-vlan.interface_name;
    networkConfig.Bridge = "virbr69";
  };

  # Firewall
  networking.firewall = {
      enable = true;
      allowPing = true;
  
      # default deny all
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
  
      # allowed ports for system services
      interfaces."${vars.net.zenki.common-vlan.interface_name}" = {
        allowedTCPPorts = [ 22 ]; # SSH
      };
  
      trustedInterfaces = [ "docker0" ];
  
      checkReversePath = "loose";

      # Allow traffic across all custom docker bridges and bypass MASQUERADE for routed supernet
      extraCommands = ''
        # Allow traffic across all custom docker bridges
        iptables -I INPUT -i br-+ -j ACCEPT
        iptables -I FORWARD -i br-+ -j ACCEPT

        # Bypass MASQUERADE for outbound container traffic from the supernet
        iptables -t nat -I POSTROUTING 1 -s 10.200.0.0/16 ! -d 10.200.0.0/16 -j ACCEPT
      '';
  };
  users.users.${vars.username}.extraGroups = [ "networkmanager" ];
}
