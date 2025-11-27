# HumanLayer AI Model Fallback Guide

**Comprehensive guide to AI model fallback configuration and best practices**

---

## Table of Contents

1. [Overview](#overview)
2. [Fallback Architecture](#fallback-architecture)
3. [Configuration](#configuration)
4. [Fallback Triggers](#fallback-triggers)
5. [Best Practices](#best-practices)
6. [Monitoring](#monitoring)
7. [Troubleshooting](#troubleshooting)

---

## Overview

HumanLayer includes a robust AI model fallback system that automatically switches to backup models when the primary model is unavailable, rate-limited, or experiencing issues.

### Key Benefits

✅ **High Availability** - System continues operating during model outages  
✅ **Rate Limit Resilience** - Automatic switching when limits are hit  
✅ **Cost Optimization** - Use cheaper fallback models when appropriate  
✅ **Performance Optimization** - Faster models for simple tasks  

---

## Fallback Architecture

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                     User Request                         │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
         ┌─────────────────────────────┐
         │    Primary Model Attempt     │
         │  (claude-sonnet-4-20250514)  │
         └──────┬─────────────┬─────────┘
                │             │
         Success│             │Failure/Timeout/Rate Limit
                │             │
                ▼             ▼
         ┌──────────┐  ┌─────────────────────┐
         │ Response │  │   Fallback Logic    │
         └──────────┘  │  (Priority Queue)   │
                       └──────┬──────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
         Priority 1 │                   │ Priority 2
                    ▼                   ▼
    ┌──────────────────────┐  ┌─────────────────────┐
    │   claude-3-5-sonnet   │  │  claude-3-opus     │
    └───────┬──────────────┘  └──────┬──────────────┘
            │                         │
     Success│                  Success│
            │                         │
            └───────────┬─────────────┘
                        │
                        ▼
                 ┌─────────────┐
                 │   Response  │
                 │  (Logged)   │
                 └─────────────┘
```

### Components

**1. Request Handler**
- Receives user requests
- Determines appropriate model
- Manages retry logic

**2. Model Selector**
- Maintains model priority queue
- Tracks model health status
- Makes fallback decisions

**3. Health Monitor**
- Monitors model availability
- Tracks error rates
- Updates model status

**4. Fallback Logger**
- Records fallback events
- Tracks usage statistics
- Alerts on threshold breaches

---

## Configuration

### Basic Configuration

**File:** `~/.humanlayer/humanlayer.json`

```json
{
  "claude_model": "claude-sonnet-4-20250514",
  "fallback_models": [
    {
      "model": "claude-3-5-sonnet-20241022",
      "priority": 1,
      "enabled": true,
      "max_retries": 2
    },
    {
      "model": "claude-3-opus-20240229",
      "priority": 2,
      "enabled": true,
      "max_retries": 1
    },
    {
      "model": "claude-3-haiku-20240307",
      "priority": 3,
      "enabled": false,
      "max_retries": 1
    }
  ]
}
```

### Advanced Configuration

```json
{
  "claude_model": "claude-sonnet-4-20250514",
  "fallback_models": [
    {
      "model": "claude-3-5-sonnet-20241022",
      "priority": 1,
      "enabled": true,
      "max_retries": 2,
      "timeout_seconds": 30,
      "cost_per_token": 0.00003
    }
  ],
  "model_config": {
    "retry_attempts": 3,
    "retry_delay_ms": 1000,
    "retry_backoff_multiplier": 2,
    "max_retry_delay_ms": 10000,
    "timeout_seconds": 30,
    "fallback_on_rate_limit": true,
    "fallback_on_error": true,
    "fallback_on_timeout": true,
    "cost_aware_fallback": true,
    "performance_aware_fallback": false
  },
  "health_check": {
    "enabled": true,
    "interval_seconds": 60,
    "failure_threshold": 3,
    "success_threshold": 1,
    "timeout_seconds": 10
  },
  "fallback_rules": {
    "rate_limit_cooldown_seconds": 60,
    "error_threshold_percent": 20,
    "latency_threshold_seconds": 10,
    "auto_disable_failing_models": true,
    "re_enable_after_seconds": 300
  }
}
```

### Configuration Parameters

#### Primary Model
| Parameter | Description | Example |
|-----------|-------------|---------|
| `claude_model` | Primary model to use | `"claude-sonnet-4-20250514"` |

#### Fallback Models
| Parameter | Description | Default |
|-----------|-------------|---------|
| `model` | Model identifier | Required |
| `priority` | Lower = higher priority | Required |
| `enabled` | Enable/disable this fallback | `true` |
| `max_retries` | Retries before next fallback | `2` |
| `timeout_seconds` | Model-specific timeout | `30` |
| `cost_per_token` | Cost for cost-aware fallback | Optional |

#### Model Config
| Parameter | Description | Default |
|-----------|-------------|---------|
| `retry_attempts` | Max retry attempts | `3` |
| `retry_delay_ms` | Initial retry delay | `1000` |
| `retry_backoff_multiplier` | Exponential backoff factor | `2` |
| `timeout_seconds` | Request timeout | `30` |
| `fallback_on_rate_limit` | Auto-fallback on 429 | `true` |
| `fallback_on_error` | Auto-fallback on errors | `true` |
| `fallback_on_timeout` | Auto-fallback on timeout | `true` |

#### Health Check
| Parameter | Description | Default |
|-----------|-------------|---------|
| `enabled` | Enable health checks | `true` |
| `interval_seconds` | Check frequency | `60` |
| `failure_threshold` | Failures before unhealthy | `3` |
| `success_threshold` | Successes to recover | `1` |

---

## Fallback Triggers

### Automatic Triggers

**1. Rate Limiting (429)**
```json
{
  "error": "rate_limit_exceeded",
  "status": 429,
  "message": "Too many requests"
}
```

**Action:** Immediately switch to next priority fallback model.

**2. Authentication Errors (401)**
```json
{
  "error": "invalid_api_key",
  "status": 401
}
```

**Action:** Log critical error, attempt fallback with different API key if configured.

**3. Model Overloaded (503)**
```json
{
  "error": "overloaded",
  "status": 503,
  "message": "Model temporarily unavailable"
}
```

**Action:** Retry with exponential backoff, fallback after max retries.

**4. Timeout**
- Request exceeds `timeout_seconds`
- **Action:** Cancel request, try fallback model

**5. Network Errors**
- Connection timeout
- DNS resolution failure
- **Action:** Retry with backoff, then fallback

**6. High Error Rate**
- Error rate exceeds `error_threshold_percent` over 5 minutes
- **Action:** Temporarily disable model, use fallback

### Manual Triggers

**Force fallback via API:**
```typescript
const session = await client.createSession({
  prompt: "task",
  force_fallback: true,
  preferred_fallback: "claude-3-opus-20240229"
});
```

**Disable primary model:**
```bash
# Update configuration
jq '.claude_model_enabled = false' ~/.humanlayer/humanlayer.json > tmp.json
mv tmp.json ~/.humanlayer/humanlayer.json

# Restart daemon
pkill hld && cd hld && ./hld-nightly &
```

---

## Best Practices

### Model Selection Strategy

**1. Performance-First Strategy**
```json
{
  "claude_model": "claude-sonnet-4-20250514",
  "fallback_models": [
    {"model": "claude-3-5-sonnet-20241022", "priority": 1},
    {"model": "claude-3-haiku-20240307", "priority": 2}
  ]
}
```

Use when: Speed is critical, task complexity varies

**2. Cost-Optimized Strategy**
```json
{
  "claude_model": "claude-3-haiku-20240307",
  "fallback_models": [
    {"model": "claude-3-5-sonnet-20241022", "priority": 1},
    {"model": "claude-sonnet-4-20250514", "priority": 2}
  ],
  "model_config": {
    "cost_aware_fallback": true
  }
}
```

Use when: Budget constraints, simple tasks

**3. Quality-First Strategy**
```json
{
  "claude_model": "claude-sonnet-4-20250514",
  "fallback_models": [
    {"model": "claude-3-opus-20240229", "priority": 1},
    {"model": "claude-3-5-sonnet-20241022", "priority": 2}
  ]
}
```

Use when: Output quality is paramount

**4. Availability-First Strategy**
```json
{
  "claude_model": "claude-3-5-sonnet-20241022",
  "fallback_models": [
    {"model": "claude-3-haiku-20240307", "priority": 1},
    {"model": "claude-3-opus-20240229", "priority": 2},
    {"model": "claude-sonnet-4-20250514", "priority": 3}
  ]
}
```

Use when: Uptime is critical, graceful degradation acceptable

### Configuration Tips

**1. Set Appropriate Timeouts**
```json
{
  "model_config": {
    "timeout_seconds": 30  // Adjust based on task complexity
  }
}
```

- Simple tasks: 15-20 seconds
- Complex tasks: 30-60 seconds
- Research tasks: 60-120 seconds

**2. Configure Retry Logic**
```json
{
  "model_config": {
    "retry_attempts": 3,
    "retry_delay_ms": 1000,
    "retry_backoff_multiplier": 2
  }
}
```

Retry delays: 1s → 2s → 4s (exponential backoff)

**3. Enable Health Monitoring**
```json
{
  "health_check": {
    "enabled": true,
    "interval_seconds": 60,
    "failure_threshold": 3
  }
}
```

Proactively detect issues before user impact.

**4. Set Cost Limits**
```json
{
  "cost_config": {
    "daily_limit_usd": 100,
    "per_session_limit_usd": 1,
    "alert_threshold_percent": 80
  }
}
```

Prevent runaway costs from excessive fallback usage.

---

## Monitoring

### Key Metrics

**Fallback Rate**
```bash
# Calculate fallback percentage
sqlite3 ~/.humanlayer/daemon.db "
  SELECT 
    COUNT(*) FILTER (WHERE model != 'claude-sonnet-4-20250514') * 100.0 / COUNT(*) as fallback_percent
  FROM sessions
  WHERE created_at > datetime('now', '-1 day');
"
```

**Target:** < 10% fallback rate

**Model Availability**
```bash
# Check model health status
curl http://localhost:8080/health/models
```

**Target:** 99.9% availability

**Cost Tracking**
```bash
# Calculate daily cost
sqlite3 ~/.humanlayer/daemon.db "
  SELECT 
    SUM(tokens_used * cost_per_token) as daily_cost
  FROM sessions
  WHERE DATE(created_at) = DATE('now');
"
```

### Dashboards

**Recommended Metrics Dashboard:**
```
┌─────────────────────────────────────────────┐
│  Primary Model Success Rate: 92%            │
│  Fallback Activation Rate: 8%               │
│  Average Response Time: 2.3s                │
│  Daily Cost: $12.45                         │
└─────────────────────────────────────────────┘

Recent Fallbacks:
  - 14:23 - Rate limit (claude-sonnet-4)
  - 14:15 - Timeout (claude-sonnet-4)
  - 13:45 - Error (claude-sonnet-4)
```

### Alerting Rules

**Critical Alerts:**
- Fallback rate > 50% for 5 minutes
- All models unavailable
- Cost exceeds daily limit

**Warning Alerts:**
- Fallback rate > 20% for 15 minutes
- Single model unavailable > 10 minutes
- Cost at 80% of daily limit

---

## Troubleshooting

### Common Issues

**1. High Fallback Rate**

**Symptoms:**
- Fallback models used > 20% of time
- Increased costs
- Slower response times

**Diagnosis:**
```bash
# Check error logs
grep "fallback" ~/.humanlayer/logs/daemon-nightly-*.log | tail -20

# Analyze failure reasons
sqlite3 ~/.humanlayer/daemon.db "
  SELECT error_type, COUNT(*) as count
  FROM session_errors
  WHERE created_at > datetime('now', '-1 hour')
  GROUP BY error_type;
"
```

**Solutions:**
- Increase API rate limits
- Upgrade API plan
- Distribute load across time
- Use request throttling

**2. Fallback Not Working**

**Symptoms:**
- Sessions fail instead of falling back
- "All models unavailable" errors

**Diagnosis:**
```bash
# Check fallback configuration
jq '.fallback_models' ~/.humanlayer/humanlayer.json

# Check model enablement
jq '.fallback_models[] | select(.enabled == false)' ~/.humanlayer/humanlayer.json
```

**Solutions:**
- Verify fallback models are enabled
- Check API keys for fallback models
- Ensure fallback models are valid
- Review fallback_on_* settings

**3. Unexpected Model Used**

**Symptoms:**
- Wrong model handling requests
- Higher costs than expected

**Diagnosis:**
```bash
# Check recent sessions
sqlite3 ~/.humanlayer/daemon.db "
  SELECT id, model_used, prompt, created_at
  FROM sessions
  ORDER BY created_at DESC
  LIMIT 10;
"
```

**Solutions:**
- Review model priority configuration
- Check if primary model was disabled
- Verify health check results
- Review fallback triggers

**4. Slow Performance**

**Symptoms:**
- Increased response times
- Timeout errors

**Diagnosis:**
```bash
# Check response times
sqlite3 ~/.humanlayer/daemon.db "
  SELECT model_used, AVG(duration_ms) as avg_duration
  FROM sessions
  WHERE created_at > datetime('now', '-1 hour')
  GROUP BY model_used;
"
```

**Solutions:**
- Adjust timeout settings
- Use faster fallback models
- Enable performance-aware fallback
- Review network latency

---

## Advanced Topics

### Custom Fallback Logic

**Example: Task-Based Fallback**
```typescript
// Custom fallback selection based on task type
function selectModel(task: Task): string {
  if (task.complexity === 'simple') {
    return 'claude-3-haiku-20240307';
  } else if (task.complexity === 'complex') {
    return 'claude-sonnet-4-20250514';
  } else {
    return 'claude-3-5-sonnet-20241022';
  }
}
```

### Multi-Region Fallback

**Configuration:**
```json
{
  "regions": [
    {
      "region": "us-east-1",
      "primary_model": "claude-sonnet-4-20250514",
      "api_endpoint": "https://api.anthropic.com"
    },
    {
      "region": "eu-west-1",
      "primary_model": "claude-3-5-sonnet-20241022",
      "api_endpoint": "https://eu.api.anthropic.com"
    }
  ]
}
```

---

## Appendix

### Model Comparison

| Model | Speed | Cost | Quality | Use Case |
|-------|-------|------|---------|----------|
| claude-sonnet-4 | Medium | High | Highest | Complex reasoning |
| claude-3-5-sonnet | Fast | Medium | High | General purpose |
| claude-3-opus | Slow | Highest | Highest | Research tasks |
| claude-3-haiku | Fastest | Lowest | Medium | Simple tasks |

### Example Configurations

See [examples/fallback-configs/](examples/fallback-configs/) for:
- Development configuration
- Production configuration
- Cost-optimized configuration
- Performance-optimized configuration

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-08  
**License**: Apache 2.0

