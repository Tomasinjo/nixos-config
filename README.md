# Lenko: Thinkpad T14 Gen 4

[lenko/configuration.nix](hosts/lenko/configuration.nix)
[home-manager/hosts/lenko/default.nix](home-manager/hosts/lenko/default.nix)

- [Niri](home-manager/modules/desktop/niri/niri.nix) + [Noctalia](home-manager/modules/desktop/niri/noctalia.nix)
- Docker container support
- Virtual machine management via virt-manager
- KDE Connect
- [Printing support](modules/printing.nix)
- WireGuard VPN
- [Firefox](home-manager/modules/desktop/firefox/firefox-base.nix) with [addons](home-manager/modules/desktop/firefox/extensions.nix), [bookmarks generated](home-manager/modules/desktop/firefox/bookmarks.nix) from labels of [oci-container]().
- [VScode with addons]()
- [Yazi](home-manager/modules/yazi.nix)
- [Kitty](home-manager/modules/desktop/kitty.nix)

<img src="pics/lenko_screenshot.png" width="800">


# Zenki: 4U Server

[zenki/configuration.nix](hosts/zenki/configuration.nix)
[home-manager/hosts/zenki/default.nix](home-manager/hosts/zenki/default.nix)

- 14600K
- 64GB DDR4
- 2x 4TB HDD, ZFS mirror
- 1x 16TB HDD, ZFS, multimedia, backups, frigate recordings
- 1x 1TB SSD, ext4, boot drive
- 1x 500GB SSD, ext4, games
- RTX 3090, for local LLMs and gaming
- Coral mini PCI-e, for frigate object detection

### Podman services
Runs 40+ containers defined in service.nix in [apps/](apps/) directory. Each service definition is merged with one or more templates in [oci-framework.nix](modules/podman/oci-framework.nix), which ensures each container is hardened and generally setup in the same way. Overrides are possible at service.nix level if needed (e.g. if container requires running as root). If container is merged with web.* preset, traefik is also configured if web access is required. Wildcard public DNS entry and TLS certs are configured so no additional setup is needed. Oci-framework also provides standard database (postgres) config and hardware access presets.

### Networking 
Container networks have NAT disabled completely and containers are assigned with static private IPv4 and static globally routed IPv6. The IP is contructed from serviceId (set in each service.nix) and containerId (auto assigned 2 for web apps and 3 for databases). 

IPv4 network: 10.0.0.0/16  
IPv4 stack network: 10.0.xxx.0/24  

IPv6 network: abcd:abcd:abcd:ff00::/64  
IPv6 stack network: abcd:abcd:abcd:ff00:1xxx::/80  

.. where xxx is service ID  

Those networks are routed by zenki and sensei has static route for them. 

Advantages of such network setup: It gives me full control which containers can talk with each container. This applies only to cross-stack communication since containers in same stack (same serviceId/same service.nix) are part of the same L2 domain. Rules are defined in [networking.nix](hosts/zenki/networking.nix). By passing requiresInternet as "true" in service.nix, the container gets ability to talk outbound, evaluated and enforced by sensei. Furthermore, [suricata](hosts/sensei/suricata.nix) is able to log flows and generated alert with true source IP.

Disadvantages: Each container exposes all ports and are accessible by every machine on the network if not limited. Since this represents an attack vector, sensei limits conectivity to these sockets. Prefered way of accessing the services in thru traefik. 

### Backups
Services' data ([apps/](apps/)) is backed up daily at 4:00 using rsnapshot to 16TB drive. Database containers are shut down before backup to avoid corrupted backups. Process is logged to journald which is sent to victorialogs using vector. Data is monitored by Grafana which sends an alert to telegram if process fails. [podman/backup-daily-weekly.nix](/home/tom/nixos-config/modules/podman/backup-daily-weekly.nix)

Container data of highest value ([immich](apps/immich/service.nix), [paperless](apps/paperless/service.nix), [opencloud](apps/cloud/opencloud/service.nix)) is mounted from mirrored 4TB drives. Backup is implemented using ZFS snapshots which are transfered to 16TB drive daily. [zfs/backup-daily.nix](modules/zfs/backup-daily.nix)

Offsite backup is done quarterly using external HDD, phisically brought every quarter for backup process and then sent to remote location [podman/backup-quarterly.nix](modules/podman/backup-quarterly.nix), [zfs/backup-quarterly.nix](modules/zfs/backup-quarterly.nix).

### Container image updates
[Renovate](renovate.json) checks for updates every Friday and opens pull requests on Github for images that have updates available. It is expected of me to merge them until Sunday morning when the new nixos config is pulled from Github. This process is initiated by completed daily backup at 4:00 (after podman-backup.service), in [deploy.nix](modules/podman/deploy.nix). This allows me to have most recent backup ready if something breaks.

### Nvidia
RTX 3090 is used for ollama and gaming. It has issues with high idling (~30W). To mitigate it, a service checks for high power during idle (P8 state, no running processes, power > 24W) and puts the card to suspended state for a second and then restores it. This procedure re-sets the power back to 14W. [idle_power_reset.nix](modules/hardware/nvidia/idle_power_reset.nix)

Custom fan curve is set because I find the default too conservative. My server is in the basement so I don't care about the noise. To set up the custom fan curve I use [my fork of ZanMax/nvidia-fan-control](https://github.com/Tomasinjo/nvidia-fan-control). I added ability to spin down fan to 0% by giving the fan control back to driver when fan speed is supposed to be 0.

The same fan curve profile is also applied to a case fan dedicated to graphic card. 
[nvidia-fan-control.nix](modules/hardware/nvidia/nvidia-fan-control.nix)

### Game mode
Most of the time, I want zenki to be as efficient as possible. CPU is put to most conservative power mode after boot which achieves power consumption of ~10W. However, during gaming, I need full performance. This is handled by game mode which detects game automatically (Steam, Lutris). It puts CPU to performance mode and shuts down ollama container which might eat up most of the VRAM. Stopping the game reverses the operation. [gamemode.nix](modules/gaming/gamemode.nix), [efficiency.nix](modules/hardware/intel/efficiency.nix)

### Intel QSV
Some workloads are hardware accelerated using iGPU:
- jellyfin, transcoding
- frigate, transcoding
- immich, machine learning, transcoding
[intel-qsv.nix](modules/hardware/intel/intel-qsv.nix)

### External access to services
Traefik is exposed outbound via port forwarding or directly for IPv6. It allows 403 forbidden unless the public IP is whitelisted. In order for IP to get whitelisted, it needs at least one successful authentication to Home Assistant using mTLS.
[traefik/service.nix](apps/traefik/service.nix)
https://github.com/Tomasinjo/gatekeeper

 
### Hyprland
Minimal hyprland + rofi is used just to launch Steam / Lutris. It is rendered by iGPU while 3090 is used for running games. 30 meters of HDMI and USB cables is used to transfer image from basement to office monitor.
[hyprland/](home-manager/modules/desktop/hyprland/)

# Sensei: Router

[sensei/configuration.nix](hosts/sensei/configuration.nix)

Qotom Q510G6, Celeron 3855U 2c 1.6GHz, 16GB DDR4

###  Networks
- VLAN 10: User devices, including TV and chromecast speakers.
- VLAN 20: Guests, open wifi
- VLAN 30: IoT devices, IPv4 only
- VLAN 40: Zenki - server
- 10.0.0.0/16: Podman containers, routed via VLAN 40, access allowed only from 1 machine
- Wireguard, allowed everywhere
- VLAN 99, native, assigned on LACP, hosts network services and SSH.
[sensei/networking.nix](hosts/sensei/networking.nix)

### Kea DHCP
Assigns IPv4 addresses, sets static assignments according to net.nix
[kea.nix](hosts/sensei/kea.nix)

### Unbound DNS
DNS forwarder, listens on 99.10 and 99::10. Implements DoT to upstream 1.1.1.1. Provides ad and malware blocking using hagezi blocklists.
[unbound.nix](hosts/sensei/unbound.nix)

### nftables
Network policy [nftables.nix](hosts/sensei/nftables.nix) and threat intel IP blocking [shit_list.nix](modules/cowabunga/shit_list.nix).


# Boarder: Wall mounted Home assistant dashboard and photoframe

[boarder/configuration.nix](hosts/boarder/configuration.nix)

N100 mini PC behind UPERFECT 15.6 inch touchscreen. 

Uses sway at boot to launch Chromium in kiosk mode and opens Home Assistant. Photoframe functionality is provided by Browsermod and Wallpanel integrations to disply images and videos from Immich.

Error detection is implemented by checking current URL in Chromium and by running a simple javascript. If error is detected, the machine is rebooted.

To save energy, the system is put to sleep at midnight for 7 hours.
[kiosk.nix](modules/desktop/kiosk.nix)
