#!/bin/bash

# Function to correct and format transcribed text
function correct_and_format_text() {
    local text="$1"
    local dictionary_file="${DICTIONARY:-$HOME/.config/whisper-stream/dictionary.md}"

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
    local base_url
    if [ -n "$TRANSLATE" ]; then
        base_url="$WHISPER_URL_TRANSLATIONS"
    else
        base_url="$WHISPER_URL_TRANSCRIPTIONS"
    fi
    local curl_command="curl -s --request POST \
    --url $base_url \
    --header \"Authorization: Bearer ${TOKEN}\" \
    --header \"Content-Type: multipart/form-data\" \
    --form \"file=@$output_file\" \
    --form \"model=$MODEL\" \
    --form \"temperature=0.02\" \
    --form \"response_format=verbose_json\""

    # Add optional parameters to the curl command when GRANULARITIES is not set to none
    if [ "$GRANULARITIES" != "none" ]; then
        curl_command+=" --form \"timestamp_granularities[]=${GRANULARITIES}\""
    fi

    if [ -n "$PROMPT" ]; then
        curl_command+=" --form \"prompt=$PROMPT\""
    fi

    if [ -n "$LANGUAGE" ]; then
        curl_command+=" --form \"language=$LANGUAGE\""
    fi

    max_retries=3
    retry_count=0
    response=""

    while [[ $retry_count -lt $max_retries ]]; do
        response=$(eval "$curl_command")
        if [ $? -eq 0 ]; then
            # Check for API error in the response
            if echo "$response" | jq -e '.error' >/dev/null; then
                error_message=$(echo "$response" | jq -r '.error.message')
                log_error "API Error: $error_message"
                printf "\r\e[K\e[1;31mAPI Error: %s\e[0m\n" "$error_message"
                # Decide if this is a retryable error or not
                # For now, we'll retry on any API error
            else
                # Success, break the loop
                break
            fi
        else
            log_error "Curl command failed"
            printf "\r\e[K\e[1;31m.\e[0m"
        fi

        retry_count=$((retry_count + 1))
        sleep 1 # Wait a second before retrying
    done

    if [[ $retry_count -ge $max_retries ]]; then
        log_error "Transcription failed after $max_retries attempts."
        printf "\r\e[K\e[1;31mTranscription failed after %s attempts.\e[0m\n" "$max_retries"
        rm -f "$output_file"
        return 1
    fi

    local transcription
    # if GRAINULARITIES is set to `none`, `.text` will be returned
    if [ "$GRANULARITIES" != "none" ]; then
        transcription=$(echo "$response")
    else
        transcription=$(echo "$response" | jq -r '.text' | sed 's/^\s*//')
    fi

    # Check if jq successfully parsed the text
    if [ -z "$transcription" ] || [ "$transcription" == "null" ]; then
        log_error "Failed to parse transcription from API response."
        log_error "Response: $response"
        printf "\r\e[K\e[1;31mFailed to parse transcription.\e[0m\n"
        rm -f "$output_file"
        return 1
    fi

    if [ "$AUTOCORRECT" = true ]; then
        transcription=$(correct_and_format_text "$transcription")
    fi

    printf "\r\e[K"
    xsel -cb
    xsel -a -b <<<"$transcription"
    echo "$transcription"

    if [ -n "$PIPE_TO_CMD" ]; then
        result=$(echo "$transcription" | $PIPE_TO_CMD)
        echo "$result"
    fi

    # Remove the output audio file unless the `-f` option is specified
    if [ -z "$AUDIO_FILE" ]; then
        rm -f "$output_file"
    fi

    # Accumulate the transcribed text in a temporary file
    # this is necessary for the data to be available when the script terminates
    echo "$transcription" >>"/tmp/whisper-stream_temp_transcriptions.txt"
}
