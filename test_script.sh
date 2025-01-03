#!/usr/bin/env bash

# test_script.sh
# --------------------------------------------------
# Automated validation script for file2ai
#
# Usage:
#   ./test_script.sh
#
# Requirements:
#   - Python 3.x with venv module
#   - Git
#
# This script:
#   1) Creates a clean virtual environment
#   2) Installs file2ai and test dependencies
#   3) Runs pytest with coverage reporting
#   4) Performs export tests:
#      - Local directory export
#      - Remote repository export
#      - Repository subdirectory export
#   5) Validates output files:
#      - Checks file existence
#      - Verifies file structure
#      - Checks content markers
#      - Verifies sequential file naming
#
# Exit Codes:
#   0 - All tests passed
#   1 - Test or validation failure
#
# Example Output Files:
#   exports/file2ai_export.txt    - Local directory export
#   exports/docling_export.txt    - Remote repository export
#   exports/docling_export(1).txt - Subdirectory export
#
# Note: This script will clean up existing venv and exports
#       before running tests. Make sure to backup any important
#       files before running.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging helpers
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; exit 1; }
log_warn() { echo -e "${YELLOW}! $1${NC}"; }
log_info() { echo -e "➜ $1"; }

# Check if sudo is available
if ! command -v sudo &> /dev/null; then
    log_warn "sudo not found - cleanup may fail if files are owned by root"
    if ! rm -rf venv logs exports launchers 2>/dev/null; then
        log_error "Permission denied. Please run with sudo or manually remove: venv logs exports launchers"
    fi
else
    # 1) Clean up old artifacts
    log_info "Cleaning up old artifacts..."
    # Use sudo only if regular rm fails
    if ! rm -rf venv logs exports launchers 2>/dev/null; then
        log_warn "Permission denied, trying with sudo..."
        sudo rm -rf venv logs exports launchers || log_error "Failed to remove directories even with sudo"
    fi
fi
log_success "Cleanup complete"

# 2) Create & activate virtual environment
log_info "Creating fresh virtual environment..."
python3 -m venv venv
source venv/bin/activate
log_success "Virtual environment created and activated"

# 3) Install package and dependencies
log_info "Installing file2ai in editable mode..."
pip install --upgrade pip
pip install -e .
pip install pytest pytest-cov
log_success "Installation complete"

# 4) Run tests with coverage
log_info "Running tests with coverage..."
pytest --cov=file2ai || log_error "Tests failed!"
log_success "Tests passed"

# 5) Test local directory export
log_info "Testing local directory export..."
python file2ai.py --local-dir . || log_error "Local export failed!"

# 6) Test normal remote repo export
log_info "Testing normal remote repo export..."
python file2ai.py --repo-url https://github.com/michaeljabbour/git2txt || log_error "Remote repo export failed!"

# 7) Test subdir/extra path export
log_info "Testing subdir/extra path export..."
python file2ai.py --repo-url-sub https://github.com/michaeljabbour/git2txt/pulls || log_error "Subdir export failed!"

# 8) Validate outputs
log_info "Validating output files..."

# Check local export
txt_file="exports/file2ai_export.txt"
if [ -f "$txt_file" ]; then
    log_info "Local directory export found"
    
    # Basic content validation
    if grep -q "Generated by file2ai" "$txt_file" && \
       grep -q "Directory Structure:" "$txt_file" && \
       grep -q "=" "$txt_file"; then
        log_success "Local export structure looks correct"
    else
        log_error "Local export structure is invalid"
    fi
    
    # Check file size
    size=$(wc -c < "$txt_file")
    if [ "$size" -gt 100 ]; then
        log_success "Local export has reasonable size ($size bytes)"
    else
        log_error "Local export seems too small ($size bytes)"
    fi
else
    log_error "Missing local export file: $txt_file"
fi

# Check remote repo export
txt_file="exports/file2ai_export.txt"
if [ -f "$txt_file" ]; then
    log_info "Remote repo text export found"
    
    # Basic content validation
    if grep -q "Generated by file2ai" "$txt_file" && \
       grep -q "Directory Structure:" "$txt_file" && \
       grep -q "=" "$txt_file"; then
        log_success "Text export structure looks correct"
    else
        log_error "Text export structure is invalid"
    fi
    
    # Check file size
    size=$(wc -c < "$txt_file")
    if [ "$size" -gt 1000 ]; then
        log_success "Text export has reasonable size ($size bytes)"
    else
        log_error "Text export seems too small ($size bytes)"
    fi
else
    log_error "Missing text export file: $txt_file"
fi

# Check subdir export
subdir_file="exports/file2ai_export(1).txt"
if [ -f "$subdir_file" ]; then
    log_info "Subdir export found"
    if grep -q "Generated by file2ai" "$subdir_file"; then
        log_success "Subdir export structure looks correct"
    else
        log_error "Subdir export structure is invalid"
    fi
else
    log_error "Missing subdir export file: $subdir_file"
fi

log_success "All validation checks passed!"
log_info "Done."
