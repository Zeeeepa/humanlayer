#!/bin/bash
# HumanLayer Health Check Script
# Purpose: Validate deployment health and AI model availability
# Version: 1.0.0

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Health check results
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Functions
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((CHECKS_PASSED++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((CHECKS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((CHECKS_WARNING++))
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check daemon process
check_daemon() {
    log_info "Checking HLD daemon..."
    
    if pgrep -f "hld" > /dev/null; then
        log_success "Daemon process is running"
        
        # Check socket file
        if [ -S ~/.humanlayer/daemon.sock ]; then
            log_success "Daemon socket file exists"
        else
            log_error "Daemon socket file not found"
        fi
    else
        log_error "Daemon process not running"
    fi
}

# Check database
check_database() {
    log_info "Checking database..."
    
    if [ -f ~/.humanlayer/daemon.db ]; then
        log_success "Database file exists"
        
        # Check database integrity
        if command -v sqlite3 &> /dev/null; then
            if sqlite3 ~/.humanlayer/daemon.db "PRAGMA integrity_check;" | grep -q "ok"; then
                log_success "Database integrity check passed"
            else
                log_error "Database integrity check failed"
            fi
            
            # Check session count
            session_count=$(sqlite3 ~/.humanlayer/daemon.db "SELECT COUNT(*) FROM sessions;" 2>/dev/null || echo "0")
            log_info "Total sessions: $session_count"
        else
            log_warning "sqlite3 not available - skipping integrity check"
        fi
    else
        log_error "Database file not found"
    fi
}

# Check AI model configuration
check_ai_config() {
    log_info "Checking AI configuration..."
    
    config_file=~/.humanlayer/humanlayer.json
    
    if [ -f "$config_file" ]; then
        log_success "Configuration file exists"
        
        # Check for model configuration
        if grep -q "claude_model" "$config_file"; then
            primary_model=$(jq -r '.claude_model // "not set"' "$config_file" 2>/dev/null || echo "parse error")
            log_success "Primary model configured: $primary_model"
        else
            log_warning "Primary model not configured"
        fi
        
        # Check for fallback models
        if grep -q "fallback_models" "$config_file"; then
            fallback_count=$(jq '.fallback_models | length' "$config_file" 2>/dev/null || echo "0")
            log_success "Fallback models configured: $fallback_count"
        else
            log_warning "No fallback models configured"
        fi
        
        # Check retry configuration
        if grep -q "model_config" "$config_file"; then
            log_success "Model retry configuration present"
        else
            log_warning "Model retry configuration not found"
        fi
    else
        log_error "Configuration file not found"
    fi
}

# Check disk space
check_disk_space() {
    log_info "Checking disk space..."
    
    data_dir=~/.humanlayer
    
    if [ -d "$data_dir" ]; then
        available=$(df -h "$data_dir" | awk 'NR==2 {print $4}')
        used=$(du -sh "$data_dir" 2>/dev/null | cut -f1)
        
        log_info "Data directory size: $used"
        log_info "Available space: $available"
        
        # Convert available space to GB for comparison
        available_gb=$(df -BG "$data_dir" | awk 'NR==2 {print $4}' | sed 's/G//')
        
        if [ "$available_gb" -gt 5 ]; then
            log_success "Sufficient disk space available"
        else
            log_warning "Low disk space: ${available_gb}GB available"
        fi
    else
        log_error "Data directory not found"
    fi
}

# Check network connectivity
check_network() {
    log_info "Checking network connectivity..."
    
    # Check GitHub (for repository access)
    if ping -c 1 -W 2 github.com &> /dev/null || curl -s --head --connect-timeout 2 https://github.com &> /dev/null; then
        log_success "GitHub connectivity OK"
    else
        log_warning "Cannot reach GitHub"
    fi
    
    # Check API endpoint (if configured)
    config_file=~/.humanlayer/humanlayer.json
    if [ -f "$config_file" ] && command -v jq &> /dev/null; then
        api_url=$(jq -r '.api_url // "https://api.humanlayer.dev"' "$config_file")
        if curl -s --head --connect-timeout 2 "$api_url/health" &> /dev/null; then
            log_success "API endpoint reachable"
        else
            log_warning "Cannot reach API endpoint: $api_url"
        fi
    fi
}

# Check log files
check_logs() {
    log_info "Checking log files..."
    
    log_dir=~/.humanlayer/logs
    
    if [ -d "$log_dir" ]; then
        log_count=$(find "$log_dir" -name "*.log" 2>/dev/null | wc -l)
        log_info "Found $log_count log files"
        
        # Check for recent errors in latest log
        latest_log=$(find "$log_dir" -name "daemon-*.log" -type f 2>/dev/null | sort | tail -n 1)
        if [ -n "$latest_log" ]; then
            error_count=$(grep -c "ERROR" "$latest_log" 2>/dev/null || echo "0")
            if [ "$error_count" -gt 0 ]; then
                log_warning "Found $error_count errors in latest log"
            else
                log_success "No errors in latest log"
            fi
        fi
        
        # Check log size
        total_size=$(du -sh "$log_dir" 2>/dev/null | cut -f1)
        log_info "Total log size: $total_size"
    else
        log_warning "Log directory not found"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Node.js
    if command -v node &> /dev/null; then
        node_version=$(node --version)
        log_success "Node.js: $node_version"
    else
        log_error "Node.js not found"
    fi
    
    # Check Bun
    if command -v bun &> /dev/null; then
        bun_version=$(bun --version)
        log_success "Bun: $bun_version"
    else
        log_warning "Bun not found"
    fi
    
    # Check Go
    if command -v go &> /dev/null; then
        go_version=$(go version | awk '{print $3}')
        log_success "Go: $go_version"
    else
        log_error "Go not found"
    fi
    
    # Check Rust
    if command -v rustc &> /dev/null; then
        rust_version=$(rustc --version | awk '{print $2}')
        log_success "Rust: $rust_version"
    else
        log_warning "Rust not found"
    fi
}

# Test daemon API
test_daemon_api() {
    log_info "Testing daemon API..."
    
    socket_path=~/.humanlayer/daemon.sock
    
    if [ -S "$socket_path" ]; then
        # Try to query daemon via socket (if nc is available)
        if command -v nc &> /dev/null; then
            response=$(echo '{"jsonrpc":"2.0","method":"health","params":{},"id":1}' | nc -U "$socket_path" 2>/dev/null | head -n 1)
            if [ -n "$response" ]; then
                log_success "Daemon API responding"
            else
                log_warning "Daemon API not responding"
            fi
        else
            log_info "netcat not available - skipping API test"
        fi
    fi
}

# Generate health report
generate_report() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║                 📊 Health Check Summary                   ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}✅ Passed:  $CHECKS_PASSED${NC}"
    echo -e "${RED}❌ Failed:  $CHECKS_FAILED${NC}"
    echo -e "${YELLOW}⚠️  Warnings: $CHECKS_WARNING${NC}"
    echo ""
    
    if [ $CHECKS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All critical checks passed!${NC}"
        return 0
    else
        echo -e "${RED}⚠️  Some checks failed. Review errors above.${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║           HumanLayer Health Check v1.0.0                  ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    check_daemon
    check_database
    check_ai_config
    check_disk_space
    check_network
    check_logs
    test_daemon_api
    
    generate_report
    exit $?
}

# Run main
main

