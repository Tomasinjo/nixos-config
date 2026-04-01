
{ secrets }:

{
  net = {
    domain = secrets.net.domain;
    sensei = {
      hostname = "sensei";
      ipv4DNS = "192.168.99.10";
      ipv6DNS = "${secrets.net.ipv6}99::10";
      ipv6_prefix = "${secrets.net.ipv6}00::/56";
      ipv4_public = secrets.net.ipv4;
      ppoe = {
        user = secrets.net.ppoe_username;
        password = secrets.net.ppoe_password;
      };

      common-vlan = {
        id = 10;
        name = "vlan10";
        ipv4 = {
          subnet =  "192.168.10.0";
          gateway = "192.168.10.1";
          mask = "24";
          dhcp_pool = "192.168.10.150 - 192.168.10.250";
        };
        ipv6 = {
          subnet =  "${secrets.net.ipv6}10::";
          gateway = "${secrets.net.ipv6}10::1";
          mask = "64";
        };
        members = {
          beyondtv2 = { mac = "34:51:80:c0:48:9a"; ip = "192.168.10.251"; hostname = "beyondtv2"; };
          wall-screen = { mac = "92:be:51:1e:d6:49"; ip = "192.168.10.151"; hostname = "wall-screen"; };
        };
      };
      guest-vlan = {
        id = 20;
        name = "vlan20";
        ipv4 = {
          subnet =  "192.168.20.0";
          gateway = "192.168.20.1";
          mask = "24";
          dhcp_pool = "192.168.20.150 - 192.168.20.250";
        };
        ipv6 = {
          subnet =  "${secrets.net.ipv6}20::";
          gateway = "${secrets.net.ipv6}20::1";
          mask = "64";
        };
      };
      iot-vlan = {
        id = 30;
        name = "vlan30";
        ipv4 = {
          subnet =  "192.168.30.0";
          gateway = "192.168.30.1";
          mask = "24";
          dhcp_pool = "192.168.30.200 - 192.168.30.254";
        };
        ipv6 = {
          subnet =  "${secrets.net.ipv6}30::";
          gateway = "${secrets.net.ipv6}30::1";
          mask = "64";
        };
        members = {
          orca =                  { mac = "00:0a:5c:c0:3f:d1"; ip = "192.168.30.160"; allow_out = false; hostname = "orca-tc"; };
          worx =                  { mac = "4c:75:25:45:52:bc"; ip = "192.168.30.127"; allow_out = true;  hostname = "worx"; };
          power_meter_leaf =      { mac = "fc:67:1f:7e:4e:61"; ip = "192.168.30.128"; allow_out = false; hostname = "tuya-power-meter-leaf"; };
          doorbell =              { mac = "ec:71:db:98:bf:d6"; ip = "192.168.30.158"; allow_out = true;  hostname = "reolink-doorbell"; };
          sesalec-nadstropje =    { mac = "24:18:c6:12:64:cf"; ip = "192.168.30.162"; allow_out = false; hostname = "sesalec-nadstropje"; };
          sesalec-klet =          { mac = "64:90:c1:0a:7f:2a"; ip = "192.168.30.163"; allow_out = false; hostname = "sesalec-klet"; };
          solaredge =             { mac = "84:d6:c5:57:51:dc"; ip = "192.168.30.164"; allow_out = true;  hostname = "solaredge"; };
          yeelink_pisarna =       { mac = "5c:e5:0c:36:6b:99"; ip = "192.168.30.165"; allow_out = false; hostname = "yeelink-light-mono4miio95"; };
          tesla =                 { mac = "4c:fc:aa:a8:46:aa"; ip = "192.168.30.166"; allow_out = true;  hostname = "tesla"; };
          sesalec-pritlicje =     { mac = "70:c9:32:53:3d:16"; ip = "192.168.30.167"; allow_out = false; hostname = "sesalec-pritlicje"; };
          pomivalc =              { mac = "68:a4:0e:0f:59:cd"; ip = "192.168.30.168"; allow_out = true;  hostname = "bosch-smv68tx06e-68a40e0f59cd"; };
          charger_leaf =          { mac = "bc:35:1e:da:2d:0f"; ip = "192.168.30.212"; allow_out = false; hostname = "tuya-leaf-charger"; };
        };
      };
      mgmt-vlan = {
        id = 99;
        name = "vlan99";
        ipv4 = {
          subnet =  "192.168.99.0";
          gateway = "192.168.99.1";
          mask = "24";
        };
        ipv6 = {
          subnet =  "${secrets.net.ipv6}99::";
          gateway = "${secrets.net.ipv6}99::1";
          mask = "64";
        };
      };

      wireguard = {
        ipv4 = {
	  gateway = "192.168.19.1";
	  subnet = "192.168.19.0";
	  mask = "24";
	};
        ipv6 = {
	  gateway = "${secrets.net.ipv6}19::1";
	  public_if = "${secrets.net.ipv6}77::1";
	};
        clients = {
          tom = {
            ipv4 = "192.168.19.2";
            ipv6 = "${secrets.net.ipv6}19::2";
            pub_key = "OZJgG/APSP6mwy68A13+JHgNN53j5Huj1+jn+oQmPxk=";
          };
        };
      };
    };


    zenki = {
      hostname = "zenki";
      fqdn = "zenki.${secrets.net.domain}";
      interface_mac = "f4:52:14:87:bd:20";
      interface_name = "eth10g";
      common-vlan = {
        interface_name = "eth10g.10";
  	    ipv4Address = "192.168.10.15";
        ipv6Address = "${secrets.net.ipv6}10::15";
        mac-vlan = {
          mass = {
  	        ipv4Address = "192.168.10.29";
            ipv6Address = "${secrets.net.ipv6}10::29";
          };
          traefik = {
  	        ipv4Address = "192.168.10.25";
            ipv6Address = "${secrets.net.ipv6}10::25";
          };
        };
      };
    };

    lenko = {
      hostname = "lenko";
    };

    vps = {
      ipv4Address = secrets.net.vps_ip;
    };
  };
}
