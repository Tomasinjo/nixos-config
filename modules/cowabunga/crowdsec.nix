{ config, pkgs, lib, vars, ... }:

let
  enrollKeyFile = pkgs.writeText "crowdsec-enroll-key" vars.crowdsec.enrollkey  # flake requires it to be file

  offendersParser = pkgs.writeText "offenders-ips.yaml" ''
    filename: offenders-ips.yaml
    parser:
      name: crowdsecurity/offenders-ips
      description: "Parse offenders-ips.log JSON format"
      vendor: crowdsecurity
      author: crowdsecurity
      enabled: true
      grok:
        pattern: '^\\{"ClientHost":"%{DATA:evt.StrSource}","RequestHost":"%{DATA:evt.RequestHost}","RequestPath":"%{DATA:evt.RequestPath}","time":"%{DATA:evt.time}"\\}$'
        apply_on: line
      labels:
        type: offenders
  '';

  offendersScenario = pkgs.writeText "offenders-ban.yaml" ''
    type: leaky
    name: crowdsecurity/offenders-ban
    description: "Ban IPs from offenders-ips.log"
    filter: evt.Meta.source == "offenders-ips"
    condition: evt.StrSource != ""
    duration: 30d
    action:
      type: ban
    labels:
      type: ban
  '';

  whitelistConfig = pkgs.writeText "whitelists.yaml" ''
    filename: whitelists.yaml
    parser:
      name: crowdsecurity/whitelists
      description: "Whitelist IP ranges"
      vendor: crowdsecurity
      author: crowdsecurity
      enabled: true
      grok:
        pattern: ""
        apply_on: message
      static_ips:
        - "10.0.0.0/8"
        - "172.16.0.0/12"
        - "192.168.0.0/16"
        - "fe80::/10"
        - "fc00::/7"
        - "${vars.net.sensei.ipv6_prefix}"
        - "${vars.net.sensei.ipv4_public}/32"
      labels:
        type: whitelist
  '';

  setupScript = pkgs.writeScriptBin "crowdsec-custom-setup" ''
    #!${pkgs.runtimeShell}
    set -eu
    set -o pipefail

    install -Dm644 ${offendersParser} /etc/crowdsec/parsers/s02-enrich/offenders-ips.yaml
    install -Dm644 ${offendersScenario} /etc/crowdsec/scenarios/offenders-ban.yaml
    install -Dm644 ${whitelistConfig} /etc/crowdsec/parsers/s02-enrich/whitelists.yaml

    # register the firewall bouncer if not already registered
    if ! cscli bouncers list | grep -q "crowdsec-firewall-bouncer"; then
      cscli bouncers add "crowdsec-firewall-bouncer" --key "${vars.crowdsec.bouncer_key}"
    fi

    # installs external ti feeds
    cscli collections install crowdsecurity/iptables 2>/dev/null || true
  '';
  
in {
  services.crowdsec = {
    enable = true;
    enrollKeyFile = enrollKeyFile;
    acquisitions = [
      {
        source = "file";
        filename = "/var/log/offenders-ips.log";
        labels.type = "offenders";
      }
    ];
  };

  services.crowdsec-firewall-bouncer = {
    enable = true;
    settings = {
      api_key = vars.crowdsec.bouncer_key;
      api_url = "http://127.0.0.1:8080";
      mode = "nftables";
      nftables = {
        ipv4 = {
          enabled = true;
          set_only = false;
          table = "crowdsec";
          chain = "prerouting";   # use prerouting else input chain is used which happens later than DNAT causing rule not to be evaluated
          priority = -150;        # priority is there to make sure it happens before dnat
        };
        ipv6 = {
          enabled = true;
          set_only = false;
          table = "crowdsec";
          chain = "prerouting";
          priority = -150;
        };
      };
      update_frequency = "10s";
      deny_action = "DROP";
      deny_log = true;
    };
  };

  # Run custom setup after crowdsec is configured
  systemd.services.crowdsec.serviceConfig = {
    ExecStartPost = ["${setupScript}/bin/crowdsec-custom-setup"];
  };
}
