#!/bin/bash

# Parse command-line arguments to set script parameters
function parse_arguments() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -v | --volume)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            MIN_VOLUME="$2"
            if [[ "$MIN_VOLUME" != *% ]]; then
                MIN_VOLUME+="%"
            fi
            shift
            shift
            ;;
        -s | --silence)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            SILENCE_LENGTH="$2"
            shift
            shift
            ;;
        -o | --oneshot)
            ONESHOT=true
            shift
            ;;
        -d | --duration)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            DURATION="$2"
            shift
            shift
            ;;
        -t | --token)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            TOKEN="$2"
            shift
            shift
            ;;
        -nr | --notebook-root)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            NOTEBOOK_ROOT="$2"
            shift
            shift
            ;;
        -n | --notebook)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            NOTEBOOK="$2"
            # check if the output directory exists
            if [ ! -d "$NOTEBOOK_ROOT/$NOTEBOOK" ]; then
                echo "Directory does not exist: $NOTEBOOK_ROOT/$NOTEBOOK"
                exit 1
            fi
            shift
            shift
            ;;
        -g | --granularities)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            GRANULARITIES="$2"
            shift
            shift
            ;;
        -r | --prompt)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            PROMPT="$2"
            shift
            shift
            ;;
        -l | --language)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            LANGUAGE="$2"
            shift
            shift
            ;;
        -tr | --translate)
            TRANSLATE=true
            shift
            ;;
        -p2 | --pipe-to)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing cmd for $1"
                exit 1
            fi
            PIPE_TO_CMD="$2"
            shift
            shift
            ;;
        -f | --file)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            AUDIO_FILE="$2"
            check_audio_file "$AUDIO_FILE"
            shift
            shift
            ;;
        -V | --version)
            SHOW_VERSION=true
            shift
            ;;
        -q | --quiet)
            QUIET_MODE=true
            shift
            ;;
        -ac | --autocorrect)
            AUTOCORRECT=true
            shift
            ;;
        -dict | --dictionary)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            DICTIONARY="$2"
            shift
            shift
            ;;
        -i | --input-device)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            SELECTED_INPUT_DEVICE="$2"
            shift
            shift
            ;;
        -h | --help)
            display_help
            ;;
        -df | --dest-file)
            if [[ ! $2 || $2 == -* ]]; then
                echo "Error: Missing value for $1"
                exit 1
            fi
            DEST_FILE="$2"
            # Ensure the directory exists if a full path is given
            OUTPUT_DIR=$(dirname "$DEST_FILE")
            if [ ! -d "$OUTPUT_DIR" ]; then
                mkdir -p "$OUTPUT_DIR" || {
                    echo "Error: Could not create directory $OUTPUT_DIR"
                    exit 1
                }
            fi
            shift # past argument
            shift # past value
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
        esac
    done
}
