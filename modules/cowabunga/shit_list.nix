{ config, pkgs, ... }:

{
  networking.nftables = {
    tables."filter" = {
      family = "inet";
      content = ''
        set abuseipdb_blacklist {
          type ipv4_addr
          flags interval
        }

        # Drops packets arriving on WAN before DNAT (priority -150 runs BEFORE DNAT at -100)
        chain prerouting_block {
          type filter hook prerouting priority -150; policy accept;
          iifname "ppp0" ip saddr @abuseipdb_blacklist drop
        }
      '';
    };
  };


  systemd.services.update-abuseipdb = {
    description = "Update AbuseIPDB Blacklist from GitHub";
    after = [ "network-online.target" "nftables.service" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ curl gawk nftables coreutils ];

    serviceConfig = {
      Type = "oneshot";
    };

    script = ''
      URL="https://raw.githubusercontent.com/borestad/blocklist-abuseipdb/refs/heads/main/abuseipdb-s100-30d.ipv4"

      RAW_DATA=$(curl -s -f "$URL")

      # Check if curl succeeded
      if [ $? -ne 0 ] || [ -z "$RAW_DATA" ]; then
        echo "Failed to download list. Keeping existing blacklist."
        exit 1
      fi

      echo "Flushing old blacklist..."
      nft flush set inet filter abuseipdb_blacklist

      # parse IPs and add them to the set
      echo "Loading new IPs into nftables..."
      echo "$RAW_DATA" | awk '
        /^#/ { next }               # Skip comment lines
        NF >= 1 { print $1 }        # Extract first column (IP)
      ' | awk '
        BEGIN { printf "add element inet filter abuseipdb_blacklist { " }
        { printf "%s, ", $1 }
        END { print "}" }
      ' | nft -f -

      echo "Blacklist successfully loaded!"
    '';
  };

  systemd.timers.update-abuseipdb = {
    description = "Daily AbuseIPDB GitHub blacklist update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}