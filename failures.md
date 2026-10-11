# Failure write-ups

## 1. Backup fails: source folder missing

- **Symptom:** Running `./backup.sh` printed `[ERROR] Source /home/anusha/data not found`, no new backup folder was created, and the script exited with code 1 (`echo $?` printed 1). The same error appeared in `~/logs/backup.log`.

- **Investigation:**
  - `tail -3 ~/logs/backup.log` showed the error and the time it started.
  - `ls -ld ~/data` returned "No such file or directory", so the source path was gone.
  - `ls -ld ~/data_old` showed the folder still existed under a different name.
  - `ls ~/backups` showed no new backup after the error time, so nothing was half-written.

- **Root cause:** The source folder had been renamed from `~/data` to `~/data_old` with `mv`, so the path hardcoded in `backup.sh` (`SRC="$HOME/data"`) no longer existed. Other common causes of this symptom are a deleted folder, an unmounted disk, or a wrong path in the script.

- **Fix:** Renamed the folder back with `mv ~/data_old ~/data`. Verified by running `./backup.sh`, which logged `[OK] Backup created` and exited with code 0, and by checking that `report.txt` and `notes.txt` were back in `~/data`.

- **Prevention:** The script already detects a missing source and stops, but that only helps if someone reads the log. To catch this early, add an alert when the backup log contains `ERROR` (for example a cron job that runs `grep ERROR ~/logs/backup.log` and sends mail), and a check that the newest folder in `~/backups` is less than two hours old, so a silently failing job is noticed.
## 2. Backup fails: permission denied on source folder

- **Symptom:** After `chmod 000 ~/data`, running `./backup.sh` printed an rsync "Permission denied (13)" error and logged `[ERROR] rsync failed with exit code 23`. The script itself exited with code 1. [verify: exit code 23 and the message]

- **Investigation:**
  - `tail -3 ~/logs/backup.log` showed the rsync error and exit code 23.
  - `ls -ld ~/data` showed `d---------`, so no user had any access.
  - `ls ~/data` returned "Permission denied", which confirmed the folder could not be read.
  - `ls ~/backups/<newest folder>` showed the failed run left an empty backup folder. [verify: only keep this line if you actually saw an empty folder]

- **Root cause:** The permissions on `~/data` had been changed to 000, so rsync could not open the folder to read the files. The script's existence check passed because the folder still existed, so it only failed when rsync tried to read it. Other causes of the same symptom are the wrong owner after a restore, or the job running as a different user than the one who owns the files.

- **Fix:** Restored permissions with `chmod 755 ~/data`. Verified with `ls -ld ~/data` showing `drwxr-xr-x`, then `./backup.sh` logged `[OK] Backup created` and exited with code 0, and the backup folder contained `report.txt` and `notes.txt`.

- **Prevention:** The script should also test that the source is readable (`[ -r "$SRC" ]`), not only that it exists. A failed run should not leave an empty backup folder that looks like a successful one, so writing to a temporary folder and renaming it only on success would be safer. Both are changes I would make, not features the script has now.
