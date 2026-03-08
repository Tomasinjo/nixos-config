{ config, pkgs, vars, ... }:

{
  networking.hostName = vars.networking.zenki.hostname;
  networking.useNetworkd = true;
  networking.useDHCP = false;

  # Rename Interface based on MAC
  systemd.network.links."10-persistent-${vars.networking.zenki.interface_name}" = {
    matchConfig.MACAddress = vars.networking.zenki.interface_mac;
    linkConfig.Name = vars.networking.zenki.interface_name;
  };

  # Configure Physical Interface (Trunk for VLANs)
  systemd.network.networks."10-${vars.networking.zenki.interface_name}" = {
    matchConfig.Name = vars.networking.zenki.interface_name;
    # Ensure link is up
    linkConfig.RequiredForOnline = "no";
    networkConfig.LinkLocalAddressing = "no";
    # Attach VLAN
    vlan = [ vars.networking.zenki.vlan10.interface_name ];
  };

  # Configure VLAN 10 Interface
  systemd.network.netdevs."10-vlan${toString vars.networking.zenki.vlan10.tag}" = {
    netdevConfig = {
      Name = vars.networking.zenki.vlan10.interface_name;
      Kind = "vlan";
    };
    vlanConfig.Id = vars.networking.zenki.vlan10.tag;
  };

  # IP Configuration for VLAN 10
  systemd.network.networks."20-vlan${toString vars.networking.zenki.vlan10.tag}" = {
    matchConfig.Name = vars.networking.zenki.vlan10.interface_name;
    address = [
      vars.networking.zenki.vlan10.ipv4Address
      vars.networking.zenki.vlan10.ipv6Address
    ];
    routes = [
      { Gateway = vars.networking.vlan10.ipv4.gateway; }
      { Gateway = vars.networking.vlan10.ipv6.gateway; }
    ];
    networkConfig = {
      IPv6AcceptRA = true;
    };
    # DNS settings
    networkConfig.DNS = [ 
      vars.networking.ipv4DNS 
			vars.networking.ipv6DNS 
    ];
  };

  # Firewall
  networking.firewall = {
      enable = true;
      allowPing = true;
  
      # default deny all
      allowedTCPPorts = [ ]; 
      allowedUDPPorts = [ ];
  
      # allowed ports for system services
      interfaces."${vars.networking.zenki.vlan10.interface_name}" = {
        allowedTCPPorts = [ 22 ]; # SSH
      };
  
      trustedInterfaces = [ "docker0" ];
  
      checkReversePath = "loose";
  };
  users.users.${vars.username}.extraGroups = [ "networkmanager" ];
}
