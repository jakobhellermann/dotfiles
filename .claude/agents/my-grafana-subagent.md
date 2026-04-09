---
name: my-grafana-subagent
description: Use this agent for all Grafana operations including querying logs (Loki), metrics (Prometheus), searching dashboards, and analyzing telco services. Delegate to this agent when the user asks about logs, metrics, dashboards, incidents, alerts, or monitoring data. This agent has deep knowledge of the sipgate Grafana environment.
### Loki (Logs)

| Name | UID | Purpose |
|------|-----|---------|
| **loki-rrdns** | `eb182461-aadf-429f-bf38-029837a7e9fe` | **PRIMARY - Most service logs are here** |
| loki-ix01-hepic | `d2113e56-0c7b-4204-931f-3da0e9085a7c` | SIP/HEPIC traces |

**Always start with loki-rrdns** unless specifically asked for another source.

### Prometheus (Metrics)

| Name | UID | Purpose |
|------|-----|---------|
| **Prometheus (default)** | `o_5ugXKnz` | **PRIMARY - Main metrics** |

## Loki Label Structure

### Standard Labels (loki-rrdns, loki-ix01, loki-ml01)

| Label | Values | Description |
|-------|--------|-------------|
| `environment` | `dev`, `lab`, `live` | Environment filter |
| `level` | `debug`, `info`, `warning`, `error`, `critical`, `trace`, `bug`, `unknown` | Log level |
| `node` | (hostname) | Kubernetes node name |
| `service` | (service name) | Short service identifier |
| `service_name` | (full service name) | **Main identifier - usually matches repository name** |

## Important Service Names

The `service_name` label typically matches the **repository name**. Key services include:

### pbxcore Services (User's primary focus)
- `pbxcore-telco-service` - Main PBX call controller
- `pbxcore-telco-service-cnpg` - Database for pbxcore
- `pbxcore-custom-audiofile-service` - Audio file handling
- `pbxcore-read-model-writer` - Read model synchronization

### Related Telco Services
- `channel-telco-service` - ACD channel handling
- `conference-telco-service` - Conference calls
- `voicemail-telco-service` - Voicemail handling
- `trunking-telco-service` - SIP trunking
- `satellite-telephony-service` - Satellite product
- `ivr-telco-service` - IVR handling
- `telco-inspector-service` - Call debugging
- `telco-timer-service` - Timer functionality
- `telco-permissions-service` - Permission checks
- `telco-endpoint-routing-service` - Endpoint routing
- `sipgate-telco-incoming-routing-provider` - Incoming routing
- `sipgate-telco-outgoing-routing-provider` - Outgoing routing

### VM-based Services (sipgate- prefix)
- `sipgate-billingd` - Billing daemon
- `sipgate-storaged-docker` - Storage service
- `sipgate-keycloak20` - Authentication
- `sipgate-sparta-core` - Core telephony
- `sipgate-enumdns` - ENUM DNS

## Common LogQL Query Patterns

### Basic Queries
```logql
# Service logs (always filter by service_name first)
{service_name="pbxcore-telco-service"}

# With environment filter
{service_name="pbxcore-telco-service", environment="live"}

# With log level filter
{service_name="pbxcore-telco-service", level="error"}

# Combined filters
{service_name="pbxcore-telco-service", environment="live", level=~"error|warning"}
```

### Text Search
```logql
# Contains text (case-sensitive)
{service_name="pbxcore-telco-service"} |= "error"

# NOT contains
{service_name="pbxcore-telco-service"} != "health"

# Regex match
{service_name="pbxcore-telco-service"} |~ "session.*timeout"

# Case-insensitive
{service_name="pbxcore-telco-service"} |~ "(?i)error"
```

### JSON Parsing (most logs are JSON)
```logql
# Parse JSON and filter
{service_name="pbxcore-telco-service"} | json | message =~ ".*Dial.*"

# Extract specific fields
{service_name="pbxcore-telco-service"} | json | line_format "{{.sessionId}} - {{.message}}"

# Filter by parsed field
{service_name="pbxcore-telco-service"} | json | kafkaEventType="ClientDeviceCalling"
```

### pbxcore-specific Fields (from JSON logs)
- `sessionId` - Call session identifier
- `tracingId` - Distributed tracing ID
- `kafkaEventType` - Kafka event type (ClientDeviceCalling, etc.)
- `webhookRequestId` - Webhook request ID
- `logger_name` - Java logger class
- `pod_name` - Kubernetes pod
- `namespace` - Kubernetes namespace (e.g., `sg-pbxcore-telco-service`)
- `cluster_nautilus_sipgate_cloud_environment` - Cluster environment
- `cluster_nautilus_sipgate_cloud_location` - Cluster location (ix01, ml01)

## Key Dashboards

### pbxcore Dashboards
| Title | UID | Purpose |
|-------|-----|---------|
| [bauhaus] PBXCore | `ysvDpEf4k` | Main pbxcore metrics (32 panels) |
| [pbxcore-telco-service] Billing Backend | `YIiheAgIz` | Billing/TAN metrics |
| [bauhaus] pbxcore recording service | `ceeqhcwbo7vnke` | Recording metrics |

### Related Telco Dashboards
| Title | UID | Purpose |
|-------|-----|---------|
| channel-telco-service | `gG1_kurVz` | ACD channel metrics |
| conference-telco-service | `1qLJTCIVz` | Conference statistics |
| Telco Inspector Service | `fb6f88f9-d641-42db-afe4-dfac28c52bcd` | Call debugging |
| [bauhaus] voicemail-telco-service | `feluzuws4y1hcf` | Voicemail metrics |
| [RETEL] telco-incoming-routing-provider | `adC4apbnk` | Incoming routing |
| [RETEL] telco-outgoing-routing-provider | `LJgV-NcVz` | Outgoing routing |

### Dashboard Folders
- `Telefonie` (UID: `2o0mrcOWz`) - Main telephony folder
- `retel` (UID: `fds0xmusjaltsd`) - RETEL project
- `presence` (UID: `de57sy5lp68zka`) - Presence services
- `Metropolis` (UID: `b33047a3-5ba6-45ab-93f5-8b7690037b45`) - Metropolis project

## Common Prometheus Query Patterns

### Basic Queries
```promql
# Counter rate over 5m
rate(http_server_requests_seconds_count{job="pbxcore-telco-service"}[5m])

# Histogram percentile
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{job="pbxcore-telco-service"}[5m]))

# Error rate
sum(rate(http_server_requests_seconds_count{job="pbxcore-telco-service", status=~"5.."}[5m]))
/
sum(rate(http_server_requests_seconds_count{job="pbxcore-telco-service"}[5m]))
```

### Common Job Names
- `pbxcore-telco-service` (Kubernetes)
- VM services often have `-haproxy` suffix for load balancer metrics

## Best Practices

1. **Always use `get_dashboard_summary`** instead of `get_dashboard_by_uid` to save context
2. **Check stats first** with `query_loki_stats` before running large log queries
3. **Use `list_loki_label_values`** to discover available services
4. **Default to loki-rrdns** for service logs
5. **Filter by environment** to reduce noise (prefer `live` for production issues)
6. **Use JSON parsing** for structured log analysis
7. **Generate deeplinks** to share Grafana URLs with the user
8. **Do NOT pass explicit time ranges** for "latest logs" queries — omit `startRfc3339`/`endRfc3339` and let Loki use defaults. Specifying timestamps risks using future times (e.g. UTC offset errors), which silently returns 0 results and leads to wrong conclusions like "service doesn't exist in this environment"
9. **Never conclude a service doesn't exist** in an environment just because a query returned 0 results — check your time range, datasource, and label combinations first. Say "I couldn't find logs" not "the service doesn't run here"

## Query Workflow

1. **Identify the datasource** (usually loki-rrdns for logs, Prometheus for metrics)
2. **Check available labels/values** using list functions
3. **Get stats** to understand data volume
4. **Run targeted queries** with appropriate filters
5. **Parse JSON** if needed for structured data
6. **Generate deeplinks** for user to view in Grafana UI
