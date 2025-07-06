# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a bash script application called "whisper-stream" that provides continuous speech-to-text transcription using the Groq API (Whisper model). The script records audio from microphones or processes audio files, detecting silence between speech segments and transcribing them to text.

## Key Architecture

The application is a single bash script (`whisper-stream`) with the following core components:

- **Audio Input Handling**: Supports both live microphone recording and file transcription
- **Cross-platform Device Detection**: Functions for macOS (using SwitchAudioSource) and Linux (using pactl/arecord)
- **API Integration**: Uses Groq's Whisper API endpoints for transcription and translation
- **Output Management**: Supports clipboard copying, file output, and piping to commands
- **Interactive UI**: Uses `gum` for device selection and file picking
- **Configuration Management**: Loads/saves settings from `~/.config/whisper-stream/config`
- **Error Logging**: Comprehensive logging to `/tmp/whisper-stream-error.log` with rotation

## Dependencies

Required system dependencies:
- `curl` - API requests
- `jq` - JSON processing  
- `sox` - Audio recording and processing
- `xclip` (Linux) or `pbcopy` (macOS) - Clipboard operations
- `gum` - Interactive UI components (required, not optional)
- `SwitchAudioSource` (macOS, optional) - Audio device switching
- `pactl` or `arecord` (Linux) - Audio device detection

Environment variable: `GROQ_API_KEY` (API authentication)

## Common Usage Patterns

The script operates in several modes:
1. **Continuous recording** (default): Records until silence is detected
2. **One-shot mode** (`-o`): Records once and exits
3. **File transcription** (`-f`): Processes existing audio files
4. **Interactive mode**: Uses gum for device/file selection when no parameters specified

## Configuration

Key script parameters (lines 32-56):
- API endpoints point to Groq instead of OpenAI (`WHISPER_URL_TRANSCRIPTIONS`, `WHISPER_URL_TRANSLATIONS`)
- Model: `whisper-large-v3-turbo`
- Default notebook root: `${HOME}/Notebooks`
- Supports various audio formats: m4a, mp3, webm, mp4, mpga, wav, mpeg
- Config file location: `~/.config/whisper-stream/config`
- Temporary files stored in `/tmp/` directory

## Critical Implementation Details

- **Audio Processing Pipeline**: SoX recording → silence detection → Groq API → clipboard/file output
- **Cross-platform Compatibility**: OS detection via `uname` for device handling and clipboard operations
- **Error Handling**: 3-attempt retry logic for API calls (lines 843-875)
- **Silence Detection**: Uses SoX stats to check maximum amplitude against threshold (lines 770-785)
- **Device Selection**: Interactive PulseAudio device selection with fallback to system default
- **File Validation**: Checks audio file existence, size (<25MB), and format before processing
- **Signal Handling**: Proper cleanup on SIGINT/SIGTSTP with background process termination

## Key Functions

- `load_config()` - Loads settings from config file (lines 129-193)
- `select_input_device()` - Interactive device selection with gum (lines 526-556)
- `convert_audio_to_text()` - Main transcription function with retry logic (lines 813-915)
- `handle_exit()` - Cleanup and final output processing (lines 917-990)
- `is_silent()` - Audio silence detection using SoX (lines 770-785)

## File Structure

- `whisper-stream` - Main executable bash script (1084 lines)
- `README.md` - User documentation with installation and usage examples
- `LICENSE` - MIT license
- `dictionary.md` - Autocorrect dictionary file
- `CLAUDE.md` - This file

## Development Notes

- No build process required - single bash script
- No test framework present
- Script must be executable (`chmod +x`)
- Error logging automatically rotates when > 1MB
- Temporary files automatically cleaned up on exit
- Configuration persists device selections between runs