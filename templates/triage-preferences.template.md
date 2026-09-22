# Triage preferences

Claude reads this before every digest. It decides what gets read in full, what gets summarised, and what is skipped. It matters most when you get hundreds or thousands of messages. Edit it any time.

## Settings

| Setting | Default | Your choice |
|---|---|---|
| `media_limit` | unlimited (each digest only takes what is new since the last one) | [a number, or unlimited] |
| `include_muted` | yes, and reports mark them "(muted)" | [yes / no] |
| `include_archived` | no | [yes / no] |
| `first_run_window` | 48 hours (used only when there is no previous digest) | [for example 24 hours, 7 days] |
| `media_types` | images, PDFs and documents, voice notes. Video: audio and a few frames, if ffmpeg is installed | [list the types to open] |
| `media_keep_days` | 30 (downloaded files are deleted after this; messages are kept) | [days, or forever] |
| `digest_delivery` | in this chat | [in this chat / saved as a file each day] |
| `draft_in_app` | no (drafts are shown in the chat with Claude). Set yes to also open each 1:1 draft pre-filled and unsent in the WhatsApp desktop app, which must be installed | [yes / no] |
| `mark_as_read` | never (Claude reading a chat does not mark it read on your phone) | [never / after each digest] |
| `appear_online` | no (background sync stays quiet, you do not show as online) | [yes / no] |
| `group_actions_per_day` | 2 groups created, 10 people added | [numbers] |
| `timezone` | your computer's timezone | [for example Australia/Sydney] |
| `languages` | English for summaries and drafts; voice notes auto-detected | [languages] |
| `account_type` | detected at setup (personal or business) | [personal / business] |

## Never read or summarise

Chats and groups Claude should ignore completely. [default: none. Archived chats are skipped unless `include_archived` is yes.]

- [chat or group name]

## Priority people

Read every new message from these people in full, first, and open all their media. [default: everyone you have messaged in the last 30 days, in their own chats]

- [name]

## Watched groups

For each, Claude reports only: anything aimed at you, questions nobody answered, decisions, and tasks. Not a play by play. [default: every group not in the ignore list]

- [group name]: [what you care about in it]

## Other groups

Choose one: [summarise by search] / [skip unless someone mentions me]

## Media in groups

- From priority people and one-to-one chats: [open everything new]
- From groups: [open only if it has a caption with a question, or comes from a priority person] / [open everything] / [open nothing]. Default: the first option, but only for very busy groups (more than about 50 new messages in a digest); in quieter groups everything new is opened.

## Customer and lead chats (business accounts)

How Claude should treat chats with customers or leads. [default: treat like any other chat]

- Priority: [for example, anything asking about price, booking or a complaint goes first]
- Never reply to: [for example, spam, suppliers, group promotions]

## When and how

- Digest time: [for example, 7am on weekdays]
- Format: [for example, a short list, top five first]
