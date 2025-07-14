#!/bin/bash

# Display help information for script usage
function display_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -v, --volume <value>          Set the minimum volume threshold (default: 1%)"
    echo "  -s, --silence <value>         Set the minimum silence length (default: 1.5)"
    echo "  -o, --oneshot                 Enable one-shot mode"
    echo "  -d, --duration <value>        Set the recording duration in seconds (default: 0, continuous)"
    echo "  -t, --token <value>           Set the OpenAI API token"
    echo "  -nr, --notebooks-root <value> Set the Notebooks root directory"
    echo "  -n, --notebook <value>        Set the Notebook to store dictations"
    echo "  -g, --granularities <value>   Set the timestamp granularities (segment or word)"
    echo "  -r, --prompt <value>          Set the prompt for the API call"
    echo "  -l, --language <value>        Set the language in ISO-639-1 format"
    echo "  -f, --file <value>            Set the audio file to be transcribed"
    echo "  -i, --input-device <value>    Set the input device for recording"
    echo "  -tr, --translate              Translate the transcribed text to English"
    echo "  -p2, --pipe-to <cmd>          Pipe the transcribed text to the specified command (e.g., 'wc -m')"
    echo "  -df <file>, --dest-file <file> Set the destination file for transcriptions"
    echo "  -V, --version                 Show the version number"
    echo "  -q, --quiet                   Suppress the banner and settings"
    echo "  -ac, --autocorrect            Enable autocorrect"
    echo "  -dict, --dictionary <file>    Set the dictionary file for autocorrect"
    echo "  --reset-config                Reset configuration and run first-time setup"
    echo "  -h, --help                    Display this help message"
    echo "To stop the app, press Ctrl+C"
    exit 0
}

# Function to display current settings
function display_settings() {
    if [ "$QUIET_MODE" = true ]; then
        return
    fi

    echo ""
    gum_title "Whisper Stream Speech-to-Text Transcriber ${VERSION}"
    echo '-----------------------------------------------' | gum_style --bold --foreground 212
    echo "Current settings:"
    echo "  Error log: $ERROR_LOG"
    echo "  Volume threshold: $MIN_VOLUME"
    echo "  Silence length: $SILENCE_LENGTH seconds"
    echo "  Input language: ${LANGUAGE:-Not specified}"

    if [ -n "$TRANSLATE" ]; then
        echo "  Translate to English: $TRANSLATE"
    fi

    if [ -n "$OUTPUT_DIR" ]; then
        echo "  Output Dir: $OUTPUT_DIR"
    fi

    if [ -n "$DEST_FILE" ]; then
        echo "  Destination File: $DEST_FILE"
    fi

    # Display selected or default input device
    if [ -n "$SELECTED_INPUT_DEVICE" ] && [ "$SELECTED_INPUT_DEVICE" != "System Default" ]; then
        echo "  Selected Input Device: $SELECTED_INPUT_DEVICE"
    else
        # Try to get the system default device name for display purposes
        local default_device_display
        default_device_display=$(get_input_device) # Use existing function
        if [ -n "$default_device_display" ]; then
            echo "  Input device: $default_device_display (System Default)"
        else
            echo "  Input device: System Default"
        fi
    fi

    # Get the input volume based on the operating system
    local input_volume
    input_volume=$(get_input_volume)
    if [ -n "$input_volume" ]; then
        echo "  Input volume: $input_volume"
    fi

    echo '-----------------------------------------------' | gum_style --bold --foreground 212
    echo "To stop the app, press $(echo 'Ctrl+C' | gum_style --bold --foreground 36)"
    echo ""
}

# Display a rotating spinner animation
function spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n "Transcribing... "
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "%c" "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b"
    done
    # Clear the spinner and "Transcribing..." text
    printf "\r%s\r" "                               "
}
