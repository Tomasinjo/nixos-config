{ config, pkgs, lib, vars, ... }:

let
  offendersParser = pkgs.writeText "offenders-ips.yaml" ''
    stage: s01-parse
    name: local/offenders-ips
    description: "Parse offenders-ips.log JSON format"
    filter: "evt.Line.Labels.type == 'offenders'"
    onsuccess: next_stage
    statics:
      - meta: log_type
        value: offenders
      - meta: source_ip
        expression: JsonExtract(evt.Line.Raw, "ClientHost")
      - target: evt.StrTime
        expression: JsonExtract(evt.Line.Raw, "time")
  '';

  # ban on third attempt. every 10 min, attempt is removed. suppress further alerts for 30 days - 720h
  offendersScenario = pkgs.writeText "offenders-ban.yaml" ''
    type: leaky
    name: local/offenders-ban
    description: "Ban IPs from offenders-ips.log"
    filter: "evt.Meta.log_type == 'offenders'"
    groupby: "evt.Meta.source_ip"
    capacity: 2
    leakspeed: 10m
    blackhole: 720h
    labels:
      service: http
      type: ban
      remediation: true
  '';

  whitelistConfig = pkgs.writeText "whitelists.yaml" ''
    name: local/whitelists
    description: "Whitelist IP ranges"
    whitelist:
      reason: "internal private and trusted public IPs"
      cidr:
        - "10.0.0.0/8"
        - "172.16.0.0/12"
        - "192.168.0.0/16"
        - "fe80::/10"
        - "fc00::/7"
        - "${vars.net.sensei.ipv6_prefix}"
        - "${vars.net.sensei.ipv4_public}/32"
  '';

  acquisYaml = pkgs.writeText "acquis.yaml" ''
    source: file
    filenames:
      - /var/log/offenders-ips.log
    labels:
      type: offenders
  '';
  
  # ban for 30 days
  profilesConfig = pkgs.writeText "profiles.yaml" ''
    name: default_ip_remediation
    filters:
      - Alert.Remediation == true && Alert.GetScope() == "Ip"
    decisions:
      - type: ban
        duration: 720h
    on_success: break
  '';

  bouncerConfig = (pkgs.formats.yaml { }).generate "crowdsec-firewall-bouncer.yaml" {
    api_key = vars.crowdsec.bouncer_key;
    api_url = "http://127.0.0.1:8080";
    mode = "nftables";
    nftables = {
      ipv4 = {
        enabled = true;
        set_only = true;  # just create ip sets, but dont create nft tables. This is handled separately below because by default bouncer can only set rules on input chain, but i need prerouting due to DNAT
        table = "crowdsec";
      };
      ipv6 = {
        enabled = true;
        set_only = true;
        table = "crowdsec";
      };
    };
    update_frequency = "1s";
    deny_action = "DROP";
    deny_log = true;
  };

in {
  environment.systemPackages = [
    pkgs.crowdsec
    pkgs.crowdsec-firewall-bouncer
  ];

  environment.etc = {
    "crowdsec/parsers/s01-parse/offenders-ips.yaml".source = offendersParser;
    "crowdsec/parsers/s02-enrich/whitelists.yaml".source = whitelistConfig;
    "crowdsec/scenarios/offenders-ban.yaml".source = offendersScenario;
    "crowdsec/acquis.yaml".source = acquisYaml;
    "crowdsec/bouncers/crowdsec-firewall-bouncer.yaml".source = bouncerConfig;
    "crowdsec/profiles.yaml".source = profilesConfig;
  };

  systemd.services.crowdsec = {
    description = "Crowdsec agent";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.crowdsec pkgs.coreutils pkgs.gnugrep pkgs.curl pkgs.cacert ];

    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.crowdsec}/bin/crowdsec -c /etc/crowdsec/config.yaml";
      ExecReload = "${pkgs.crowdsec}/bin/cscli reload";
      StateDirectory = "crowdsec";
      RuntimeDirectory = "crowdsec";
      ReadWritePaths = [ "/etc/crowdsec" "/var/lib/crowdsec" ];

      ExecStartPre = pkgs.writeShellScript "crowdsec-prestart" ''
        set -eu
        mkdir -p /etc/crowdsec /var/lib/crowdsec/data /var/lib/crowdsec/hub /etc/crowdsec/patterns

        # Copy stock template files only if they do not exist
        for item in ${pkgs.crowdsec}/share/crowdsec/config/*; do
          target="/etc/crowdsec/$(basename "$item")"
          if [ ! -e "$target" ] && [ ! -L "$target" ]; then
            cp -r --no-preserve=mode,ownership "$item" "$target"
          fi
        done

        if [ ! -f /etc/crowdsec/local_api_credentials.yaml ]; then
          ${pkgs.crowdsec}/bin/cscli machines add --force --auto || true
        fi

        if [ ! -f /etc/crowdsec/hub/.index.json ]; then
          ${pkgs.crowdsec}/bin/cscli hub update || true
        fi
      '';

      ExecStartPost = pkgs.writeShellScript "crowdsec-poststart" ''
        set -eu

        if [ -n "${vars.crowdsec.enrollkey}" ]; then
          ${pkgs.crowdsec}/bin/cscli console enroll "${vars.crowdsec.enrollkey}" || true
        fi

        if ! ${pkgs.crowdsec}/bin/cscli bouncers list -o raw | grep -q "^crowdsec-firewall-bouncer,"; then
          ${pkgs.crowdsec}/bin/cscli bouncers add "crowdsec-firewall-bouncer" --key "${vars.crowdsec.bouncer_key}" || true
        fi

        ${pkgs.crowdsec}/bin/cscli collections install crowdsecurity/iptables 2>/dev/null || true
      '';
    };
  };

  systemd.services.crowdsec-firewall-bouncer = {
    description = "CrowdSec Firewall Bouncer";
    wantedBy = [ "multi-user.target" ];
    after = [ "crowdsec.service" "nftables.service" ];
    requires = [ "crowdsec.service" ];
    path = [ pkgs.nftables pkgs.ipset pkgs.iptables ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.crowdsec-firewall-bouncer}/bin/cs-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml";
      Restart = "always";
      RestartSec = "10s";
    };
  };


networking.nftables.tables = {
  "crowdsec-ipv4" = {
    family = "ip";
    name = "crowdsec";
    content = ''
      set crowdsec-blacklists-CAPI {
        type ipv4_addr
        flags timeout
      }
      set crowdsec-blacklists-crowdsec {
        type ipv4_addr
        flags timeout
      }
      chain prerouting-drops {
        type filter hook prerouting priority -150; policy accept;
        ip saddr @crowdsec-blacklists-CAPI log prefix "crowdsec[drop]: " counter drop
        ip saddr @crowdsec-blacklists-crowdsec log prefix "crowdsec[drop]: " counter drop
      }
    '';
  };

  "crowdsec-ipv6" = {
    family = "ip6";
    name = "crowdsec";
    content = ''
      set crowdsec6-blacklists-CAPI {
        type ipv6_addr
        flags timeout
      }
      set crowdsec6-blacklists-crowdsec {
        type ipv6_addr
        flags timeout
      }
      chain prerouting-drops {
        type filter hook prerouting priority -150; policy accept;
        ip6 saddr @crowdsec6-blacklists-CAPI log prefix "crowdsec6[drop]: " counter drop
        ip6 saddr @crowdsec6-blacklists-crowdsec log prefix "crowdsec6[drop]: " counter drop
      }
    '';
  };
};

}
