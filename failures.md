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
