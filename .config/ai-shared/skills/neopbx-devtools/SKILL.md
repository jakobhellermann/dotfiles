---
name: neopbx-devtools
description: Inspect calls, routing, and sessions via NeoPBX DevTools MCP servers (dev and live). Use when asked to look up a call/session, check routing for an account or number, list active calls, or search sessions by text.
---

# NeoPBX DevTools

Two MCP servers with identical tools, one per environment:

| Environment | Server name | Tool prefix |
|-------------|-------------|-------------|
| **DEV** | `neopbx-devtools-dev` | `neopbx_devtools_dev_*` |
| **LIVE** | `neopbx-devtools-live` | `neopbx_devtools_live_*` |

**Always pick the server matching the environment the data comes from.**
If you found an error in Loki with `environment="live"`, use the `live` tools. For `environment="dev"`, use the `dev` tools.

## Typical Workflows

### Investigate an error from Grafana/Loki logs

1. Find `sessionId` in the Loki log entry's parsed fields
2. `getCall` with that sessionId to see full event journal + errors
3. Check `errorLogs` and `eventJournal` in the response for root cause

### Check why a number isn't routing correctly

1. `getNumberRouting` with the E.164 number (no leading `+`)
2. If you need the full account config: `getAccountRouting` with the accountId from the routing result

### Find sessions related to a specific issue

1. `searchSessions` with a descriptive query (error message, phone number, callSid, etc.) and a time range
2. Then `getCall` on interesting session IDs from the results
