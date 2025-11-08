# HumanLayer Deployment Testing Guide

**Comprehensive testing procedures for validating deployments**

---

## Table of Contents

1. [Overview](#overview)
2. [Pre-Deployment Testing](#pre-deployment-testing)
3. [Post-Deployment Validation](#post-deployment-validation)
4. [AI Model Fallback Testing](#ai-model-fallback-testing)
5. [Error Recovery Testing](#error-recovery-testing)
6. [Performance Testing](#performance-testing)
7. [Rollback Procedures](#rollback-procedures)

---

## Overview

This guide provides systematic testing procedures to ensure HumanLayer deployments are stable, functional, and production-ready.

### Testing Levels

1. **Smoke Tests** - Quick validation that basic functionality works
2. **Integration Tests** - Verify components work together
3. **Failover Tests** - Validate error handling and fallback mechanisms
4. **Performance Tests** - Ensure acceptable performance under load
5. **Recovery Tests** - Validate backup and restore procedures

---

## Pre-Deployment Testing

### Environment Validation

**Run health check:**
```bash
# Linux/macOS
./scripts/health-check.sh

# Windows
powershell -ExecutionPolicy Bypass -File .\scripts\windows-health-check.ps1
```

**Validate prerequisites:**
```bash
# Check versions
node --version    # Should be v18+
bun --version     # Should be latest
go version        # Should be 1.21+
rustc --version   # Should be latest

# Check disk space
df -h ~/.humanlayer  # Should have 5GB+ free

# Check network
ping github.com
curl -I https://api.humanlayer.dev/health
```

### Configuration Validation

**Validate configuration file:**
```bash
# Check syntax
cat ~/.humanlayer/humanlayer.json | jq .

# Verify required fields
jq '.claude_model' ~/.humanlayer/humanlayer.json
jq '.fallback_models' ~/.humanlayer/humanlayer.json
jq '.model_config' ~/.humanlayer/humanlayer.json
```

**Test configuration:**
```json
{
  "claude_model": "claude-sonnet-4-20250514",
  "fallback_models": [
    {
      "model": "claude-3-5-sonnet-20241022",
      "priority": 1,
      "enabled": true
    },
    {
      "model": "claude-3-opus-20240229",
      "priority": 2,
      "enabled": true
    }
  ],
  "model_config": {
    "retry_attempts": 3,
    "retry_delay_ms": 1000,
    "timeout_seconds": 30,
    "fallback_on_rate_limit": true,
    "fallback_on_error": true
  },
  "health_check": {
    "enabled": true,
    "interval_seconds": 60,
    "failure_threshold": 3,
    "success_threshold": 1
  }
}
```

---

## Post-Deployment Validation

### Smoke Tests

**1. Test Daemon Startup:**
```bash
# Start daemon
cd hld
./hld-nightly &

# Wait 5 seconds
sleep 5

# Check process
pgrep hld
ps aux | grep hld

# Check socket
ls -la ~/.humanlayer/daemon.sock

# Check logs
tail -f ~/.humanlayer/logs/daemon-nightly-*.log
```

**Expected Output:**
- Daemon process running
- Socket file exists
- No errors in logs
- Log shows "Daemon started successfully"

**2. Test Database Connection:**
```bash
# Query database
sqlite3 ~/.humanlayer/daemon.db "SELECT * FROM sessions LIMIT 5;"

# Check integrity
sqlite3 ~/.humanlayer/daemon.db "PRAGMA integrity_check;"
```

**Expected Output:**
- Database queries execute without error
- Integrity check returns "ok"

**3. Test UI Startup:**
```bash
# Start UI (development mode)
cd humanlayer-wui
npm run tauri dev
```

**Expected Output:**
- UI opens without errors
- Connects to daemon successfully
- Dashboard displays correctly

**4. Test CLI:**
```bash
# Test CLI commands
npx humanlayer --version
npx humanlayer config-show
```

**Expected Output:**
- Commands execute successfully
- Configuration displays correctly

### Integration Tests

**1. Test Session Creation:**
```bash
# Launch a test session
npx humanlayer launch "print hello world in Python"
```

**Expected Behavior:**
- Session created successfully
- Appears in UI session list
- Claude Code starts and executes task
- Session completes successfully

**2. Test Session Tracking:**
```bash
# Query sessions via database
sqlite3 ~/.humanlayer/daemon.db "
  SELECT id, prompt, status, created_at 
  FROM sessions 
  ORDER BY created_at DESC 
  LIMIT 5;
"
```

**Expected Output:**
- Test session appears in database
- Status progresses correctly (pending → running → completed)
- Timestamps are accurate

**3. Test Approval Workflow:**
```bash
# Launch session requiring approval
npx humanlayer launch "modify system configuration" --require-approval
```

**Expected Behavior:**
- Approval request appears in UI
- Approval/deny functions work
- Session resumes/stops based on approval

---

## AI Model Fallback Testing

### Primary Model Failure

**Test 1: Invalid API Key**

**Setup:**
```bash
# Temporarily set invalid API key
export ANTHROPIC_API_KEY="invalid-key-for-testing"
```

**Test:**
```bash
npx humanlayer launch "test task"
```

**Expected Behavior:**
1. Primary model fails with authentication error
2. System logs fallback attempt
3. Fallback model is tried automatically
4. Session completes with fallback model
5. User notification of fallback usage

**Verify in logs:**
```bash
tail -f ~/.humanlayer/logs/daemon-nightly-*.log | grep -i "fallback"
```

**Test 2: Rate Limit**

**Simulate:**
```bash
# Make rapid successive requests
for i in {1..10}; do
  npx humanlayer launch "task $i" &
done
```

**Expected Behavior:**
1. Some requests hit rate limit
2. Rate-limited requests automatically use fallback
3. All sessions eventually complete
4. Rate limit errors logged but handled gracefully

**Test 3: Timeout**

**Setup:**
```json
{
  "model_config": {
    "timeout_seconds": 1
  }
}
```

**Test:**
```bash
npx humanlayer launch "complex task that takes time"
```

**Expected Behavior:**
1. Primary model times out
2. Fallback model is tried
3. Task completes with fallback
4. Timeout logged appropriately

### Fallback Priority Testing

**Test fallback priority order:**

**Configuration:**
```json
{
  "fallback_models": [
    {"model": "claude-3-5-sonnet-20241022", "priority": 1, "enabled": true},
    {"model": "claude-3-opus-20240229", "priority": 2, "enabled": false},
    {"model": "claude-3-haiku-20240307", "priority": 3, "enabled": true}
  ]
}
```

**Test:**
1. Disable primary model
2. Verify priority 1 fallback is used
3. Disable priority 1
4. Verify priority 2 is skipped (disabled)
5. Verify priority 3 is used

---

## Error Recovery Testing

### Database Corruption

**Test:**
```bash
# Backup database
cp ~/.humanlayer/daemon.db ~/.humanlayer/daemon.db.backup

# Corrupt database
echo "corrupt data" >> ~/.humanlayer/daemon.db

# Restart daemon
pkill hld
cd hld && ./hld-nightly
```

**Expected Behavior:**
1. Daemon detects corruption on startup
2. Error logged clearly
3. Daemon attempts recovery or suggests restore
4. User instructed on recovery procedure

**Recovery:**
```bash
# Restore from backup
cp ~/.humanlayer/daemon.db.backup ~/.humanlayer/daemon.db
```

### Socket File Issues

**Test:**
```bash
# Create invalid socket
rm ~/.humanlayer/daemon.sock
touch ~/.humanlayer/daemon.sock  # Regular file instead of socket

# Try to start daemon
cd hld && ./hld-nightly
```

**Expected Behavior:**
1. Daemon detects invalid socket
2. Removes/recreates socket
3. Starts successfully

### Disk Space Exhaustion

**Simulate:**
```bash
# Fill disk near capacity (test environment only!)
# Monitor logs during low disk space
```

**Expected Behavior:**
1. Daemon logs disk space warning
2. Old logs rotated/deleted automatically
3. Sessions fail gracefully with clear error
4. No data corruption

### Network Interruption

**Test:**
```bash
# Disable network during session
sudo ifconfig en0 down  # macOS
sudo ip link set eth0 down  # Linux

# Wait 10 seconds
sleep 10

# Re-enable network
sudo ifconfig en0 up  # macOS
sudo ip link set eth0 up  # Linux
```

**Expected Behavior:**
1. Session pauses during network outage
2. Automatic retry with exponential backoff
3. Session resumes when network returns
4. User notified of temporary interruption

---

## Performance Testing

### Load Testing

**Test concurrent sessions:**
```bash
# Launch multiple concurrent sessions
for i in {1..10}; do
  npx humanlayer launch "task $i" --daemon-socket ~/.humanlayer/daemon.sock &
done

# Monitor resource usage
top -p $(pgrep hld)
```

**Metrics to collect:**
- CPU usage (should stay < 80%)
- Memory usage (should stay < 2GB per instance)
- Response time (should stay < 5s for session creation)
- Throughput (sessions per minute)

**Acceptance Criteria:**
- 10 concurrent sessions: All complete successfully
- 50 concurrent sessions: All complete within 10 minutes
- No memory leaks (memory stable over time)
- No database locks or deadlocks

### Stress Testing

**Test session throughput:**
```bash
# Create 100 sessions rapidly
for i in {1..100}; do
  npx humanlayer launch "test $i" &
  if [ $((i % 10)) -eq 0 ]; then
    wait  # Wait every 10 to avoid overwhelming system
  fi
done
```

**Monitor:**
- Database response time
- Log file I/O
- Network bandwidth
- API rate limits

---

## Rollback Procedures

### Pre-Deployment Backup

**Create backup:**
```bash
# Automated backup
./scripts/backup-humanlayer.sh

# Manual backup
cp -r ~/.humanlayer ~/.humanlayer.backup-$(date +%Y%m%d-%H%M%S)
```

### Rollback Steps

**1. Stop Current Deployment:**
```bash
# Stop daemon
pkill hld

# Stop UI
pkill -f "tauri dev"
```

**2. Restore Previous Version:**
```bash
# Restore data directory
cp -r ~/.humanlayer.backup-20250108-120000 ~/.humanlayer

# Restore binaries
cd hld
git checkout previous-release-tag
go build -o hld
```

**3. Verify Rollback:**
```bash
# Start daemon
./hld &

# Run health check
./scripts/health-check.sh

# Test basic functionality
npx humanlayer launch "test session"
```

### Emergency Procedures

**Critical failure rollback:**
```bash
#!/bin/bash
# emergency-rollback.sh

set -e

echo "Starting emergency rollback..."

# Stop all processes
pkill hld
pkill -f "tauri dev"

# Find most recent backup
LATEST_BACKUP=$(ls -t ~/.humanlayer.backup-* | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "ERROR: No backup found!"
    exit 1
fi

echo "Restoring from: $LATEST_BACKUP"

# Restore
rm -rf ~/.humanlayer
cp -r "$LATEST_BACKUP" ~/.humanlayer

# Start daemon
cd hld && ./hld &

echo "Rollback complete. Running health check..."
./scripts/health-check.sh
```

---

## Automated Testing

### CI/CD Integration

**GitHub Actions example:**
```yaml
name: Deployment Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deployment-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup
        run: make setup
      
      - name: Run health check
        run: ./scripts/health-check.sh
      
      - name: Test daemon startup
        run: |
          cd hld
          ./hld &
          sleep 5
          pgrep hld || exit 1
      
      - name: Test session creation
        run: npx humanlayer launch "test" --no-interactive
      
      - name: Validate deployment
        run: ./scripts/validate-deployment.sh
```

### Testing Checklist

Before marking deployment as successful:

- [ ] All smoke tests pass
- [ ] Integration tests pass
- [ ] AI fallback mechanisms tested
- [ ] Error recovery tested
- [ ] Performance acceptable
- [ ] Rollback procedure tested
- [ ] Documentation updated
- [ ] Monitoring configured
- [ ] Alerts configured
- [ ] Backup scheduled

---

## Monitoring Post-Deployment

### Key Metrics

**System Health:**
- Daemon uptime
- Memory usage
- CPU usage
- Disk space

**Application Health:**
- Session success rate
- Average session duration
- API response time
- Error rate

**AI Model Health:**
- Primary model success rate
- Fallback activation rate
- Model response time
- Rate limit occurrences

### Alerting Rules

**Critical Alerts:**
- Daemon down > 1 minute
- Error rate > 10%
- Disk space < 10%
- Database corruption detected

**Warning Alerts:**
- Fallback model used > 20% of requests
- Session queue > 50
- Memory usage > 80%
- Log size > 1GB

---

## Troubleshooting Failed Tests

### Test Failure Analysis

**1. Identify failure point:**
```bash
# Check logs
tail -100 ~/.humanlayer/logs/daemon-nightly-*.log

# Check database
sqlite3 ~/.humanlayer/daemon.db ".tables"
sqlite3 ~/.humanlayer/daemon.db "SELECT * FROM sessions WHERE status='failed';"
```

**2. Reproduce failure:**
- Run test in isolation
- Enable debug logging
- Capture full error trace

**3. Common issues:**

| Symptom | Likely Cause | Solution |
|---------|-------------|----------|
| Daemon won't start | Port conflict | Check `lsof -i :port` |
| Database locked | Multiple instances | Kill all hld processes |
| UI won't connect | Socket permissions | Check file permissions |
| Sessions fail immediately | Invalid API key | Verify ANTHROPIC_API_KEY |
| Slow performance | Resource limits | Increase memory/CPU |

---

## Version-Specific Testing

### v1.0 → v2.0 Migration

**Additional tests:**
- Schema migration successful
- Configuration compatibility
- Backward compatibility with old sessions
- Data integrity after migration

---

## Appendix

### Testing Tools

**Required:**
- `jq` - JSON parsing
- `sqlite3` - Database queries
- `curl` - API testing
- `nc` (netcat) - Socket testing

**Optional:**
- `ab` (Apache Bench) - Load testing
- `hey` - HTTP load testing
- `prometheus` - Metrics collection
- `grafana` - Metrics visualization

### Test Data

**Sample test sessions:**
```bash
# Simple task
npx humanlayer launch "echo hello world"

# Complex task
npx humanlayer launch "implement a binary search algorithm in Python with unit tests"

# Error-prone task (for testing error handling)
npx humanlayer launch "access non-existent API endpoint"
```

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-08  
**License**: Apache 2.0

