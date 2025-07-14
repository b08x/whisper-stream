#! /usr/bin/env bash

# Bashsmith template patterns for safety
set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

# Check the validity of the provided audio file
function check_audio_file() {
    local file=$1

    # Check if the file exists
    if [ ! -f "$file" ]; then
        echo "File does not exist: $file"
        exit 1
    fi

    # Check if the file is not empty
    if [ ! -s "$file" ]; then
        echo "File is empty: $file"
        exit 1
    fi

    # Check if the file size is under 25MB
    local filesize
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        filesize=$(stat -c%s "$file")
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        filesize=$(stat -f%z "$file")
    else
        echo "Unknown operating system"
        exit 1
    fi
    if [ "$filesize" -gt 26214400 ]; then
        echo "File size is over 25MB: $file"
        exit 1
    fi

    # Check if the file format is acceptable
    local ext="${file##*.}"
    case "$ext" in
    m4a | mp3 | webm | mp4 | mpga | wav | mpeg) ;;
    *)
        echo "File format is not acceptable: $file"
        exit 1
        ;;
    esac
}

# Function to list available audio input devices on Linux
function list_input_devices() {
    if command -v pactl &>/dev/null; then
        # Use PulseAudio device names (more compatible with SoX)
        pactl list short sources | while read -r index name module format state; do
            # Skip monitor devices
            if [[ "$name" != *.monitor ]]; then
                # Get a friendly description
                local desc
                desc=$(pactl list sources | grep -A 10 "Name: $name" | grep "Description:" | sed 's/.*Description: //')
                echo "$name [$desc]"
            fi
        done
    elif command -v arecord &>/dev/null; then
        # Fallback to ALSA hardware devices
        arecord -l | grep '^card' | while read -r line; do
            local card
            card=$(echo "$line" | sed -n 's/card \([0-9]*\):.*/\1/p')
            local device
            device=$(echo "$line" | sed -n 's/.*device \([0-9]*\):.*/\1/p')
            local name
            name=$(echo "$line" | sed -n 's/.*: \([^[]*\) \[.*/\1/p')
            echo "hw:$card,$device [$name]"
        done
    else
        echo "Error: Neither pactl nor arecord found. Cannot list devices." >&2
        return 1
    fi
}

# Function to select an input device using gum
function select_input_device() {
    local devices_list=()

    echo "Detecting input devices..." >&2

    # Read devices into an array
    mapfile -t devices_list < <(list_input_devices)

    if [ ${#devices_list[@]} -eq 0 ]; then
        echo "No input devices found. Using system default." >&2
        echo ""
        return 1
    fi

    # Use gum_choose to select a device
    local selected_device
    selected_device=$(printf "System Default\n%s\n" "${devices_list[@]}" | gum_choose --header "Select Input Device")

    # Handle cancellation or "System Default" selection
    if [ -z "$selected_device" ] || [ "$selected_device" == "System Default" ]; then
        echo "Using system default input device." >&2
        echo ""
        return 0
    fi

    # Extract device name from the selection (remove description)
    local device_id
    device_id=$(echo "$selected_device" | sed 's/\([^ ]*\) \[.*/\1/')
    echo "$device_id"
    return 0
}

# Function to get the name of the current audio input device on macOS
function get_macos_input_device() {
    # if SwitchAudioSource command available
    if [ -x "$(command -v SwitchAudioSource)" ]; then
        local input_device
        input_device=$(SwitchAudioSource -t input -c)
        echo "$input_device"
        return
    fi
}

# Function to get the volume of the audio input on macOS
function get_macos_input_volume() {
    local input_volume
    input_volume=$(osascript -e "input volume of (get volume settings)")
    echo "$input_volume%"
}

# Function to get the name of the current audio input device on Linux
function get_linux_input_device() {
    # if arecord command available
    if [ -x "$(command -v arecord)" ]; then
        local input_device
        input_device=$(arecord -l | grep -oP "(?<=card )\d+(?=:\s.*\[)")
        echo "hw:$input_device"
        return
    fi
}

function get_linux_input_volume() {
    # Check if amixer command is available and executable
    if [ -x "$(command -v amixer)" ]; then
        local input_volume
        input_volume=$(amixer sget Capture | grep 'Left:' | awk -F'[][]' '{ print $2 }')
        echo "$input_volume"
        return
    fi
}

# Get the name of the current audio input device based on OS
function get_input_device() {
    case "$(uname)" in
    Darwin)
        get_macos_input_device
        ;;
    Linux)
        get_linux_input_device
        ;;
    *)
        echo "Unknown operating system"
        ;;
    esac
}

# Get the volume level of the current audio input device based on OS
function get_input_volume() {
    case "$(uname)" in
    Darwin)
        get_macos_input_volume
        ;;
    Linux)
        get_linux_input_volume
        ;;
    *)
        echo "Unknown operating system"
        ;;
    esac
}

# Function to check if an audio file is silent
function is_silent() {
    local file=$1
    # Use SoX to get audio stats, then check the max amplitude
    local max_amp
    max_amp=$(sox "$file" -n stat 2>&1 | grep "Maximum amplitude" | awk '{print $3}')

    # Define a silence threshold
    local silence_threshold=0.001

    # Compare the max amplitude with the threshold
    if (($(echo "$max_amp < $silence_threshold" | bc -l))); then
        return 0 # 0 means true (is silent)
    else
        return 1 # 1 means false (is not silent)
    fi
}

function generate_default_dest_file() {
    local current_date
    current_date=$(date +%Y-%m-%d)
    # Expand HOME variable properly
    local expanded_notebook_root="${NOTEBOOK_ROOT/#\$HOME/$HOME}"
    local dest_dir="$expanded_notebook_root/Daily"
    local dest_file="$dest_dir/$current_date.md"

    # Create directory if it doesn't exist
    mkdir -p "$dest_dir"

    echo "$dest_file"
}
