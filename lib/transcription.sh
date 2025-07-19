#!/bin/bash

# Function to send success notification
function send_success_notification() {
    local transcription="$1"
    local preview
    
    if command -v notify-send >/dev/null 2>&1; then
        # Truncate transcription to first 50 characters for preview
        if [ ${#transcription} -gt 50 ]; then
            preview="${transcription:0:47}..."
        else
            preview="$transcription"
        fi
        
        notify-send -i dialog-information -t 3000 "Transcription Complete" "$preview"
    fi
}

# Function to send failure notification
function send_failure_notification() {
    local max_retries="$1"
    
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -i dialog-error -t 5000 "Transcription Failed" "Failed after $max_retries attempts. Check logs for details."
    fi
}

# Function to correct and format transcribed text
function correct_and_format_text() {
    local text="$1"
    local dictionary_file="${DICTIONARY:-$SCRIPT_DIR/docs/dictionary.md}"

    if [ -f "$dictionary_file" ]; then
        echo "Applying corrections from: $dictionary_file" >&2
        echo "Original text: $text" >&2

        while IFS=: read -r incorrect correct; do
            # Use a temporary variable to check if a replacement happened
            local original_text="$text"
            text=$(echo "$text" | sed "s/$incorrect/$correct/gI")
            if [ "$original_text" != "$text" ]; then
                echo "  - Corrected '$incorrect' to '$correct'" >&2
            fi
        done <"$dictionary_file"

        echo "Corrected text: $text" >&2
    else
        echo "Dictionary file not found: $dictionary_file" >&2
    fi

    echo "$text"
}

# Convert the audio to text using the OpenAI Whisper API
function convert_audio_to_text() {
    local output_file=$1
    local max_retries=3
    local attempt=1

    local curl_command="curl -s --request POST \
    --url https://api.groq.com/openai/v1/audio/transcriptions \
    --header \"Authorization: Bearer ${TOKEN}\" \
    --header \"Content-Type: multipart/form-data\" \
    --form \"file=@$output_file\" \
    --form \"model=$MODEL\" \
    --form \"temperature=0.02\" \
    --form \"response_format=verbose_json\""

    if [ -n "$TRANSLATE" ]; then
        curl_command=$(echo "$curl_command" | sed 's|/transcriptions|/translations|')
    fi
    if [ "$GRANULARITIES" != "none" ]; then
        curl_command+=" --form \"timestamp_granularities[]=${GRANULARITIES}\""
    fi
    if [ -n "$PROMPT" ]; then
        curl_command+=" --form \"prompt=$PROMPT\""
    fi
    if [ -n "$LANGUAGE" ]; then
        curl_command+=" --form \"language=$LANGUAGE\""
    fi

    while [[ $attempt -le $max_retries ]]; do
        local response
        response=$(eval "$curl_command")
        local curl_exit_code=$?

        # 1. Check for curl command failure
        if [[ $curl_exit_code -ne 0 ]]; then
            log_error "Attempt $attempt/$max_retries: Curl command failed with exit code $curl_exit_code."
            sleep 1
            ((attempt++))
            continue
        fi

        # 2. Check for valid JSON
        if ! echo "$response" | jq . >/dev/null 2>&1; then
            log_error "Attempt $attempt/$max_retries: API did not return valid JSON. Response: $response"
            sleep 1
            ((attempt++))
            continue
        fi

        # 3. Check for structured JSON error from the API
        if echo "$response" | jq -e '.error' >/dev/null; then
            local error_message
            error_message=$(echo "$response" | jq -r '.error.message')
            log_error "Attempt $attempt/$max_retries: API returned a structured error: $error_message"
            sleep 1
            ((attempt++))
            continue
        fi

        # If we reach here, the response is valid JSON without a known error object.
        # Attempt to parse the transcription text.
        local transcription
        if [ "$GRANULARITIES" != "none" ]; then
            transcription=$(echo "$response")
        else
            transcription=$(echo "$response" | jq -r '.text' | sed 's/^\s*//')
        fi

        if [ -n "$transcription" ] && [ "$transcription" != "null" ]; then
            # --- SUCCESS ---
            log_error "Transcription successful on attempt $attempt."

            if [ "$AUTOCORRECT" = true ]; then
                transcription=$(correct_and_format_text "$transcription")
            fi

            # Send success notification
            send_success_notification "$transcription"

            printf "\r\e[K"
            xsel -cb
            xsel -a -b <<<"$transcription"

            if [ -n "$DEST_FILE" ]; then
                echo "$transcription" | tee -a "$DEST_FILE"
            else
                echo "$transcription"
            fi

            if [ -n "$PIPE_TO_CMD" ]; then
                local result
                result=$(echo "$transcription" | $PIPE_TO_CMD)
                echo "$result"
            fi

            if [ -z "$AUDIO_FILE" ]; then
                rm -f "$output_file"
            fi

            return 0 # Exit function successfully
        fi

        # If transcription is empty/null, something is unexpected in the JSON. Retry.
        log_error "Attempt $attempt/$max_retries: Failed to parse .text from a valid JSON response. Response: $response"
        sleep 1
        ((attempt++))
    done

    # If the loop finishes, all retries have failed.
    log_error "Transcription failed for $output_file after $max_retries attempts."
    
    # Send failure notification
    send_failure_notification "$max_retries"
    
    printf "\r\e[K\e[1;31mTranscription failed after %s attempts.\e[0m\n" "$max_retries"
    rm -f "$output_file"
    return 1
}
