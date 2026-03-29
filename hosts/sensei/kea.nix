{ config, lib, pkgs, vars, ... }:

{
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          vars.net.sensei.common-vlan.name
          vars.net.sensei.guest-vlan.name
          vars.net.sensei.iot-vlan.name
        ];
        dhcp-socket-type = "raw";
      };
      valid-lifetime = 4000;
      
      option-data = [
        { name = "domain-name"; data = vars.net.domain; }
        { name = "domain-search"; data = vars.net.domain; }
        { name = "ntp-servers"; data = vars.net.sensei.ipv4DNS; }
        { name = "time-servers"; data = vars.net.sensei.ipv4DNS; }
        { name = "domain-name-servers"; data = "${vars.net.sensei.ipv4DNS}, 1.1.1.1"; }
      ];

      subnet4 = [
        {
          subnet = "${vars.net.sensei.common-vlan.ipv4.subnet}/${vars.net.sensei.common-vlan.ipv4.mask}";
          id = vars.net.sensei.common-vlan.id;
          pools = [ { pool = vars.net.sensei.common-vlan.ipv4.dhcp_pool; } ];
          option-data = [
            { name = "routers"; data = vars.net.sensei.common-vlan.ipv4.gateway; }
          ];
          reservations = map (m: {
            hw-address = m.mac;
            ip-address = m.ip;
            hostname = m.hostname;
          }) (builtins.filter (m: m ? mac) (builtins.attrValues vars.net.sensei.common-vlan.members));
        }
        {
          subnet = "${vars.net.sensei.guest-vlan.ipv4.subnet}/${vars.net.sensei.guest-vlan.ipv4.mask}";
          id = vars.net.sensei.guest-vlan.id;
          pools = [ { pool = vars.net.sensei.guest-vlan.ipv4.dhcp_pool; } ];
          option-data = [
            { name = "routers"; data = vars.net.sensei.guest-vlan.ipv4.gateway; }
            { name = "domain-name-servers"; data = "1.1.1.1"; }
          ];
        }
        {
          subnet = "${vars.net.sensei.iot-vlan.ipv4.subnet}/${vars.net.sensei.iot-vlan.ipv4.mask}";
          id = vars.net.sensei.iot-vlan.id;
          pools = [ { pool = vars.net.sensei.iot-vlan.ipv4.dhcp_pool; } ];
          option-data = [
            { name = "routers"; data = vars.net.sensei.iot-vlan.ipv4.gateway; }
          ];
          reservations = map (m: {
            hw-address = m.mac;
            ip-address = m.ip;
            hostname = m.hostname;
          }) (builtins.filter (m: m ? mac) (builtins.attrValues vars.net.sensei.iot-vlan.members));
        }
      ];
    };
  };

  services.kea.dhcp6 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          vars.net.sensei.common-vlan.name
          vars.net.sensei.guest-vlan.name
          #vars.net.sensei.iot-vlan.name
        ];
      };
      valid-lifetime = 4000;
      
      option-data = [
        { name = "domain-search"; data = vars.net.domain; }
        { name = "dns-servers"; data = vars.net.sensei.ipv6DNS; }
      ];

      subnet6 = [
        {
          subnet = "${vars.net.sensei.common-vlan.ipv6.subnet}/${vars.net.sensei.common-vlan.ipv6.mask}";
          id = vars.net.sensei.common-vlan.id;
          pools = [ { pool = vars.net.sensei.common-vlan.ipv6.dhcp_pool; } ];
          option-data = [];
        }
        {
          subnet = "${vars.net.sensei.guest-vlan.ipv6.subnet}/${vars.net.sensei.guest-vlan.ipv6.mask}";
          id = vars.net.sensei.guest-vlan.id;
          pools = [ { pool = vars.net.sensei.guest-vlan.ipv6.dhcp_pool; } ];
          option-data = [
            { name = "dns-servers"; data = "2620:fe::fe"; } # quad9 ipv6
          ];
        }
        #{
        #  subnet = "${vars.net.sensei.iot-vlan.ipv6.subnet}/${vars.net.sensei.iot-vlan.ipv6.mask}";
        #  id = vars.net.sensei.iot-vlan.id;
        #  pools = [ { pool = vars.net.sensei.iot-vlan.ipv6.dhcp_pool; } ];
        #  option-data = [];
        #}
      ];
    };
  };
}
