{ config, pkgs, vars, ... }:

{
  services.vector = {
    enable = true;
    settings = {
      sources = {
        traefik_logs = {
          type = "docker_logs";
          include_containers = [
              "traefik"
            ];
          };
      };

      transforms = {
        # Filter only JSON logs containing ClientHost field
        filter_json = {
          type = "filter";
          inputs = [ "traefik_logs" ];
          condition = ''contains!(.message, "ClientHost") && contains!(.message, "{") && contains!(.message, "}")'';
        };
        
        # send only ip
        extract_ip = {
          type = "remap";
          inputs = [ "filter_json" ];
          source = ''
            . = parse_json!(string!(.message))
            del(.level)
            del(.msg)
          '';
        };
      };

      # to sensei
      sinks = {
        syslog_sink = {
          type = "socket";
          inputs = [ "extract_ip" ];
          mode = "udp";
          address = "${vars.net.sensei.mgmt-vlan.ipv4.gateway}:514";
          encoding = {
            codec = "json";
          };
        };
      };
    };
  };
}
