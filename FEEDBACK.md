# WhatsApp Agent Kit: feedback for Rob

Use this if something went wrong, or if it all worked and you want to tell Rob how it went. Claude can fill it in for you: say "fill in FEEDBACK.md". You can also fill it in by hand. Either way, you send it to Rob yourself (three ways are at the bottom). Claude never sends it for you.

## Privacy rules for this file

- Show phone numbers as the last three digits only, for example `+61 *** *** 678`.
- Never paste a pairing code, a message you do not want Rob to read, or anything from the `.wacli` folder (especially `session.db`).
- Rob only needs the facts below. You can delete any line you are not comfortable sharing.

## The basics

| Field | Your answer |
|---|---|
| Date and time (your timezone, and say which one) | |
| Your name | |
| Computer (Mac or Windows) and version | |
| Mac chip (Apple Silicon or Intel), if a Mac | |
| Account type (regular WhatsApp, WhatsApp Business app, or not sure) | |
| Claude Code Desktop version, if you know it | |
| wacli version (`wacli --version`) | |
| How wacli was installed (Homebrew, or downloaded file) | |
| Setup step you reached (the step number from the setup prompt) | |
| Did you finish setup? (yes, no, partly) | |

## `wacli doctor` output

Paste the output of `wacli doctor` here, with phone numbers cut down to the last three digits. Claude can help with this. A helper that catches most numbers (it misses numbers written with spaces, so read the result once yourself):

- Mac: `wacli doctor | sed -E 's/\+?[0-9]{8,}([0-9]{3})/***\1/g'`
- Windows PowerShell: `wacli doctor | ForEach-Object { $_ -replace '\+?\d{8,}(\d{3})','***$1' }`

```
(paste here)
```

## What you tried

Step by step, in order. Short is fine.

1.
2.
3.

## What happened

Say what you saw, and the exact wording of any error. If the phone showed something (for example a passkey prompt, "Continue on WhatsApp Web", or a linked-device limit message), write down what it said.

## Coverage output

Paste the output of `wacli history coverage` (numbers cut down as above). If you never got that far, write "not reached".

```
(paste here)
```

## Anything else

What was confusing, slow or surprising? What did you expect that did not happen? What worked better than you expected?

## Send this back to Rob

**Email.** Send this file (or paste its contents) to rob@brightcoast.ai. Put "WhatsApp Agent Kit feedback" in the subject line.
