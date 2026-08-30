{
  config,
  pkgs,
  lib,
  vars,
  ...
}:

{
  services.suricata = {
    enable = true;

    enabledSources = [
      "et/open" # Emerging Threats Open ruleset
      "abuse.ch/sslbl-blacklist" # SSL Blacklist
      "abuse.ch/sslbl-c2" # SSL Botnet C2
      "oisf/trafficid" # Traffic identification
      "tgreen/hunting" # Threat hunting rules
      "pawpatrules"
      "ptrules/open"
    ];

    disabledRules = [
      "re:modbus"
      "re:dnp3"
      "re:enip"
      "group:emerging-scada.rules"
      "re:Ethertype unknown"
      "group:emerging-p2p.rules" # Disables the entire ET P2P category
      "re:BitTorrent"
      "re:bittorrent"
      "re:torrent"
      "re:uTorrent"
      "re:DHT ping"
      "re:Peer_Exchange"
      "re:classtype:protocol-command-decode"
      "re:stream_event"
    ];

    settings = {
      vars.address-groups = {
        HOME_NET = "[192.168.0.0/16, 10.0.0.0/16]";
        EXTERNAL_NET = "!$HOME_NET";
      };

      host-mode = "router";

      af-packet = [
        {
          interface = vars.net.sensei.common-vlan.name; # vlan 10
          bpf-filter = "not dst net 192.168.0.0/16 and not dst net ${vars.net.zenki.docker-services.subnet} and not dst ${vars.net.sensei.ipv4_public} and not dst net ${vars.net.sensei.ipv6_prefix} and not dst net 224.0.0.0/4";
          threads = "auto";
          cluster-id = 10;
          cluster-type = "cluster_flow";
          defrag = "yes";
          use-mmap = "yes";
          tpacket-v3 = "yes";
        }
        {
          interface = vars.net.sensei.iot-vlan.name; # vlan 30
          bpf-filter = "not dst net 192.168.0.0/16 and not dst net ${vars.net.zenki.docker-services.subnet} and not dst ${vars.net.sensei.ipv4_public} and not dst net ${vars.net.sensei.ipv6_prefix} and not dst net 224.0.0.0/4";
          threads = "auto";
          cluster-id = 30;
          cluster-type = "cluster_flow";
          defrag = "yes";
          use-mmap = "yes";
          tpacket-v3 = "yes";
        }
        {
          interface = vars.net.sensei.server-vlan.name; # vlan 40
          bpf-filter = "not dst net 192.168.0.0/16 and not dst net ${vars.net.zenki.docker-services.subnet} and not dst ${vars.net.sensei.ipv4_public} and not dst net ${vars.net.sensei.ipv6_prefix} and not port 51413 and not dst net 224.0.0.0/4";
          threads = "auto";
          cluster-id = 40;
          cluster-type = "cluster_flow";
          defrag = "yes";
          use-mmap = "yes";
          tpacket-v3 = "yes";
        }
      ];

      "default-log-dir" = "/var/log/suricata";

      outputs = [
        {
          fast = {
            enabled = false; # already included in eve-log
          };
        }
        {
          eve-log = {
            enabled = true;
            filetype = "unix_stream";  # "regular" to write to file
            filename = "/run/vector/eve.sock"; # filename to write to file in var/log/suricata
            community-id = true;

            types = [
              {
                alert = {
                  payload = "no"; # Set to "yes" if you need full packet hex dumps
                  payload-printable = "yes";
                  packet = "yes";
                  metadata = "yes";
                  tagged-packets = "yes";
                };
              }
              {
                http = {
                  extended = "yes";
                };
              }
              {
                dns = {};
              }
              {
              tls = {
                extended = "yes";
                };
              }
              { flow = { }; } # Connection metadata / metrics
              { drop = { }; } # Logs dropped packets (useful when moving to IPS)
              {
                stats = {
                  totals = "yes";
                  threads = "no";
                };
              }
            ];
          };
        }
      ];

      app-layer.protocols = {
        tls.enabled = "yes";
        http.enabled = "yes";
        dns.enabled = "yes";
      };
    };
  };


  users.groups.vector = {};

  users.users.vector = {
    isSystemUser = true;
    group = "vector";
    extraGroups = [ "suricata" ];
  };

  users.users.suricata.extraGroups = [ "vector" ];

  systemd.services.vector.serviceConfig = {
    RuntimeDirectory = "vector";
    RuntimeDirectoryMode = "0755";
  };

  # Allow Suricata's sandbox to access /run/vector
  systemd.services.suricata.serviceConfig = {
    ReadWritePaths = [ "/run/vector" ];
  };

  services.vector = {
    enable = true;
    settings = {
      sources = {
        suricata_socket = {
          type = "socket";
          mode = "unix";
          path = "/run/vector/eve.sock";
          socket_file_mode = 438; # 0666 in decimal or 0660
        };
      };

      transforms = {
        parse_eve = {
          type = "remap";
          inputs = [ "suricata_socket" ];
          source = ''
             parsed, err = parse_json(.message)
            if err != null {
              abort
            }

            . = parsed

            # Set stream fields
            .service = "suricata"
            .host = get_hostname!()
            .event_type = to_string!(.event_type || "unknown")

            # Parse timestamp into strict RFC3339 for VictoriaLogs
            if exists(.timestamp) {
              ts, err = parse_timestamp(to_string!(.timestamp), "%FT%T%.f%z")
              if err == null {
                .timestamp = ts
              }
            }

            # Helper for connection string: (src:port -> dst:port)
            conn = ""
            if exists(.src_ip) && exists(.dest_ip) {
              src = to_string!(.src_ip)
              if exists(.src_port) {
                src = src + ":" + to_string!(.src_port)
              }

              dst = to_string!(.dest_ip)
              if exists(.dest_port) {
                dst = dst + ":" + to_string!(.dest_port)
              }

              conn = " (" + src + " -> " + dst + ")"
            }

            # Construct the _msg field required by VictoriaLogs
            if .event_type == "alert" {
              ._msg = to_string!(.alert.signature || "Alert") + conn
            } else if .event_type == "dns" {
              ._msg = "DNS " + to_string!(.dns.type || "QUERY") + " " + to_string!(.dns.rrname || "") + conn
            } else if .event_type == "http" {
              ._msg = "HTTP " + to_string!(.http.http_method || "REQ") + " " + to_string!(.http.hostname || "") + to_string!(.http.url || "") + conn
            } else if .event_type == "tls" {
              sni = to_string!(.tls.sni || .tls.subject || "TLS connection")
              ._msg = "TLS " + sni + conn
            } else if .event_type == "flow" {
              ._msg = "FLOW " + to_string!(.proto || "") + conn + " [" + to_string!(.flow.state || "") + "]"
            } else if .event_type == "drop" {
              ._msg = "DROP " + to_string!(.proto || "") + conn
            } else if .event_type == "stats" {
              ._msg = "Suricata engine periodic stats"
            } else {
              ._msg = "[" + .event_type + "]" + conn
            }
          '';
        };
      };

      sinks = {
        victorialogs = {
          type = "http";
          inputs = [ "parse_eve" ];
          uri = "http://10.0.37.2:9428/insert/jsonline?_stream_fields=service,event_type,host&_time_field=timestamp";
          encoding = {
            codec = "json";
          };
          framing = {
            method = "newline_delimited";
          };
          batch = {
            max_bytes = 1048576; # Flush at 1MB batch
            timeout_secs = 1;     # Or every 1 second
          };
        };
      };
    };
  };

  # Ensure Vector starts before Suricata so the socket is ready
  systemd.services.suricata.after = [ "vector.service" ];
  systemd.services.suricata.wants = [ "vector.service" ];
}
