{ config, lib, pkgs, ... }:

{
  # Allow users to run nft list commands without password for MOTD
  security.sudo.extraRules = [
    {
      users = [ "root" ]; # Will apply to all users via group membership
      commands = [
        {
          command = "${pkgs.nftables}/bin/nft list set ip crowdsec crowdsec-blacklists-CAPI";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.nftables}/bin/nft list set ip crowdsec crowdsec-blacklists-crowdsec";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.nftables}/bin/nft list chain ip crowdsec prerouting-drops";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Create dynamic MOTD script
  environment.etc."motd.d/10-crowdsec-stats".text = ''
    #!/run/current-system/sw/bin/bash
    # Crowdsec Security Statistics

    # ANSI color codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              Crowdsec Security Statistics${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Get CAPI blocked IPs count
    CAPI_COUNT=$(${pkgs.nftables}/bin/nft list set ip crowdsec crowdsec-blacklists-CAPI 2>/dev/null | ${pkgs.gnugrep}/bin/grep -c "expires" || echo "0")

    # Get crowdsec blocked IPs count
    CROWDSEC_COUNT=$(${pkgs.nftables}/bin/nft list set ip crowdsec crowdsec-blacklists-crowdsec 2>/dev/null | ${pkgs.gnugrep}/bin/grep -c "expires" || echo "0")

    echo -e "${GREEN}Blocked IP Addresses:${NC}"
    echo -e "  Crowdsec CAPI:      ${YELLOW}${CAPI_COUNT}${NC}"
    echo -e "  Crowdsec Offenders: ${YELLOW}${CROWDSEC_COUNT}${NC}"
    echo ""

    # Get drop statistics
    DROPS_OUTPUT=$(${pkgs.nftables}/bin/nft list chain ip crowdsec prerouting-drops 2>/dev/null)

    if [[ -n "$DROPS_OUTPUT" ]]; then
      echo -e "${GREEN}Drop Statistics (prerouting-drops chain):${NC}"
      
      # Parse CAPI drops
      CAPI_PACKETS=$(echo "$DROPS_OUTPUT" | ${pkgs.gnugrep}/bin/grep "crowdsec-blacklists-CAPI" | ${pkgs.gawk}/bin/awk '{print $7}' || echo "0")
      CAPI_BYTES=$(echo "$DROPS_OUTPUT" | ${pkgs.gnugrep}/bin/grep "crowdsec-blacklists-CAPI" | ${pkgs.gawk}/bin/awk '{print $9}' || echo "0")
      
      # Parse crowdsec drops
      CROWDSEC_PACKETS=$(echo "$DROPS_OUTPUT" | ${pkgs.gnugrep}/bin/grep "crowdsec-blacklists-crowdsec" | ${pkgs.gawk}/bin/awk '{print $7}' || echo "0")
      CROWDSEC_BYTES=$(echo "$DROPS_OUTPUT" | ${pkgs.gnugrep}/bin/grep "crowdsec-blacklists-crowdsec" | ${pkgs.gawk}/bin/awk '{print $9}' || echo "0")

      echo -e "  CAPI List:"
      echo -e "    Packets: ${YELLOW}${CAPI_PACKETS}${NC}"
      echo -e "    Bytes:   ${YELLOW}${CAPI_BYTES}${NC}"
      echo ""
      echo -e "  Offenders List:"
      echo -e "    Packets: ${YELLOW}${CROWDSEC_PACKETS}${NC}"
      echo -e "    Bytes:   ${YELLOW}${CROWDSEC_BYTES}${NC}"
    else
      echo -e "${RED}No drop statistics available${NC}"
    fi

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
  '';

  # Make the MOTD script executable and add it to profile
  environment.interactiveShellInit = ''
    if [[ -f /etc/motd.d/10-crowdsec-stats ]]; then
      source /etc/motd.d/10-crowdsec-stats
    fi
  '';
}
