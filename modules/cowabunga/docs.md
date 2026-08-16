Implements network ban for public IPs that generated too many 403 or 404 requests on traefik on zenki.  
HTTP 403 is caused by absence of IP on gatekeeper whitelist https://github.com/Tomasinjo/gatekeeper  

Requests are logged on traefik stdout on zenki and sent via syslog to sensei to file /var/log/offenders-ips.log

Log example:
{"ClientHost":"178.x.x.x","RequestHost":"xxx.xxx.xx","RequestPath":"/wp-admin.php","time":"2026-08-16T20:19:28+02:00"}

Crowdsec monitors this file and bans IP on too many occurances. It also blocks IPs in community blacklist.  
Gatekeeper is solid at blocking, but too many attempts bother me, that's why sensei blocks them on network level as well.  

Check jailed ips with
sudo cscli decisions list
sudo nft list set ip crowdsec crowdsec-blacklists-crowdsec


Unban:
sudo cscli decisions delete --ip x.x.x.x

Statistics:
sudo cscli metrics

Alerts (attempts, before decision happens)
sudo cscli alerts list

General check:
sudo cscli hub list

Live drops:
sudo journalctl -k -f | grep -E "crowdsec(\[drop\]|6\[drop\])"

Live decisions:
sudo journalctl -u crowdsec-firewall-bouncer -n 50 -f

View crowdsec chains without IPs:
sudo nft -t list table ip crowdsec
sudo nft -t list table ip6 crowdsec

View drop counters for crowdsec:
sudo nft list chain ip crowdsec prerouting-drops
sudo nft list chain ip6 crowdsec prerouting-drops
