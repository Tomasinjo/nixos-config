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
        
        local-zone = ''"${vars.net.domain}" transparent'';

        # Local overrides
        local-data = let
          # Evaluate Zenki containers to find those using oci-framework.web.internal
          zenkiContainers = inputs.self.nixosConfigurations.zenki.config.virtualisation.oci-containers.containers;
          
          # Extract hostnames that have the fikus.dns.internal label
          internalHostnames = lib.unique (lib.mapAttrsToList 
            (name: container: container.labels."fikus.dns.hostname") 
            (lib.filterAttrs (name: container: container.labels ? "fikus.dns.internal") zenkiContainers));
            
          # For each hostname, generate A and AAAA records pointing to Traefik
          dynamicRecords = lib.concatMap (hostname: [
            ''"${hostname}.${vars.net.domain}. IN A ${vars.net.zenki.common-vlan.mac-vlan.traefik.ipv4Address}"''
            ''"${hostname}.${vars.net.domain}. IN AAAA ${vars.net.zenki.common-vlan.mac-vlan.traefik.ipv6Address}"''
          ]) internalHostnames;
          
          staticRecords = [
            ''"ha-int.${vars.net.domain}. IN A 192.168.10.15"''
            ''"sensei.${vars.net.domain}. IN A 192.168.99.1"''
            ''"sensei.${vars.net.domain}. IN AAAA 2a00:ee2:1101:ff99::1"''
            ''"pretikalo.${vars.net.domain}. IN A 192.168.99.2"''
            ''"ap.${vars.net.domain}. IN A 192.168.99.101"''
            ''"ap2.${vars.net.domain}. IN A 192.168.99.102"''
            ''"zenki.${vars.net.domain}. IN A 192.168.10.15"''
            ''"tv.${vars.net.domain}. IN A 192.168.10.251"''
            ''"os.${vars.net.domain}. IN A 192.168.30.12"''
            ''"printer.${vars.net.domain}. IN A 192.168.30.7"''
            ''"tc.${vars.net.domain}. IN A 192.168.30.160"''
            ''"mass.${vars.net.domain}. IN A 192.168.10.29"''
            ''"hugo.${vars.net.domain}. IN A 192.168.10.15"''
            ''"reo-terasa_1.${vars.net.domain}. IN A 192.168.30.80"''
            ''"reo-terasa_2.${vars.net.domain}. IN A 192.168.30.78"''
            ''"reo-dvorisce.${vars.net.domain}. IN A 192.168.30.85"''
            ''"reo-dnevna.${vars.net.domain}. IN A 192.168.30.56"''
            ''"reo-jedilnica.${vars.net.domain}. IN A 192.168.30.57"''
            ''"reo-sredina.${vars.net.domain}. IN A 192.168.30.58"''
            ''"reo-doorbell.${vars.net.domain}. IN A 192.168.30.158"''
          ];
        in staticRecords ++ dynamicRecords;

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
      
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = "yes";
          forward-addr = [
            "9.9.9.9@853#dns.quad9.net"
            "149.112.112.112@853#dns.quad9.net"
            "2620:fe::fe@853#dns.quad9.net"
            "2620:fe::9@853#dns.quad9.net"
          ];
        }
      ];
    };
  };
}

