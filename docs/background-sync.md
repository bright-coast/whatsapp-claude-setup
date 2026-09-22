# Background sync (optional)

Written 19 Sep 2026 for wacli 0.18.2. The Task Scheduler steps were tested on Rob's Windows 11 machine with a harmless stand-in job (not wacli itself). The lock behaviour was observed on Rob's real store on Windows with a live `sync --follow`: local reads, `send` and `media download --read-only` worked, and `contacts check`, `groups info` and `media download` without `--read-only` failed with `store is locked`. The Mac steps are **written from Apple's launchd manual pages and wacli's docs, untested on a Mac**. Anything not verified is marked `[UNVERIFIED]`.

## What this is for

By default, wacli only copies new WhatsApp messages into your local store when something runs `wacli sync`. A background sync keeps the store current all day, so a digest reads fresh data without waiting for a sync first. It does not need Claude Code or Claude Code Desktop to be open. It does need your computer to be on and awake, and you to be logged in.

You do not need this to use the kit. Skip it until the first digests work.

The command that runs in the background is:

```
wacli sync --follow --presence-mode quiet --max-db-size 2GB --lock-wait 30s
```

What each part does (from wacli's sync docs and `--help`):

| Part | Meaning |
|---|---|
| `--follow` | Keep running and reconnect after drops. This is the default for `sync`, written out so the intent is clear. |
| `--presence-mode quiet` | Do not announce this linked device as "available". wacli's docs say this is for personal-number mirrors where you want your phone to keep making notification sounds. WhatsApp decides in the end, so this is not a guarantee. |
| `--max-db-size 2GB` | Stop syncing when the message database reaches this size. It stops the sync; it does not trim anything. Text history is small, so 2GB is generous. If the job stops for this reason, you decide whether to raise the number. |
| `--lock-wait 30s` | If another wacli command holds the store lock when the job starts, wait up to 30 seconds instead of failing at once. See the lock section below. |

Do **not** add `--webhook` (it leaks media keys, wacli issue #417) and do **not** set `WACLI_READONLY=1` anywhere the sync job can see it, because a read-only wacli refuses to write the store and the sync would do nothing useful.

## How the store lock works (read this before mixing background sync with other commands)

Checked against wacli's docs (`sync.md`, `spec.md`, `media.md`, `send.md`) and its source on `main` (`internal/lock/lock.go`, `cmd/wacli/root.go`, `cmd/wacli/send.go`). The behaviour below is from documentation and code, except the rows marked verified: on 19 Sep 2026 the reads, `send`, `media download --read-only`, and the `store is locked` failures for `contacts check`, `groups info` and `media download` without `--read-only` were observed on Rob's Windows machine against a live `sync --follow`.

1. The store has one exclusive writer, a lock file called `LOCK` inside the store folder.
2. `sync --follow` holds that lock for its **entire run**. wacli's own media docs say so plainly: "A follow session holds the lock for its entire run".
3. `--lock-wait DURATION` makes a command retry the lock every 100 milliseconds until the time is up, then fail with `timed out waiting for store lock after <duration>`. Without it, a command that cannot get the lock fails at once with `store is locked (another wacli is running?)`.
4. **This means `--lock-wait` cannot help you get past a running background sync.** The sync never lets go, so the waiting command just times out later. The media docs say the same: "`--lock-wait` only turns the immediate failure into a timeout." `--lock-wait` is only useful between short one-off commands, or (as in the command above) to let the background job start when a short command happens to be running.
5. **Do not add `--lock-wait` to `wacli send`.** In the source, a send first tries to take the lock (waiting if `--lock-wait` is set) and only after that fails does it hand the send to the running sync. So `--lock-wait 30s` would add a 30 second delay to every send while the background sync is running. Plain `wacli send ...` hands over immediately.

What that means in practice, by command type:

| Command | While `sync --follow` is running |
|---|---|
| `send text` | **Works. Verified on Windows, 19 Sep 2026.** wacli hands the send to the running sync over a small local socket in the store folder. Needs the sync to have finished starting up. |
| `send file`, `send sticker`, `send voice`, `send react`, `send location`, `send poll`, `send select`, `poll vote`, `presence typing`, `presence paused`, `messages edit`, `chats mark-read`, `chats mark-unread` | **Should work.** They are on wacli's list of commands handed to a running sync (`sync.md`), but I did not run each one. After you upgrade wacli, restart the background job first, or an older sync will reject newer requests. |
| `media download <...> --read-only --output PATH` | **Works. Verified on Windows, 19 Sep 2026.** It takes no lock. (`media.md`) |
| Local reads: `messages list/search/show/context`, `chats list/show`, `groups list`, `groups participants list`, `history coverage`, `contacts search`, `doctor` (without `--connect`) | **Works. Verified on Windows, 19 Sep 2026** for `doctor`, `messages list`, `chats list`, `groups list` and `history coverage`. The source opens the others in this row without the lock too, and `spec.md` says readers can inspect the mirror while sync owns the lock. |
| `contacts check`, `groups info`, `media download` without `--read-only` | **Fails with `store is locked`. Verified on Windows, 19 Sep 2026.** |
| `groups create`, `groups participants add/remove/promote/demote`, `groups invite link get/revoke`, `groups refresh`, `groups rename/topic/description/leave/join`, `history backfill`, `media backfill`, `media retry`, `profile business`, `send status`, `doctor --connect`, `messages delete`, chat archive/pin/mute, `auth logout` | **Expected to fail** with `store is locked`. I did not run each one. They are not on wacli's list of commands handed to a running sync, and the source takes the lock for each (`profile business` needs a live connection, so it needs the lock too). Stop the background sync first (steps below), run the command, then start it again. |

The "introduce people in a new group" flow uses `contacts check`, `groups create` and `groups invite link get`, which are all in the last two rows. Stop the background sync before an intro session, and start it again afterwards. The sends inside that flow are fine either way.

## Windows (Task Scheduler through `conhost.exe --headless`)

On Rob's machine, the default terminal is Windows Terminal, which ignores `-WindowStyle Hidden` and pops up a visible window for every scheduled console job. Launching through `conhost.exe --headless` avoids that. Rob's other scheduled tasks use the same pattern.

### Install

Run in PowerShell. It assumes wacli is installed at `%LOCALAPPDATA%\wacli\bin\wacli.exe`, as the setup prompt does.

```powershell
$wacli = "$env:LOCALAPPDATA\wacli\bin\wacli.exe"
$logDir = "$env:USERPROFILE\WhatsAppAgent\logs"
New-Item -ItemType Directory -Force $logDir | Out-Null
$log = "$logDir\sync.log"

# cmd.exe /c is used so the log is plain text (PowerShell 5.1 redirection writes UTF-16).
$cmdLine = '--headless C:\Windows\System32\cmd.exe /c ""' + $wacli + '" sync --follow --presence-mode quiet --max-db-size 2GB --lock-wait 30s >> "' + $log + '" 2>&1"'

$action    = New-ScheduledTaskAction -Execute 'C:\Windows\System32\conhost.exe' -Argument $cmdLine
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'WhatsAppAgent-Sync' -Action $action -Trigger $trigger -Settings $settings -Principal $principal
```

Two settings matter and are easy to miss:

- `-ExecutionTimeLimit ([TimeSpan]::Zero)` switches off Task Scheduler's default "stop the task after 3 days". Without it, the sync would be killed every 72 hours. (Rob's existing tasks show `ExecTimeLimit=PT72H`, the default. I checked that this setting produces `PT0S`, meaning no limit.)
- `-MultipleInstances IgnoreNew` stops a second copy starting if one is already running.

### Start, verify

```powershell
Start-ScheduledTask -TaskName 'WhatsAppAgent-Sync'

Get-ScheduledTask -TaskName 'WhatsAppAgent-Sync' | Select-Object TaskName, State
Get-ScheduledTaskInfo -TaskName 'WhatsAppAgent-Sync' | Select-Object LastRunTime, LastTaskResult
Get-CimInstance Win32_Process -Filter "Name='wacli.exe'" | Select-Object ProcessId, CommandLine
Get-Content "$env:USERPROFILE\WhatsAppAgent\logs\sync.log" -Tail 20
wacli doctor
```

- `State` is `Running` while it works. `LastTaskResult` of `267009` (0x41301) means "still running", which is normal for this job.
- The `Get-CimInstance` line should show one `wacli.exe` whose command line contains `sync --follow`.
- `wacli doctor` reports the lock holder. `wacli doctor --json` includes `store.last_activity_at` when a sync follow process is writing its heartbeat file (wacli's doctor docs). A quiet, healthy session may not update it every minute, so a stale value alone is not proof of failure.

### Stop (pause), resume, turn off

**Stopping the scheduled task does not stop wacli.** I tested this on Rob's machine with a stand-in program launched the same way: after `Stop-ScheduledTask` reported the task as `Ready`, the program it had launched was still running. For wacli that means the store lock would still be held. So always stop both.

```powershell
# Pause (for example before a group command)
Stop-ScheduledTask -TaskName 'WhatsAppAgent-Sync'
Get-CimInstance Win32_Process -Filter "Name='wacli.exe'" | Select-Object ProcessId, CommandLine
# Find the row whose CommandLine contains "sync --follow", then stop that one process by its ProcessId:
Stop-Process -Id <ProcessId>

# Resume
Start-ScheduledTask -TaskName 'WhatsAppAgent-Sync'

# Turn off for good (it will not start at logon any more)
Disable-ScheduledTask -TaskName 'WhatsAppAgent-Sync'
```

`Stop-Process` ends wacli abruptly. wacli's sync docs say interrupted recovery work is replayed at the next start, and its store is SQLite, but I did not test an abrupt kill of wacli itself. `[UNVERIFIED]`

Do not stop it by process name across the board if you have run wacli by hand in another window; pick the `ProcessId` of the sync job only.

### Uninstall

```powershell
Stop-ScheduledTask -TaskName 'WhatsAppAgent-Sync'
# then stop the wacli.exe process as above, then:
Unregister-ScheduledTask -TaskName 'WhatsAppAgent-Sync' -Confirm:$false
```

### Upgrading wacli on Windows

Stop the job and the `wacli.exe` process first, because Windows will not overwrite a running `.exe`. After replacing the file, start the job again so the running sync is the new version.

## macOS (launchd LaunchAgent)

A LaunchAgent runs for your user while you are logged in. It does not run while the Mac is asleep or when nobody is logged in.

### Work out the path to wacli

The plist needs an **absolute** path. launchd's manual does not say whether `~` or `$HOME` are expanded, so do not use them.

| How wacli was installed | Path to put in the plist |
|---|---|
| Homebrew on Apple Silicon | `/opt/homebrew/bin/wacli` |
| Homebrew on an Intel Mac | `/usr/local/bin/wacli` |
| The tar.gz from GitHub, copied to `~/.local/bin` (the setup prompt's route) | `/Users/<your username>/.local/bin/wacli` |

Confirm in Terminal with `command -v wacli`. For Homebrew, `$(brew --prefix)/bin/wacli` gives the same answer on both chip types. Replace `YOURNAME` below with your macOS username (the output of `whoami`).

### Install

Save this as `~/Library/LaunchAgents/ai.brightcoast.wacli-sync.plist`, with `WACLI_PATH` and `YOURNAME` replaced.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>ai.brightcoast.wacli-sync</string>
  <key>ProgramArguments</key>
  <array>
    <string>WACLI_PATH</string>
    <string>sync</string>
    <string>--follow</string>
    <string>--presence-mode</string>
    <string>quiet</string>
    <string>--max-db-size</string>
    <string>2GB</string>
    <string>--lock-wait</string>
    <string>30s</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>/Users/YOURNAME</string>
    <key>WACLI_STORE_DIR</key>
    <string>/Users/YOURNAME/.wacli</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <dict>
    <key>SuccessfulExit</key>
    <false/>
  </dict>
  <key>ThrottleInterval</key>
  <integer>120</integer>
  <key>StandardOutPath</key>
  <string>/Users/YOURNAME/WhatsAppAgent/logs/sync.log</string>
  <key>StandardErrorPath</key>
  <string>/Users/YOURNAME/WhatsAppAgent/logs/sync.log</string>
</dict>
</plist>
```

Why these choices (keys checked against Apple's `launchd.plist(5)` page):

- `KeepAlive` with `SuccessfulExit` set to false means launchd restarts the job only when it exits with an error. wacli's docs say that when WhatsApp logs the session out, sync "exits cleanly", so a logged-out session is not restarted in a loop. That matches the kit's "log out means stop" rule. Do not change this to a plain `KeepAlive` of true.
- `ThrottleInterval` of 120 seconds spaces out restarts after a failure.
- `HOME` and `WACLI_STORE_DIR` are set explicitly because launchd's manual does not say what environment a LaunchAgent gets. Setting them removes the guess. `[UNVERIFIED]` whether they are needed.
- `RunAtLoad` starts it at login and when you load it.

Then in Terminal:

```sh
mkdir -p ~/Library/LaunchAgents ~/WhatsAppAgent/logs
plutil -lint ~/Library/LaunchAgents/ai.brightcoast.wacli-sync.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.brightcoast.wacli-sync.plist
```

`plutil -lint` should print `OK`. `bootstrap` loads it and, because of `RunAtLoad`, starts it. On some macOS versions the system may show a "background item added" notice for a new LaunchAgent. `[UNVERIFIED]`

### Verify

```sh
launchctl print gui/$(id -u)/ai.brightcoast.wacli-sync
launchctl list | grep wacli
tail -n 20 ~/WhatsAppAgent/logs/sync.log
wacli doctor
```

`launchctl print` shows the state and process ID. `launchctl list` shows three columns: process ID, last exit status and label. A process ID present means it is running. `wacli doctor` reports the lock holder.

### Stop (pause), restart, turn off

`launchctl bootout` stops the job (launchd sends the process SIGTERM, then SIGKILL after a wait), and wacli's source handles SIGTERM as a normal shutdown. `[UNVERIFIED]` by a live test.

```sh
# Pause (for example before a group command)
launchctl bootout gui/$(id -u)/ai.brightcoast.wacli-sync

# Resume
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.brightcoast.wacli-sync.plist

# Restart now (also needed after upgrading wacli)
launchctl kickstart -k gui/$(id -u)/ai.brightcoast.wacli-sync

# Keep it off across logins without deleting the file
launchctl disable gui/$(id -u)/ai.brightcoast.wacli-sync
```

`bootout` unloads it for this login session only. Because the plist stays in `LaunchAgents`, it comes back at the next login unless you disable or remove it. To re-enable after `disable`, run `launchctl enable gui/$(id -u)/ai.brightcoast.wacli-sync`, then `bootstrap` again.

### Uninstall

```sh
launchctl bootout gui/$(id -u)/ai.brightcoast.wacli-sync
rm ~/Library/LaunchAgents/ai.brightcoast.wacli-sync.plist
```

### Upgrading wacli on a Mac

Homebrew: `brew upgrade wacli`, then `launchctl kickstart -k gui/$(id -u)/ai.brightcoast.wacli-sync`. Tarball install: replace the file in `~/.local/bin`, then run the same `kickstart`. wacli's docs say routine upgrades do not need re-pairing.

## Using it with Claude

- Digests read the local store, so they work with or without the background job. With it running, Claude should not run `wacli sync --once` (it would fail on the lock); it just reads.
- The permission rules in the project's `.claude/settings.json` ask before `wacli sync *`, so Claude will not start or stop a sync without you clicking Allow.
- **Claude Code Desktop's "Routines" (scheduled tasks) are a different thing.** A local scheduled task only runs while the Desktop app is open and the computer is awake (Claude Code docs, "Schedule recurring tasks in Claude Code Desktop"). If you want a scheduled daily digest, a Routine can trigger it, but keep the sync in launchd or Task Scheduler, which do not need the app.
- For an unattended digest that must never write, you can start its `wacli` commands with `WACLI_READONLY=1`. Never set that for the sync job. Do not use it in ordinary interactive sessions either: an allow rule does not match a command with an environment variable in front, so every read would prompt (ask and deny rules still match). `[UNVERIFIED]` how a Routine's permission settings treat a prefixed command.

## Not verified

1. Everything on the macOS side (plist, `launchctl` commands, SIGTERM handling, the background-item notice) is from documentation only.
2. Observed on Windows, 19 Sep 2026, with a live `sync --follow` running: `doctor`, `messages list`, `chats list`, `groups list` and `history coverage` all answered in about 70 ms, `send` and `media download --read-only` worked, and `contacts check`, `groups info` and `media download` without `--read-only` failed with `store is locked`. Not yet observed on a Mac. The commands in the last row of the lock table were not run one by one.
3. wacli's exit code when it gives up reconnecting (after `--max-reconnect`, default 5 minutes) or when `--max-db-size` is reached. The Windows `-RestartCount 3` and the macOS `SuccessfulExit false` rule assume a non-zero exit for real failures.
4. Whether an abrupt `Stop-Process` on Windows leaves the store clean.
5. Log growth. wacli writes progress lines to the log; I do not know the rate. Check the size of `sync.log` after a week.
