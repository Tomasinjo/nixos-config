### Available commands
backup-services-daily
nixos-auto-deploy
backup-services-quarterly

### Daily and Weekly Backups
Alias:   backup-services-daily
Service: docker-backup

- Runs every day at 4:00.
- Shuts down database containers (ending with "-db").
- Backup according to rsnapshot config.
- Weekly is on Sunday.
- After backup service completes, auto deploy is triggered.

### Quarterly Backups
Alias:   backup-services-quarterly

Guide:
1. Connect external USB drive
2. Find device: lsblk | grep 4.5T
3. Mount: mount -t ext4 /dev/sdx /home/tom/mnt/
4. Open screen: screen -S backup
5. Run: sudo backup-services-quarterly
6. Leave screen: ctrl + a + d
7. Check after few hours: screen -r backup  (list screens: screen -ls, kill screen: ctrl + a + k)

### Updates and Auto-Deploy
Alias:   nixos-auto-deploy
Service: nixos-auto-deploy

- Triggered after daily backup, but quits if not Sunday.
- Fetches from github and rebuilds the system.
- Idea is to have renovate bot create pull requests on Github on Friday, give me 3 days to merge and then attempt to deploy it on Sunday after weekly backup.