# wacli 0.18.2 command reference (verified from `--help` on Windows 11, 19 Sep 2026)

Raw help output, trimmed of the repeated Global Flags block (see bottom). Re-verify after upgrading wacli.

## wacli messages

```
List and search messages from the local DB

Usage:
  wacli messages [command]

Available Commands:
  context     Show message context around a message ID
  delete      Delete a message for everyone or for you
  edit        Edit one of your recent sent text messages
  export      Export messages as JSON
  forward     Forward a stored message
  list        List messages
  purge       Permanently remove one tombstoned message payload
  revoke      Delete one of your sent messages for everyone
  search      Search messages (FTS5 if available; otherwise LIKE)
  show        Show one message
  starred     List starred messages

Flags:
  -h, --help   help for messages
```

## wacli messages list

```
List messages

Usage:
  wacli messages list [flags]

Flags:
      --after string    only messages after time (RFC3339 or YYYY-MM-DD)
      --asc             show oldest messages first (default: newest first)
      --before string   only messages before time (RFC3339 or YYYY-MM-DD)
      --chat string     filter by chat JID
      --forwarded       only forwarded messages
      --from-me         only messages sent by me
      --from-them       only messages received (not sent by me)
  -h, --help            help for list
      --limit int       max number of messages to return (default 50)
      --sender string   filter by sender JID
      --starred         only starred messages
```

## wacli messages search

```
Search messages (FTS5 if available; otherwise LIKE)

Usage:
  wacli messages search <query> [flags]

Flags:
      --after string    only messages after time (RFC3339 or YYYY-MM-DD)
      --before string   only messages before time (RFC3339 or YYYY-MM-DD)
      --chat string     chat JID
      --forwarded       only forwarded messages
      --from string     sender JID
      --has-media       only messages with media
  -h, --help            help for search
      --limit int       limit results (default 50)
      --starred         only starred messages
      --type string     message type filter (text|image|video|audio|document)
```

## wacli messages show

```
Show one message

Usage:
  wacli messages show [flags]

Flags:
      --chat string   chat JID
  -h, --help          help for show
      --id string     message ID
```

## wacli messages context

```
Show message context around a message ID

Usage:
  wacli messages context [flags]

Flags:
      --after int     messages after (default 5)
      --before int    messages before (default 5)
      --chat string   chat JID
  -h, --help          help for context
      --id string     message ID
```

## wacli chats list

```
List chats

Usage:
  wacli chats list [flags]

Flags:
      --archived       show only archived chats
  -h, --help           help for list
      --limit int      limit (default 50)
      --muted          show only muted chats
      --no-archived    exclude archived chats
      --no-muted       exclude muted chats
      --no-pinned      exclude pinned chats
      --no-unread      exclude unread chats
      --pinned         show only pinned chats
      --query string   search query
      --unread         show only unread chats
```

## wacli chats show

```
Show one chat

Usage:
  wacli chats show [flags]

Flags:
  -h, --help         help for show
      --jid string   chat JID
```

## wacli send text

```
Send a text message

Usage:
  wacli send text [flags]

Flags:
      --allow-self                  allow sending to the linked account itself (delivery is not guaranteed)
      --ephemeral                   send with the disappearing-message timer for this chat
      --ephemeral-duration string   disappearing-message timer override (for example 24h, 7d, 90d, 168h)
  -h, --help                        help for text
      --mention stringArray         phone number or user JID to mention (repeatable)
      --message string              message text
      --message-escapes             interpret backslash escapes in --message (\n, \r, \t, \\, \")
      --no-preview                  disable automatic link previews for the first URL in text
      --pick int                    when --to is ambiguous, pick the Nth match (1-indexed)
      --post-send-wait duration     keep the connection alive after send so retry receipts can be handled (0 disables) (default 2s)
      --reply-to string             message ID to quote/reply to
      --reply-to-sender string      sender JID of the quoted message (required for unsynced group replies)
      --to string                   recipient JID, phone number, or contact/group/chat name
```

## wacli send file

```
Send a file (image/video/audio/document)

Usage:
  wacli send file [flags]

Flags:
      --as string                 force WhatsApp media type (auto|document|audio|image|video) (default "auto")
      --caption string            caption (images/videos/documents)
      --file string               path to file
      --filename string           display name for the file (defaults to basename of --file)
  -h, --help                      help for file
      --mime string               override detected mime type
      --pick int                  when --to is ambiguous, pick the Nth match (1-indexed)
      --post-send-wait duration   keep the connection alive after send so retry receipts can be handled (0 disables) (default 2s)
      --ptt                       send OGG/Opus audio as a WhatsApp voice note
      --reply-to string           message ID to quote/reply to
      --reply-to-sender string    sender JID of the quoted message (required for unsynced group replies)
      --to string                 recipient JID, phone number, or contact/group/chat name
```

## wacli send voice

```
Send a voice note

Usage:
  wacli send voice [flags]

Flags:
      --file string               path to OGG/Opus audio file
  -h, --help                      help for voice
      --mime string               override detected mime type
      --pick int                  when --to is ambiguous, pick the Nth match (1-indexed)
      --post-send-wait duration   keep the connection alive after send so retry receipts can be handled (0 disables) (default 2s)
      --reply-to string           message ID to quote/reply to
      --reply-to-sender string    sender JID of the quoted message (required for unsynced group replies)
      --to string                 recipient JID, phone number, or contact/group/chat name
```

## wacli groups list

```
List known groups (from local DB; run sync to populate)

Usage:
  wacli groups list [flags]

Flags:
  -h, --help           help for list
      --limit int      maximum groups to return (non-positive values use 50) (default 50)
      --query string   search query
```

## wacli groups info

```
Fetch group info (live) and update local DB

Usage:
  wacli groups info [flags]

Flags:
  -h, --help         help for info
      --jid string   group JID (…@g.us)
```

## wacli groups create

```
Create a group

Usage:
  wacli groups create [flags]

Flags:
      --announce-only          only admins can send messages
      --community              create a community parent group
  -h, --help                   help for create
      --join-approval          require admin approval for new join requests
      --linked-parent string   community parent group JID for a new subgroup
      --locked                 only admins can edit group info
      --name string            group name
      --user strings           initial participant phone number (+E164 and formatting ok) or JID (repeatable)
```

## wacli groups participants add

```
add participants

Usage:
  wacli groups participants add [flags]

Flags:
  -h, --help           help for add
      --jid string     group JID (…@g.us)
      --user strings   user phone number (+E164 and formatting ok) or JID (repeatable)
```

## wacli groups invite link

```
Get or revoke invite links

Usage:
  wacli groups invite link [command]

Available Commands:
  get         Get invite link
  revoke      Revoke/reset invite link

Flags:
  -h, --help   help for link
```

## wacli groups refresh

```
Fetch joined groups (live) and update local DB

Usage:
  wacli groups refresh [flags]

Flags:
  -h, --help   help for refresh
```

## wacli contacts check

```
Query WhatsApp's servers whether each phone number is registered.
Accepts +E164 numbers, common formatting, or user JIDs.
Connects with the account session; results are not stored locally.

Usage:
  wacli contacts check <phone> [phone...] [flags]

Flags:
  -h, --help   help for check
```

## wacli contacts search

```
Search contacts (from synced metadata)

Usage:
  wacli contacts search <query> [flags]

Flags:
  -h, --help        help for search
      --limit int   limit results (default 50)
```

## wacli history coverage

```
Show local archive coverage by chat

Usage:
  wacli history coverage [flags]

Flags:
      --chat strings      chat JID to inspect (repeatable)
  -h, --help              help for coverage
      --include-blocked   include chats without a local message anchor
      --kind string       chat kind filter (dm|group|broadcast|newsletter|unknown)
      --limit int         limit rows (default 100)
      --only-actionable   show only chats with a local message anchor
      --query string      filter chats by local name or JID
```

## wacli history backfill

```
Request older messages for a chat from your primary device (on-demand history sync)

Usage:
  wacli history backfill [flags]

Flags:
      --chat string          chat JID
      --count int            number of messages to request per on-demand sync (default 50)
  -h, --help                 help for backfill
      --idle-exit duration   exit after being idle (after backfill requests) (default 5s)
      --requests int         number of history batches to request (each may retry once after a timeout) (default 1)
      --wait duration        time to wait for an on-demand response per request (default 1m0s)
```

## wacli media download

```
Download media for a message

Usage:
  wacli media download [flags]

Flags:
      --chat string     chat JID
  -h, --help            help for download
      --id string       message ID
      --output string   output file or directory (default: store media dir)
```

## wacli sync

```
Sync messages (requires prior auth; never shows QR)

Usage:
  wacli sync [flags]

Flags:
      --download-media             download media in the background during sync
      --follow                     keep syncing until Ctrl+C (default true)
  -h, --help                       help for sync
      --idle-exit duration         exit after being idle (once mode) (default 30s)
      --max-db-size string         maximum wacli.db disk usage before sync stops, e.g. 500MB or 2GB (default: WACLI_SYNC_MAX_DB_SIZE or unlimited)
      --max-messages int           maximum total messages to keep in the local DB before sync stops (0 = unlimited, or WACLI_SYNC_MAX_MESSAGES)
      --max-reconnect duration     give up reconnecting after this duration (0 = unlimited) (default 5m0s)
      --once                       sync until idle and exit
      --presence-mode string       global sync presence behavior: normal or quiet (default "normal")
      --refresh-channels           refresh subscribed channels (live) into local DB
      --refresh-contacts           refresh contacts from session store into local DB
      --refresh-groups             refresh joined groups and participant snapshots (live)
      --send-spacing string        pace delegated sends in follow mode by a fixed duration or random min-max range (e.g. 2s or 500ms-5s; default: disabled)
      --stale-threshold duration   force reconnect when keepalive failures last this long in follow mode (1s-<2m20s, 0 = disabled)
      --webhook string             URL to POST live message JSON
      --webhook-allow-private      allow webhook URLs that resolve to localhost or private networks
      --webhook-events string      comma-separated event types to POST: message, receipt, chat_presence (default "message")
      --webhook-secret string      HMAC-SHA256 secret for X-Wacli-Signature header
```

## wacli auth

```
Authenticate with WhatsApp (QR) and bootstrap sync

Usage:
  wacli auth [flags]
  wacli auth [command]

Available Commands:
  logout      Logout (invalidate session)
  status      Show authentication status

Flags:
      --download-media       download media in the background during sync
      --follow               keep syncing after auth
  -h, --help                 help for auth
      --idle-exit duration   exit after being idle (bootstrap/once modes) (default 30s)
      --phone string         pair by phone number instead of QR code
      --qr-format string     QR output format: terminal or text (default "terminal")
```

## wacli doctor

```
Diagnostics for store/auth/search

Usage:
  wacli doctor [flags]

Flags:
      --connect   try connecting to WhatsApp (requires store lock)
  -h, --help      help for doctor
```

## Global flags (all commands)

```
--account string  named account from config.yaml
--events  NDJSON lifecycle events on stderr
--full  disable table truncation
--json  JSON output
--lock-wait duration  wait for store lock (write commands)
--read-only  reject commands that write WhatsApp or the local store (or WACLI_READONLY=1)
--store string  store directory (default $WACLI_STORE_DIR or ~/.wacli)
--timeout duration  command timeout for non-sync commands (default 5m)
```

---

# Added 19 Sep 2026 after the independent review (commands the skill and settings name that were missing above)

## wacli media retry

```
For media that expired off WhatsApp's CDN, ask the primary device (phone)
to re-upload it via the media-retry protocol, then download it. Receipts are
sent in batches with a second attempt for non-responders; media the phone no
longer holds is marked so it is not retried again. Only works while the phone
is online and still has the media.

Usage:
  wacli media retry [flags]

Flags:
      --batch int       number of retry receipts to send per batch (default 32)
      --before string   only retry media older than this date (YYYY-MM-DD)
      --chat string     limit retry to a single chat JID
  -h, --help            help for retry
      --limit int       maximum number of messages to retry (0 = all pending)
      --wait duration   how long to wait for the phone per attempt (default 30s)
```

## wacli media backfill

```
Fetch media for messages already stored in the local database that have
downloadable metadata but no local file yet. Unlike `sync --download-media`,
which only downloads media for messages arriving during the sync, this scans
existing rows and downloads them over a single connection.

Usage:
  wacli media backfill [flags]

Flags:
      --chat string   limit backfill to a single chat JID
  -h, --help          help for backfill
      --limit int     maximum number of media files to download (0 = all)
      --workers int   number of concurrent downloads (default 4)
```

## wacli profile business

```
Fetch a WhatsApp business profile

Usage:
  wacli profile business --jid <jid-or-phone> [flags]

Flags:
  -h, --help         help for business
      --jid string   target JID or phone number
```

## wacli groups rename

```
Rename group

Usage:
  wacli groups rename [flags]

Flags:
  -h, --help          help for rename
      --jid string    group JID (…@g.us)
      --name string   new name
```

## wacli groups join

```
Join group by invite code

Usage:
  wacli groups join [flags]

Flags:
      --code string   invite code (from link)
  -h, --help          help for join
```

## wacli groups leave

```
Leave a group

Usage:
  wacli groups leave [flags]

Flags:
  -h, --help         help for leave
      --jid string   group JID (…@g.us)
```

## wacli groups participants list

```
List participants from the last group snapshot saved in the local database.

This command does not connect to WhatsApp. The snapshot can be empty or stale.
Run "wacli sync --once --refresh-groups" to fetch joined groups and replace
their local participant snapshots.

Usage:
  wacli groups participants list [flags]

Flags:
  -h, --help         help for list
      --jid string   group JID (…@g.us)
```

## wacli groups invite link get

```
Get invite link

Usage:
  wacli groups invite link get [flags]

Flags:
  -h, --help         help for get
      --jid string   group JID (…@g.us)
```

## wacli chats mark-read

```
Mark a chat as read

Usage:
  wacli chats mark-read [flags]

Flags:
      --chat string   chat name, phone number, or JID
  -h, --help          help for mark-read
      --pick int      choose match N when --chat is ambiguous
```

## wacli doctor

```
Diagnostics for store/auth/search

Usage:
  wacli doctor [flags]

Flags:
      --connect   try connecting to WhatsApp (requires store lock)
  -h, --help      help for doctor
```

## wacli auth status

```
Show authentication status

Usage:
  wacli auth status [flags]

Flags:
  -h, --help   help for status
```
