{ config, pkgs, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  networking.hostName = "zenki";
  networking.useNetworkd = true;
  networking.useDHCP = false;

  # Rename Interface based on MAC
  systemd.network.links."10-persistent-eth10g" = {
    matchConfig.MACAddress = "f4:52:14:87:bd:20";
    linkConfig.Name = "eth10g";
  };

  # Configure Physical Interface (Trunk for VLANs)
  systemd.network.networks."10-eth10g" = {
    matchConfig.Name = "eth10g";
    # Ensure link is up
    linkConfig.RequiredForOnline = "no";
    networkConfig.LinkLocalAddressing = "no";
    # Attach VLAN
    vlan = [ secrets.networking.zenki.vlan10.interface_name ];
  };

  # Configure VLAN 10 Interface
  systemd.network.netdevs."10-vlan10" = {
    netdevConfig = {
      Name = secrets.networking.zenki.vlan10.interface_name;
      Kind = "vlan";
    };
    vlanConfig.Id = 10;
  };

  # IP Configuration for VLAN 10
  systemd.network.networks."20-vlan10" = {
    matchConfig.Name = secrets.networking.zenki.vlan10.interface_name;
    address = [
      secrets.networking.zenki.vlan10.ipv4Address
      secrets.networking.zenki.vlan10.ipv6Address
    ];
    routes = [
      { Gateway = secrets.networking.zenki.vlan10.ipv4Gateway; }
      { Gateway = secrets.networking.zenki.vlan10.ipv6Gateway; }
    ];
    networkConfig = {
      IPv6AcceptRA = true;
    };
    # DNS settings
    networkConfig.DNS = [ secrets.networking.zenki.vlan10.ipv4DNS 
			  secrets.networking.zenki.vlan10.ipv6DNS 
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
      interfaces."eth10g.10" = {
        allowedTCPPorts = [ 22 ]; # SSH
      };
  
      trustedInterfaces = [ "docker0" ];
  
      checkReversePath = "loose";
  };
  users.users.tom.extraGroups = [ "networkmanager" ];
}
