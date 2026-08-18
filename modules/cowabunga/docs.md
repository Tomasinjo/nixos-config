Implements network ban for public IPs that generated too many 403 or 404 requests on traefik on zenki.  
HTTP 403 is caused by absence of IP on gatekeeper whitelist https://github.com/Tomasinjo/gatekeeper  

Requests are logged on traefik stdout on zenki and sent via syslog to sensei to file /var/log/offenders-ips.log  

Log example:  
{"ClientHost":"178.x.x.x","RequestHost":"xxx.xxx.xx","RequestPath":"/wp-admin.php","time":"2026-08-16T20:19:28+02:00"}  

Fail2ban monitors this file and bans IP on too many occurances.  
Gatekeeper is solid at blocking, but too many attempts bother me, that's why sensei blocks them on network level as well.  

There is also service "update-abuseipdb" that refreshes known bad IPs every day.

Check jailed ips with  
sudo nft list set inet f2b-table addr-set-offenders  

Check whole table containing jailed IP:  
sudo nft list table inet f2b-table  

Check all tables:  
sudo nft list tables  

Check shit IPs from github:  
sudo nft list set inet filter abuseipdb_blacklist  

Check all tables and chains without IP lists:  
sudo nft -t list ruleset  