{ config, lib, pkgs, vars, inputs, ... }:

{
  services.unbound = {
    enable = true;
    settings = {
      server = {
        tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";
        interface = [
          "${vars.net.sensei.ipv4DNS}"
          "${vars.net.sensei.ipv6DNS}"
          "127.0.0.1"
        ];
        port = 53;
        
        access-control = [
          "192.168.0.0/16 allow"
          "${vars.net.sensei.ipv6_prefix} allow"
        ];
      
	module-config = "'respip validator iterator'"; # respip-enables rpz blocklist. validator=enables dnssec. iterator=queries upstream, necessary.

        local-data = [
          ''"ha-int.${vars.net.domain}. IN A 192.168.10.15"''
          ''"sensei.${vars.net.domain}. IN A ${vars.net.sensei.mgmt-vlan.ipv4.gateway}"''
          ''"sensei.${vars.net.domain}. IN AAAA ${vars.net.sensei.mgmt-vlan.ipv6.gateway}"''
          ''"pretikalo.${vars.net.domain}. IN A 192.168.99.2"''
          ''"ap.${vars.net.domain}. IN A 192.168.99.101"''
          ''"ap2.${vars.net.domain}. IN A 192.168.99.102"''
          ''"zenki.${vars.net.domain}. IN A 192.168.10.15"''
          ''"tv.${vars.net.domain}. IN A 192.168.10.251"''
          ''"os.${vars.net.domain}. IN A 192.168.30.12"''
          ''"printer.${vars.net.domain}. IN A 192.168.30.7"''
          ''"tc.${vars.net.domain}. IN A 192.168.30.160"''
          ''"reo-terasa_1.${vars.net.domain}. IN A 192.168.30.80"''
          ''"reo-terasa_2.${vars.net.domain}. IN A 192.168.30.78"''
          ''"reo-dvorisce.${vars.net.domain}. IN A 192.168.30.85"''
          ''"reo-dnevna.${vars.net.domain}. IN A 192.168.30.56"''
          ''"reo-jedilnica.${vars.net.domain}. IN A 192.168.30.57"''
          ''"reo-sredina.${vars.net.domain}. IN A 192.168.30.58"''
          ''"reo-doorbell.${vars.net.domain}. IN A 192.168.30.158"''
        ];

        # Prevents upstream from returning private addresses, protects from DNS rebinding
        # Applies only to upstream responses, local-data overrides will not be affected.
        private-address = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "169.254.0.0/16"
          "fd00::/8"
          "fe80::/10"
        ];
      };

      # Pro and TIF, together take about 1.3GB of memory
      rpz = [
	{
	  name = "hageziPro";
	  url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/pro.txt";
	}
	{
	  name = "hageziThreatIntel";
	  url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/tif.txt";
	}
      ];
      
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = "yes";
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
            "2606:4700:4700::1111@853#cloudflare-dns.com"
            "2606:4700:4700::1001@853#cloudflare-dns.com"
          ];
        }
      ];
    };
  };
}

