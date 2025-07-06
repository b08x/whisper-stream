# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a bash script application called "whisper-stream" that provides continuous speech-to-text transcription using the Groq API (Whisper model). The script records audio from microphones or processes audio files, detecting silence between speech segments and transcribing them to text.

## Key Architecture

The application has been recently modularized from a single monolithic bash script into a clean, organized library structure. The main executable (`whisper-stream`) acts as a thin orchestrator that sources seven specialized modules from the `lib/` directory:

### Core Modules
- **logging.sh**: Error logging and automatic log rotation (prevents disk space issues)
- **gum_wrapper.sh**: Interactive UI framework with auto-installation and styled components
- **config.sh**: Configuration management with persistent storage and flexible parsing
- **arguments.sh**: Comprehensive command-line argument parsing with validation
- **audio.sh**: Cross-platform audio processing and device management
- **transcription.sh**: API integration with retry logic and text processing
- **ui.sh**: User interface display and formatted output

### Key Architectural Patterns
- **Separation of Concerns**: Each module has a single, well-defined responsibility
- **Cross-Platform Compatibility**: OS-specific implementations for macOS and Linux
- **Progressive Enhancement**: Graceful handling of optional dependencies
- **Configuration-First Design**: Config file loaded before argument parsing
- **Error Resilience**: Comprehensive error handling with retries and cleanup

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

## Common Development Commands

Since this is a bash script application:
- **Testing**: No formal test framework present - manual testing recommended
- **Linting**: Uses shellcheck directives in gum_wrapper.sh for specific disables
- **Execution**: `./whisper-stream` (ensure executable with `chmod +x`)
- **Development**: Edit modules in `lib/` directory, main logic in `whisper-stream`
- **Debugging**: Check error logs at `/tmp/whisper-stream-error.log`

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
- **Error Handling**: 3-attempt retry logic for API calls (transcription.sh:convert_audio_to_text)
- **Silence Detection**: Uses SoX stats to check maximum amplitude against threshold (audio.sh:is_silent)
- **Device Selection**: Interactive PulseAudio device selection with fallback to system default
- **File Validation**: Checks audio file existence, size (<25MB), and format before processing
- **Signal Handling**: Proper cleanup on SIGINT/SIGTSTP with background process termination
- **Auto-Installation**: Gum UI framework automatically downloads if not present
- **Configuration Persistence**: Device selections and preferences saved to ~/.config/whisper-stream/config

## Key Functions by Module

### Configuration (config.sh)
- `load_config()` - Loads settings from config file with flexible parsing
- `create_default_config_if_not_exists()` - Creates default config file
- `write_device_to_config()` - Persists device selections

### Audio Processing (audio.sh)
- `select_input_device()` - Interactive device selection with gum
- `list_input_devices()` - Cross-platform audio device enumeration
- `is_silent()` - Audio silence detection using SoX stats
- `check_audio_file()` - Validates audio files (format, size, existence)

### Transcription (transcription.sh)
- `convert_audio_to_text()` - Main transcription function with retry logic
- `correct_and_format_text()` - Autocorrect using dictionary file

### UI Framework (gum_wrapper.sh)
- `gum_init()` - Auto-downloads and installs gum if not found
- `gum_*()` - Styled wrapper functions for all gum components
- `trap_error()` / `trap_exit()` - Comprehensive error handling

## File Structure

- `whisper-stream` - Main executable bash script (orchestrator)
- `lib/` - Modular library directory
  - `logging.sh` - Error logging and rotation
  - `gum_wrapper.sh` - Interactive UI framework  
  - `config.sh` - Configuration management
  - `arguments.sh` - Command-line argument parsing
  - `audio.sh` - Audio processing and device management
  - `transcription.sh` - API integration and text processing
  - `ui.sh` - User interface display
- `README.md` - User documentation with installation and usage examples
- `LICENSE` - MIT license
- `dictionary.md` - Autocorrect dictionary file
- `CLAUDE.md` - This file

## Development Notes

- **Module Development**: Edit modules in `lib/` directory for specific functionality
- **No Build Process**: Single bash script with sourced modules
- **No Test Framework**: Manual testing recommended
- **Executable Requirements**: Script must be executable (`chmod +x`)
- **Error Logging**: Automatically rotates when > 1MB
- **Temporary Files**: Automatically cleaned up on exit
- **Configuration**: Persists device selections between runs
- **Global State**: Modules share global variables for configuration
- **Extensibility**: New features can be added by extending existing modules or creating new ones