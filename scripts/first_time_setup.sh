#! /usr/bin/env bash

# Find the script's own directory to locate lib files
_FTS_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Source gum_wrapper.sh, searching in common locations
if [ -f "$_FTS_SCRIPT_DIR/../lib/gum_wrapper.sh" ]; then
  # shellcheck source=../lib/gum_wrapper.sh
  source "$_FTS_SCRIPT_DIR/../lib/gum_wrapper.sh"
elif [ -f "/usr/share/whisper-stream/lib/gum_wrapper.sh" ]; then
  # shellcheck source=/usr/share/whisper-stream/lib/gum_wrapper.sh
  source "/usr/share/whisper-stream/lib/gum_wrapper.sh"
else
  echo "Error: gum_wrapper.sh not found." >&2
  exit 1
fi

# DESCRIPTION
# First-time setup and configuration for whisper-stream

# Bashsmith template patterns for safety
set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

# CONSTANTS
readonly SETUP_MODULE="first_time_setup"
readonly CONFIG_DIR="$HOME/.config/whisper-stream"
readonly CONFIG_FILE="$CONFIG_DIR/config"
readonly FIRST_RUN_FLAG="$CONFIG_DIR/.first_run_complete"

# FUNCTIONS

# Check if this is the first run
is_first_run() {
    [[ ! -f "$FIRST_RUN_FLAG" ]]
}

# Create configuration directory
create_config_directory() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        gum_info "Created configuration directory: $CONFIG_DIR"
    fi
}

# Welcome message for first-time setup
show_welcome_message() {
    gum_style \
        --foreground 014 --border-foreground 024 --border double \
        --align center --width 60 --margin "1 2" --padding "2 4" \
        "Welcome to whisper-stream!" \
        "" \
        "First-time setup wizard" \
        "Let's configure your speech-to-text environment"
    
    echo
    gum_info "This wizard will help you set up whisper-stream for optimal performance."
    echo
    
    if ! gum_confirm "Would you like to proceed with the configuration?"; then
        gum_info "Setup cancelled. You can run whisper-stream again anytime to configure."
        exit 0
    fi
}

# Validate API key format
validate_api_key() {
    local api_key="$1"
    
    # Basic validation - Groq API keys typically start with 'gsk_'
    if [[ ${#api_key} -lt 20 ]]; then
        gum_error "API key seems too short. Please check your key."
        return 1
    fi
    
    if [[ ! "$api_key" =~ ^gsk_ ]]; then
        gum_warn "API key doesn't start with 'gsk_' - this might not be a valid Groq API key."
        if ! gum_confirm "Continue anyway?"; then
            return 1
        fi
    fi
    
    return 0
}

# Test API key by making a simple request
test_api_key() {
    local api_key="$1"
    
    gum_info "Testing API key..."
    
    # Simple API test (check if we can reach the endpoint)
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        "https://api.groq.com/openai/v1/models" \
        --connect-timeout 10 \
        --max-time 30) || {
        gum_error "Failed to connect to Groq API. Please check your internet connection."
        return 1
    }
    
    case "$response" in
        200)
            gum_success "API key is valid and working!"
            return 0
            ;;
        401)
            gum_error "API key is invalid or expired."
            return 1
            ;;
        403)
            gum_error "API key doesn't have required permissions."
            return 1
            ;;
        *)
            gum_warn "Unexpected response from API (HTTP $response). Key might still work."
            return 0
            ;;
    esac
}

# Configure API key
configure_api_key() {
    gum_info "Step 1: Groq API Configuration"
    echo
    
    # Check if API key is already in environment
    if [[ -n "${GROQ_API_KEY:-}" ]]; then
        gum_info "Found existing API key in environment variables."
        if gum_confirm "Would you like to use the existing API key?"; then
            echo "GROQ_API_KEY=\"$GROQ_API_KEY\"" >> "$CONFIG_FILE"
            if test_api_key "$GROQ_API_KEY"; then
                return 0
            else
                gum_warn "Existing API key failed validation. Please enter a new one."
            fi
        fi
    fi
    
    # Interactive API key setup
    gum_info "You'll need a Groq API key to use whisper-stream."
    gum_info "Get your free API key from: https://console.groq.com/keys"
    echo
    
    local api_key
    while true; do
        api_key=$(gum_input --password --placeholder "Enter your Groq API key")
        
        if [[ -z "$api_key" ]]; then
            gum_error "API key cannot be empty."
            continue
        fi
        
        if validate_api_key "$api_key"; then
            if test_api_key "$api_key"; then
                break
            else
                gum_error "API key validation failed. Please try again."
                continue
            fi
        fi
    done
    
    # Save API key to config
    echo "GROQ_API_KEY=\"$api_key\"" >> "$CONFIG_FILE"
    gum_success "API key configured successfully!"
}

# Configure audio settings
configure_audio_settings() {
    gum_info "Step 2: Audio Configuration"
    echo
    
    # Audio device selection
    gum_info "Configuring audio input device..."
    
    local device_choice
    device_choice=$(gum_choose "Auto-detect (recommended)" "Select specific device" \
        --header "Audio Input Device")
    
    if [[ "$device_choice" == "Select specific device" ]]; then
        local selected_device
        selected_device=$(select_input_device)
        if [[ -n "$selected_device" && "$selected_device" != "System Default" ]]; then
            echo "SELECTED_INPUT_DEVICE=\"$selected_device\"" >> "$CONFIG_FILE"
            gum_success "Audio device configured: $selected_device"
        fi
    else
        gum_info "Audio device will be auto-detected on first use."
    fi
    
    # Audio sensitivity settings
    gum_info "Configuring audio sensitivity..."
    
    local sensitivity_choice
    sensitivity_choice=$(gum_choose "Default (recommended)" "Low sensitivity" "High sensitivity" "Custom" \
        --header "Audio Sensitivity")
    
    case "$sensitivity_choice" in
        "Low sensitivity")
            echo "MIN_VOLUME=\"3%\"" >> "$CONFIG_FILE"
            echo "SILENCE_LENGTH=\"2.0\"" >> "$CONFIG_FILE"
            gum_info "Low sensitivity configured (less likely to trigger on background noise)."
            ;;
        "High sensitivity")
            echo "MIN_VOLUME=\"0.5%\"" >> "$CONFIG_FILE"
            echo "SILENCE_LENGTH=\"1.0\"" >> "$CONFIG_FILE"
            gum_info "High sensitivity configured (more responsive to quiet speech)."
            ;;
        "Custom")
            local min_volume
            min_volume=$(gum_input --placeholder "1%" --prompt "Minimum volume threshold: ")
            local silence_length
            silence_length=$(gum_input --placeholder "1.5" --prompt "Silence length (seconds): ")
            
            echo "MIN_VOLUME=\"${min_volume:-1%}\"" >> "$CONFIG_FILE"
            echo "SILENCE_LENGTH=\"${silence_length:-1.5}\"" >> "$CONFIG_FILE"
            gum_info "Custom audio settings configured."
            ;;
        *)
            gum_info "Using default audio sensitivity settings."
            ;;
    esac
}

# Configure workspace and paths
configure_workspace() {
    gum_info "Step 3: Workspace Configuration"
    echo
    
    # Notebook root directory
    gum_info "Where would you like to store your transcriptions?"
    
    local notebook_choice
    notebook_choice=$(gum_choose "Default (~/Notebooks)" "Select custom directory" "Create new directory" \
        --header "Notebook Storage Location")
    
    case "$notebook_choice" in
        "Select custom directory")
            local custom_dir
            custom_dir=$(gum_file --directory --header "Select Notebook Directory" "$HOME")
            if [[ -n "$custom_dir" ]]; then
                echo "NOTEBOOK_ROOT=\"$custom_dir\"" >> "$CONFIG_FILE"
                gum_success "Notebook directory set to: $custom_dir"
            fi
            ;;
        "Create new directory")
            local new_dir_name
            new_dir_name=$(gum_input --placeholder "Transcriptions" --prompt "Directory name: ")
            local new_dir="$HOME/${new_dir_name:-Transcriptions}"
            
            if mkdir -p "$new_dir"; then
                echo "NOTEBOOK_ROOT=\"$new_dir\"" >> "$CONFIG_FILE"
                gum_success "Created and configured notebook directory: $new_dir"
            else
                gum_error "Failed to create directory. Using default."
            fi
            ;;
        *)
            local default_dir="$HOME/Notebooks"
            mkdir -p "$default_dir"
            echo "NOTEBOOK_ROOT=\"$default_dir\"" >> "$CONFIG_FILE"
            gum_info "Using default notebook directory: $default_dir"
            ;;
    esac
}

# Configure transcription preferences
configure_transcription_preferences() {
    gum_info "Step 4: Transcription Preferences"
    echo
    
    # Model selection
    gum_info "Choose the transcription model:"
    
    local model_choice
    model_choice=$(gum_choose \
        "whisper-large-v3-turbo (recommended - fast and accurate)" \
        "whisper-large-v3 (slower but potentially more accurate)" \
        --header "Transcription Model")
    
    case "$model_choice" in
        *"whisper-large-v3-turbo"*)
            echo "MODEL=\"whisper-large-v3-turbo\"" >> "$CONFIG_FILE"
            gum_info "Selected fast turbo model."
            ;;
        *"whisper-large-v3"*)
            echo "MODEL=\"whisper-large-v3\"" >> "$CONFIG_FILE"
            gum_info "Selected standard large model."
            ;;
    esac
    
    # Language settings
    gum_info "Language configuration:"
    
    local language_choice
    language_choice=$(gum_choose "Auto-detect (recommended)" "English only" "Other language" \
        --header "Primary Language")
    
    case "$language_choice" in
        "English only")
            echo "LANGUAGE=\"en\"" >> "$CONFIG_FILE"
            gum_info "Set to English-only transcription."
            ;;
        "Other language")
            gum_info "Language codes: en, es, fr, de, it, pt, ru, ja, ko, zh, etc."
            local lang_code
            lang_code=$(gum_input --placeholder "en" --prompt "Language code: ")
            if [[ -n "$lang_code" ]]; then
                echo "LANGUAGE=\"$lang_code\"" >> "$CONFIG_FILE"
                gum_info "Language set to: $lang_code"
            fi
            ;;
        *)
            gum_info "Auto-detect enabled (default)."
            ;;
    esac
    
    # Auto-correction
    if gum_confirm "Enable auto-correction using dictionary?"; then
        echo "AUTOCORRECT=true" >> "$CONFIG_FILE"
        gum_info "Auto-correction enabled."
    else
        echo "AUTOCORRECT=false" >> "$CONFIG_FILE"
        gum_info "Auto-correction disabled."
    fi
}

# Configure additional features
configure_additional_features() {
    gum_info "Step 5: Additional Features"
    echo
    
    # Default file behavior
    local file_behavior
    file_behavior=$(gum_choose \
        "Auto-generate daily files (recommended)" \
        "Always prompt for file location" \
        "Use single continuous file" \
        --header "Default File Behavior")
    
    case "$file_behavior" in
        *"Always prompt"*)
            echo "DEFAULT_FILE_BEHAVIOR=\"prompt\"" >> "$CONFIG_FILE"
            gum_info "Will prompt for file location each time."
            ;;
        *"single continuous"*)
            echo "DEFAULT_FILE_BEHAVIOR=\"single\"" >> "$CONFIG_FILE"
            gum_info "Will use single continuous file."
            ;;
        *)
            echo "DEFAULT_FILE_BEHAVIOR=\"daily\"" >> "$CONFIG_FILE"
            gum_info "Will auto-generate daily files."
            ;;
    esac
    
    # Quiet mode preference
    if gum_confirm "Enable quiet mode by default? (reduces output messages)"; then
        echo "QUIET_MODE=true" >> "$CONFIG_FILE"
        gum_info "Quiet mode enabled by default."
    fi
    
    # Clipboard integration
    if gum_confirm "Copy transcriptions to clipboard automatically?"; then
        echo "AUTO_CLIPBOARD=true" >> "$CONFIG_FILE"
        gum_info "Auto-clipboard enabled."
    fi
}

# Show configuration summary
show_configuration_summary() {
    gum_info "Configuration Summary"
    echo
    
    gum_style \
        --foreground 012 --border-foreground 006 --border rounded \
        --align left --width 60 --margin "1 2" --padding "1 2" \
        "Configuration saved to:" \
        "$CONFIG_FILE" \
        "" \
        "You can edit this file anytime to modify settings."
    
    echo
    gum_info "Configuration file contents:"
    gum_style \
        --foreground 008 --border-foreground 004 --border rounded \
        --align left --margin "1 2" --padding "1 2" \
        "$(cat "$CONFIG_FILE")"
}

# Mark first run as complete
mark_first_run_complete() {
    touch "$FIRST_RUN_FLAG"
    echo "# First-time setup completed on $(date)" >> "$FIRST_RUN_FLAG"
}

# Main setup orchestration
run_first_time_setup() {
    gum_info "Initializing first-time setup..."
    
    # Ensure gum is available
    gum_init
    
    # Create configuration directory
    create_config_directory
    
    # Start fresh config file
    echo "# whisper-stream configuration" > "$CONFIG_FILE"
    echo "# Generated on $(date)" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
    
    # Show welcome and run setup steps
    show_welcome_message
    
    configure_api_key
    echo
    
    configure_audio_settings
    echo
    
    configure_workspace
    echo
    
    configure_transcription_preferences
    echo
    
    configure_additional_features
    echo
    
    show_configuration_summary
    
    # Mark setup as complete
    mark_first_run_complete
    
    echo
    gum_success "First-time setup completed successfully!"
    echo
    gum_info "You can now use whisper-stream. Run 'whisper-stream --help' for usage information."
    echo
    
    if gum_confirm "Would you like to start whisper-stream now?"; then
        return 0  # Signal to continue to main application
    else
        gum_info "Setup complete. Run 'whisper-stream' when you're ready to start transcribing."
        exit 0
    fi
}

# Reset configuration (for testing or reconfiguration)
reset_configuration() {
    if [[ -f "$CONFIG_FILE" ]]; then
        rm -f "$CONFIG_FILE"
    fi
    
    if [[ -f "$FIRST_RUN_FLAG" ]]; then
        rm -f "$FIRST_RUN_FLAG"
    fi
    
    gum_info "Configuration reset. Run whisper-stream to set up again."
}

# Export functions for use in main script
export -f is_first_run
export -f run_first_time_setup
export -f reset_configuration