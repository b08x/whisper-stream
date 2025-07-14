#! /usr/bin/env bash

# Bashsmith template patterns for safety
set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

# Set up error logging
ERROR_LOG="/tmp/whisper-stream-error.log"

# The following global redirection is disabled as it prevents 'gum' from
# detecting terminal color support. Error logging is now handled manually
# within the log_error function.
#
# exec 2> >(tee -a "$ERROR_LOG" >&2)

# Function to log errors with timestamp
function log_error() {
    # Manually append the message to the log file.
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$ERROR_LOG"
}

# Function to rotate error log if it gets too large
function rotate_error_log() {
    if [[ -f "$ERROR_LOG" && $(stat -f%z "$ERROR_LOG" 2>/dev/null || stat -c%s "$ERROR_LOG" 2>/dev/null) -gt 1048576 ]]; then
        # If log is larger than 1MB, keep only the last 500 lines
        tail -n 500 "$ERROR_LOG" >"${ERROR_LOG}.tmp" && mv "${ERROR_LOG}.tmp" "$ERROR_LOG"
        log_error "Log rotated - keeping last 500 lines"
    fi
}
