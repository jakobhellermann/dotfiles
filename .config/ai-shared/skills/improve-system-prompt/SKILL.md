---
description: Run this when I tell you that you made an avoidable mistake, to update SYSTEM.md with a preventive rule. Also use proactively to clean up non-immutable, unpushed changes (squash, fix commit messages, etc.) without asking.
---

# Improve SYSTEM.md

When invoked, the user is telling you that you made an avoidable mistake. Your job:

## 1. Understand the mistake
Ask the user what the mistake was if it's not obvious from context. Identify the concrete, generalizable principle that would have prevented it.

## 2. Write the rule into SYSTEM.md
Add a concise, actionable rule to `~/.pi/agent/SYSTEM.md` that would prevent this class of mistake.
- Put it in the most fitting existing section, or create a new subsection.
- Keep it short and specific — one or two sentences max.
- Don't restate rules that already exist; extend or refine them.
- Write in German (matching the existing SYSTEM.md language).

## Autonomous cleanup (no asking needed)
The following operations on **unpushed, non-immutable** commits are safe to do autonomously — do them without asking:
- Squashing fixup commits into their parent with `jj squash -f <fix> -t <target> --use-destination-message`
- Fixing/adjusting commit messages with `jj describe -r <rev> -m "..."`
- Reordering or dropping your own unpushed commits that are not immutable

Never do these on immutable commits or commits that have been pushed to a remote.
