---
name: grafana-loki
description: Query Grafana Loki logs and Prometheus metrics via MCP tools. Use when asked to check logs, errors, metrics, or dashboards in Grafana. Knows the correct datasource UIDs for sipgate infrastructure.
---

# Grafana Loki & Prometheus Queries

## Datasource UIDs

Always use these UIDs — never guess or use generic names like "loki":

| Name | UID | Type | Location |
|------|-----|------|----------|
| loki-ix01 | `c683e452-1ea5-4b20-bb80-0b7eca8b43dc` | Loki | ix01 |
| loki-ml01 | `c651a657-ca0f-4f83-884c-a4dfb46d7525` | Loki | ml01 |
| loki-ix01-hepic | `d2113e56-0c7b-4204-931f-3da0e9085a7c` | Loki | ix01 hepic |
| loki-rrdns | `eb182461-aadf-429f-bf38-029837a7e9fe` | Loki | rrdns |
| sipgate App Loki | `ffbjfwockmps0c` | Loki | sipgate app |

The main "loki" datasource (uid `afh3fah7lquwwb`) has **no URL configured** and will always fail. Never use it.

## Querying Logs

### Which Loki datasource to use?

- **sipgate services (bauhaus, telco, etc.)**: Use **loki-ix01** (`c683e452-1ea5-4b20-bb80-0b7eca8b43dc`). This contains logs from both ix01 AND ml01 locations (logs are shipped to both, but ix01 is the canonical one to query).
- If a query returns no results on ix01, also try **loki-ml01** as fallback.

### LogQL Query Pattern

```
mcp({ tool: "grafana_query_loki_logs", args: '{"datasourceUid": "c683e452-1ea5-4b20-bb80-0b7eca8b43dc", "logql": "<your LogQL query>", "limit": 50}' })
```

### Common Label Selectors

- `{service="pbxcore-telco-service"}` — service name
- `{environment="live"}` or `{environment="dev"}` — environment
- `{level=~"error"}` or `{level=~"error|warn"}` — log level
- `{namespace="sg-pbxcore-telco-service"}` — k8s namespace

### Useful LogQL Patterns

```logql
# Errors for a service in live
{environment="live", level=~"error", service="pbxcore-telco-service"} | json | line_format `[{{.service}}] {{.message}}`

# Search for specific text
{service="pbxcore-telco-service"} |= "some search text"

# Error rate over time
sum(rate({service="pbxcore-telco-service", level="error"}[5m]))
```

## Querying Prometheus Metrics

Use `grafana_query_prometheus`. Find the right datasource UID first:
```
mcp({ tool: "grafana_list_datasources", args: '{"type": "prometheus"}' })
```

## Finding Dashboards

```
mcp({ tool: "grafana_search_dashboards", args: '{"query": "pbxcore"}' })
```

Then get panel queries from a dashboard:
```
mcp({ tool: "grafana_get_dashboard_panel_queries", args: '{"uid": "dashboard-uid-here"}' })
```

## Log Patterns (for anomaly detection)

```
mcp({ tool: "grafana_query_loki_patterns", args: '{"datasourceUid": "c683e452-1ea5-4b20-bb80-0b7eca8b43dc", "logql": "{service=\"some-service\", environment=\"live\"}"}' })
```

## Keeping Output Small (IMPORTANT)

The MCP tool returns the full parsed JSON including `stack_trace` fields, which can be **hundreds of lines per log entry**. This makes responses enormous and hard to read. Always minimize output:

### Default: Drop stack traces and only return messages

For an initial overview, **always** use `| json | drop stack_trace | line_format` to avoid massive output:

```logql
# GOOD — compact, readable output
{environment="live", level=~"error", service="my-service"}
  | json
  | drop stack_trace
  | line_format `{{.logger_name}}: {{.message}}`
```

```logql
# BAD — returns full stack traces, explodes response size
{environment="live", level=~"error", service="my-service"}
  | json
  | line_format `{{.message}}`
```

Note: `| json | line_format` without `drop stack_trace` still returns the full parsed JSON (including stack_trace) in the structured metadata — the `line_format` only changes the displayed line, not what Grafana returns via API.

### For counting/grouping errors (no individual logs needed)

Use metric queries instead of log queries:

```logql
# Count errors by message pattern in the last hour
sum by (level) (count_over_time({environment="live", level=~"error", service="my-service"}[1h]))
```

Or use the **patterns** endpoint for automatic clustering:
```
mcp({ tool: "grafana_query_loki_patterns", args: '{"datasourceUid": "c683e452-1ea5-4b20-bb80-0b7eca8b43dc", "logql": "{service=\"my-service\", environment=\"live\", level=\"error\"}"}' })
```

### When you DO need stack traces

Only fetch stack traces for specific sessions/errors, with low limit:
```logql
{environment="live", level=~"error", service="my-service"}
  |= "specific-session-id-or-error-text"
  | json
  | line_format `{{.message}}\n{{.stack_trace}}`
```
Use `limit: 5` or less.

## Other Tips

- Always set `limit` to 50 for log queries (default is only 10)
- For metric queries use `queryType: "instant"` for current values, `"range"` for time series
- The `line_format` template in LogQL is useful for readable output
- Use `grafana_query_loki_stats` first if you want to check how much data a selector matches before querying

## Validated Pitfalls (2026-09, BAUHAUS-3115 investigation)

These cost real detours — check this list before trusting an unexpected empty/odd result:

- **Tool routing:** via `datapls_prometheus`, LogQL (anything starting with a stream selector `{...}`) needs `action: "loki_query"`; `action: "grafana_query"` is PromQL/VictoriaMetrics only (LogQL there → 422 "cannot recognize").
- **Label names:** Prometheus metrics use `pod`/`job`/`namespace`/`instance` — `pod_name` is Loki-only. Discover with `topk(1, <metric>)`; a `by(<label>)` returning one single empty-label group means the label does not exist.
- **Retention ≈ 10 days:** an empty Loki result on an old window means nothing until a control query (`{service="..."}`, limit 1) proves logs exist there at all.
- **`limit` truncation:** a query returning exactly `limit` entries is truncated — totals belong to metric counters, not to counting log lines.
- **Lazy Micrometer counters:** tagged counters (`exception_type=...`) are created on first increment, disappear with the pod/JVM, reset on restart — so the series only exists while an error has occurred on that pod. Long-window `increase()` undercounts (observed: 155 reported vs 371 real). Enumerate with `last_over_time(<counter>[30d])` (returns dead pods' final values) and sum those.
- **Short-lived series** (<1h, e.g. a counter that only lived between two deploys) are invisible to range queries with coarse steps (each eval point looks back only 5 min). Find them with instant lookback queries (`last_over_time`, `max_over_time`) and bracket by shrinking the window.
- **CNPG:** `cnpg_backends_total` carries a `state` label (active/idle/…) — aggregate by it or you read idle pool connections as load. Several CNPG clusters share one namespace (one per k8s `cluster`: ix01/ml01/dev). Identify the primary per cluster with `cnpg_pg_replication_in_recovery == 0` before interpreting "the primary".
- **mcpScript batches:** datapls tool results arrive as `r.data.content[0].text` (JSON-in-text). Probe one call, inspect the raw shape, then loop — and include a known-positive control window in the batch so parse bugs surface as non-zero, not as silent "0".
