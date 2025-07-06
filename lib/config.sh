#!/bin/bash

# Default configuration and versioning
VERSION="1.2.0"
AUTOCORRECT=false

# Setting the default values for the script parameters
MIN_VOLUME="1%"    # Minimum volume threshold
SILENCE_LENGTH=1.5 # Minimum silence duration in seconds
ONESHOT=false      # Flag to determine if the script should run once or continuously
DURATION=0         # Duration of the recording in seconds (0 means continuous)
WHISPER_URL_TRANSLATIONS="https://api.groq.com/openai/v1/audio/translations"
WHISPER_URL_TRANSCRIPTIONS="https://api.groq.com/openai/v1/audio/transcriptions"
MODEL="whisper-large-v3-turbo" # Model for the OpenAI API
TOKEN="${GROQ_API_KEY}"        # OpenAI API token
OUTPUT_DIR=""                  # Directory to save the transcriptions
DEST_FILE=""                   # File to write the transcriptions to
PROMPT=""                      # Prompt for the API call
LANGUAGE=""                    # Language code for transcription
TRANSLATE=""                   # Flag to indicate translation to English
AUDIO_FILE=""                  # Specific audio file for transcription
PIPE_TO_CMD=""                 # Command to pipe the transcribed text to
QUIET_MODE=false               # Flag to determine if the banner and settings should be suppressed
GRANULARITIES="none"           # Timestamp granularities for transcription: segment or word
NOTEBOOK_ROOT="$HOME/Notebooks"
NOTEBOOK=""
DICTIONARY=""
SELECTED_INPUT_DEVICE=""

# Function to load configuration from config file
function load_config() {
    local config_file="$HOME/.config/whisper-stream/config"

    if [[ -f "$config_file" ]]; then
        while IFS='=' read -r key value || [[ -n "$key" ]]; do
            # Skip empty lines and comments
            [[ "$key" =~ ^[[:space:]]*$ ]] && continue
            [[ "$key" =~ ^[[:space:]]*# ]] && continue

            # Remove leading/trailing whitespace
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Remove quotes if present
            value=$(echo "$value" | sed 's/^"//;s/"$//')

            case "$key" in
            MIN_VOLUME) MIN_VOLUME="$value" ;;
            SILENCE_LENGTH) SILENCE_LENGTH="$value" ;;
            ONESHOT)
                if [[ "$value" =~ ^(true|yes|1)$ ]]; then
                    ONESHOT=true
                else
                    ONESHOT=false
                fi
                ;;
            DURATION) DURATION="$value" ;;
            TOKEN) TOKEN="$value" ;;
            OUTPUT_DIR) OUTPUT_DIR="$value" ;;
            DEST_FILE) DEST_FILE="$value" ;;
            PROMPT) PROMPT="$value" ;;
            LANGUAGE) LANGUAGE="$value" ;;
            TRANSLATE)
                if [[ "$value" =~ ^(true|yes|1)$ ]]; then
                    TRANSLATE="true"
                else
                    TRANSLATE=""
                fi
                ;;
            AUDIO_FILE) AUDIO_FILE="$value" ;;
            PIPE_TO_CMD) PIPE_TO_CMD="$value" ;;
            QUIET_MODE)
                if [[ "$value" =~ ^(true|yes|1)$ ]]; then
                    QUIET_MODE=true
                else
                    QUIET_MODE=false
                fi
                ;;
            GRANULARITIES) GRANULARITIES="$value" ;;
            NOTEBOOK_ROOT) NOTEBOOK_ROOT="$value" ;;
            NOTEBOOK) NOTEBOOK="$value" ;;
            SELECTED_INPUT_DEVICE) SELECTED_INPUT_DEVICE="$value" ;;
            AUTOCORRECT)
                if [[ "$value" =~ ^(true|yes|1)$ ]]; then
                    AUTOCORRECT=true
                else
                    AUTOCORRECT=false
                fi
                ;;
            DICTIONARY) DICTIONARY="$value" ;;
            esac
        done <"$config_file"
    fi
}

function create_default_config_if_not_exists() {
    local config_file="$1"
    local config_dir
    config_dir=$(dirname "$config_file")

    mkdir -p "$config_dir"

    if [[ ! -f "$config_file" ]]; then
        cat >"$config_file" <<'EOF'
# whisper-stream configuration file
# This file is loaded when whisper-stream is called without arguments

# Audio recording settings
MIN_VOLUME=1%
SILENCE_LENGTH=1.5
ONESHOT=false
DURATION=0

# API settings
# TOKEN=your_groq_api_key_here

# Output settings
OUTPUT_DIR=""
DEST_FILE=""
QUIET_MODE=false

# Transcription settings
PROMPT=""
LANGUAGE=""
TRANSLATE=false
GRANULARITIES=none

# Notebook settings
NOTEBOOK_ROOT=${HOME}/Notebooks
NOTEBOOK=""

# Device settings
SELECTED_INPUT_DEVICE=""

# Advanced settings
AUDIO_FILE=""
PIPE_TO_CMD=""
AUTOCORRECT=false
DICTIONARY=""
EOF
    fi
}

# Function to write selected device back to config file
function write_device_to_config() {
    local device="$1"
    local config_file="$HOME/.config/whisper-stream/config"

    create_default_config_if_not_exists "$config_file"

    # Update the SELECTED_INPUT_DEVICE line in the config file
    if grep -q "^SELECTED_INPUT_DEVICE=" "$config_file"; then
        # Replace existing line
        sed -i "s/^SELECTED_INPUT_DEVICE=.*/SELECTED_INPUT_DEVICE=\"$device\"/" "$config_file"
    else
        # Add new line if it doesn't exist
        echo "SELECTED_INPUT_DEVICE=\"$device\"" >>"$config_file"
    fi

    echo "Saved device selection to config: $device" >&2
}

# Function to write notebook root back to config file
function write_notebook_root_to_config() {
    local notebook_root="$1"
    local config_file="$HOME/.config/whisper-stream/config"

    create_default_config_if_not_exists "$config_file"

    # Update the NOTEBOOK_ROOT line in the config file
    if grep -q "^NOTEBOOK_ROOT=" "$config_file"; then
        # Replace existing line
        sed -i "s|^NOTEBOOK_ROOT=.*|NOTEBOOK_ROOT=\"$notebook_root\"|" "$config_file"
    else
        # Add new line if it doesn't exist
        echo "NOTEBOOK_ROOT=\"$notebook_root\"" >>"$config_file"
    fi

    echo "Saved notebook root to config: $notebook_root" >&2
}
