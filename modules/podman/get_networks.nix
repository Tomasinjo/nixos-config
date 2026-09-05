{ config, pkgs, ... }:

let
  podmanGetNetworks = pkgs.writeShellScriptBin "podman-get-networks" ''
    podman network inspect $(podman network ls -q) | jq -r '
      .[] | select(.containers != null and (.containers | length > 0)) |
      (
        .containers[] | 
        "\([.interfaces[].subnets[].ipnet | select(contains("."))] | join(", ")) - \(.name)"
      ),
      ""
    '
  '';
in
{
  environment.systemPackages = [ 
    podmanGetNetworks  # This makes the 'podman-get-networks' command available in terminal
  ];
}