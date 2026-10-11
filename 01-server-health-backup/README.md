# Linux Server Health Monitoring and Backup Recovery

A set of Bash scripts for Ubuntu Linux that check server health, back up files with rsync, restore and verify files, and run on a schedule with cron. Built and tested in an Ubuntu VirtualBox VM as a support-engineering practice lab.

## What it does

| Script | Purpose |
|--------|---------|
| `health_check.sh` | Checks root disk usage, memory usage, load average, and whether `ssh` and `cron` are running. Logs each result as OK, WARN or ERROR with a timestamp. |
| `backup.sh` | Copies `~/data` into a timestamped folder under `~/backups` with `rsync -a`, logs the result, and deletes backups older than 7 days. |
| `restore.sh` | Restores one file from a named backup and verifies the contents with `diff`. |
| `crontab.txt` | The cron schedule: health check every 15 minutes, backup every hour. |

## Setup

1. Ubuntu 24.04 with `rsync` and `cron` installed.
2. Clone or copy the scripts, then run `chmod +x *.sh`.
3. Create test data: `mkdir -p ~/data` and add a few files.
4. Install the schedule: `crontab crontab.txt` (edit the paths to your username first).

## How I tested it

- **Health check:** set the disk threshold to 1% to force a `WARN`, then stopped `cron` with `sudo systemctl stop cron` to force an `ERROR`. Both were logged. Restored the threshold and restarted the service afterwards.
- **Backup and retention:** created a fake backup folder dated 10 days ago with `touch -d`. After running `backup.sh`, it was deleted and newer backups stayed.
- **Restore:** deleted `~/data/report.txt`, restored it from the newest backup, and `diff` confirmed identical contents. Tested wrong arguments and a missing file, which both logged an error.
- **Cron:** ran the scripts on a one- and two-minute test schedule, confirmed the logs grew without manual runs, then changed to the hourly schedule above.

Sample logs are in `evidence/`.

## Failures I reproduced and fixed

Full write-ups are in [`failures.md`](failures.md).

1. Source folder missing (renamed with `mv`)
2. Permission denied on the source folder (`chmod 000`)
3. Backup destination unavailable

## What I learned

- **[edit]** Write 2 or 3 sentences in your own words, for example what surprised you about cron needing full paths, or how the ssh socket made the service look inactive.

## Known limitations

- Backups go to the same disk as the source. A real setup needs a separate disk or remote target (the 3-2-1 rule).
- No alert is sent when a job fails. Someone has to read the logs.
- A failed rsync can leave an empty backup folder, which looks like a good backup unless opened.
- The retention rule deletes by folder age only and does not check that newer backups are valid.

## Planned improvements

- Check that the destination exists and is writable before backing up.
- Alert when the backup log contains `ERROR`.
- Back up over SSH to a second VM.
