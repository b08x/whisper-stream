# Whisper Stream Speech-to-Text Transcriber

![whisper-stream](https://github.com/yohasebe/whisper-stream/assets/18207/7b419ba0-a621-40ac-82c6-9c498e038e0d)

This is a **modular bash script application** that utilizes the [Groq Whisper API](https://groq.com/) to **transcribe continuous voice input into text**. It uses SoX for audio recording and includes a built-in feature that detects silence between speech segments.

The application was re-designed using a modular architecture featuring seven specialized modules that handle different aspects of the transcription process - from audio processing and UI interaction to configuration management and API integration.

The script is designed to convert voice audio into text each time the system identifies a **specified duration of silence**. This enables the Whisper API to function as if it were capable of real-time speech-to-text conversion. It is also possible to specify the audio file to be converted by Whisper.

After transcription, the text is automatically copied to your system's **clipboard** for immediate use. It can also be saved in a specified directory as a **text file** or automatically to daily notebook files.

## Features

- **Modular Architecture**: Clean separation of concerns across 7 specialized modules
- **Self-Installing UI**: Automatically downloads and installs the `gum` interactive framework
- **Config file support**: Automatically loads settings from `~/.config/whisper-stream/config`
- **Device selection**: Interactive audio input device selection with PulseAudio support
- **Auto-destination**: Automatically creates daily transcription files in `$NOTEBOOK_ROOT/YYYY-Month/YYYY-MM-DD.md` format
- **Cross-platform**: Support for both Linux and macOS with intelligent device detection
- **Error resilience**: Comprehensive error handling with retry logic and automatic cleanup
- **Configuration persistence**: Saves device selections and preferences between sessions
- **First-time setup**: Interactive setup wizard for new users
- **Multiple installation methods**: AUR package, automated script, or manual installation
- **Packaging support**: Ready-to-use PKGBUILD for Arch Linux distribution

## Installation

### Arch Linux (AUR)

For Arch Linux users, the package is available in the AUR:

```bash
# Using yay
yay -S whisper-stream

# Using makepkg
git clone https://aur.archlinux.org/whisper-stream.git
cd whisper-stream
makepkg -si
```

### Automated Installation Script

The easiest way to install whisper-stream is using the automated installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/b08x/whisper-stream/main/scripts/install.sh | bash
```

This script will:
- Check for required dependencies and install them if needed
- Install whisper-stream to `/usr/local/bin`
- Set up configuration directories
- Create example configuration files

### Manual Installation

1. Install the following dependencies:

- `curl`
- `jq`
- `sox`
- `wl-clipboard` (for Wayland), `xclip` or `xsel` (for X11), or `pbcopy` (for macOS)
- `pactl` or `arecord` (for Linux audio device detection)
- `SwitchAudioSource` (optional for macOS)

**Note**: The `gum` interactive UI framework will be automatically downloaded and installed if not found.

On a Debian-based Linux distribution, you can install these dependencies with:

```bash
sudo apt-get install curl jq sox wl-clipboard alsa-utils
```

2. Identify a directory in your system's PATH variable where you want to place the script. You can check the directories in your PATH variable by running the following command:

```bash
> echo $PATH
```

3. Clone or download the repository and move the entire `whisper-stream` directory to your chosen location:

```bash
> git clone <repository-url> whisper-stream
> cd whisper-stream
> chmod +x whisper-stream
```

4. Create a symlink to the script in your PATH directory:

```bash
> ln -s $(pwd)/whisper-stream /usr/local/bin/whisper-stream
```

**Important**: The script requires the `lib/` directory to be in the same location as the main executable, as it sources the modular components from there.

### Development Installation

For development work, you can also install from source:

```bash
git clone https://github.com/b08x/whisper-stream.git
cd whisper-stream
chmod +x whisper-stream
./whisper-stream  # Run directly from the source directory
```

### Packaging

The repository includes packaging files for distribution:

- **AUR Package**: `packaging/PKGBUILD` - Arch Linux package build script
- **Installation Script**: `scripts/install.sh` - Automated installation for Linux systems
- **Setup Scripts**: `scripts/first_time_setup.sh` - First-time user setup wizard

## Usage

You can start the script with the following command:

```bash
> whisper-stream [options]
```

The available options are:

- `-v, --volume <value>`: Set the minimum volume threshold (default: 1%)
- `-s, --silence <value>`: Set the minimum silence length (default: 1.5)
- `-o, --oneshot`: Enable one-shot mode
- `-d, --duration <value>`: Set the recording duration in seconds (default: 0, continuous)
- `-t, --token <value>`: Set the Groq API token
- `-nr, --notebooks-root <value>`: Set the Notebooks root directory
- `-n, --notebook <value>`: Set the Notebook to store dictations
- `-i, --input-device <value>`: Set the input device for recording
- `-g, --granularities <value>`: Set the timestamp granularities (segment or word)
- `-r, --prompt <value>`: Set the prompt for the API call
- `-l, --language <value>`: Set the input language in ISO-639-1 format
- `-f, --file <value>`: Set the audio file to be transcribed
- `-tr, --translate`: Translate the transcribed text to English
- `-p2, --pipe-to <cmd>`: Pipe the transcribed text to the specified command (e.g., 'wc -w')
- `-df, --dest-file <file>`: Set the destination file for transcriptions
- `-q, --quiet`: Suppress the banner and settings
- `-V, --version`: Show the version number
- `-h, --help`: Display the help message

## Examples

Here are some usage examples with a brief comment on each of them:

`> whisper-stream`

This will start the script with the default settings, recording audio continuously and transcribing it into text using the default volume threshold and silence length. The script will:

- Load settings from `~/.config/whisper-stream/config` if no arguments provided
- Prompt for audio input device selection if none configured
- Auto-generate daily transcription file in `$NOTEBOOK_ROOT/YYYY-Month/YYYY-MM-DD.md` format
- Use the `GROQ_API_KEY` environment variable for API authentication

`> whisper-stream -l ja`

This will start the script with the input language specified as Japanese; see the [Wikipedia](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) page for ISO-639-1 language codes.

`> whisper-stream -tr`

It transcribes the spoken audio in whatever language and presents the text translated into English. Currently, the target language for translation is limited to English.

`> whisper-stream -v 2% -s 2 -o -d 60 -t your_groq_api_token`

This example sets the minimum volume threshold to 2%, the minimum silence length to 2 seconds, enables one-shot mode, sets the recording duration to 60 seconds, and specifies the Groq API token.

`> whisper-stream -i alsa_input.usb-Nuance_PowerMicII-NS-00.mono-fallback`

This specifies a specific PulseAudio input device for recording. The device name can be found using the interactive device selection or by running `pactl list short sources`.

`> whisper-stream -f ~/Desktop/interview.mp3 -p ~/Desktop/transcripts -l en`

This will transcribe the audio file located at `~/Desktop/interview.mp3`. The input language is specified as English. The output directory is set to `~Desktop/transcripts` to create a transcription text file.

`> whisper-stream -p2 'wc -w'`

This will start the script with the default settings for recording audio and transcribing it. After transcription, the transcribed text will be piped to the `wc -w` command, which counts the number of words in the text. The result, indicating the total word count, will be printed below the original transcribed output.

`> whisper-stream -v segment -p ~/Desktop`

The `-g` option allows you to specify the mode for timestamp granularities. The available modes are segment or word, and specifying either will display detailed transcript data in JSON format. When used in conjunction with the `-p` option to specify a directory, the results will be saved as a JSON file. For more information, see the [`timestamp_granularities[]`](https://platform.openai.com/docs/api-reference/audio/createTranscription#audio-createtranscription-timestamp_granularities) section in OpenAI Whisper API reference.

## Restrictions

Restrictions such as the languages that can be converted by this program, the types of audio files that can be input, and the size of data that can be converted at one time depend on what the Groq Whisper API specifies. Please refer to [Groq Documentation](https://console.groq.com/docs/speech-text) for details.

## Configuration

The script uses a configuration file at `~/.config/whisper-stream/config` to store default settings:

```bash
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
```

Settings in this file are automatically loaded when running `whisper-stream` without arguments. Command-line arguments override config file settings.

## Architecture

The application features a modular architecture with the following components:

### Core Modules (`lib/` directory)

- **logging.sh**: Error logging and automatic log rotation
- **gum_wrapper.sh**: Interactive UI framework with auto-installation
- **config.sh**: Configuration management with persistent storage
- **arguments.sh**: Command-line argument parsing and validation
- **audio.sh**: Cross-platform audio processing and device management
- **transcription.sh**: API integration with retry logic and text processing
- **ui.sh**: User interface display and formatted output

### Supporting Directories

- **docs/**: Documentation files including CLAUDE.md development guide and dictionary.md
- **scripts/**: Installation and setup scripts for various environments
- **packaging/**: Distribution packaging files (PKGBUILD, install scripts)
- **dev/**: Development and build configuration files

### Key Design Patterns

- **Separation of Concerns**: Each module has a single, well-defined responsibility
- **Cross-Platform Compatibility**: OS-specific implementations for macOS and Linux
- **Progressive Enhancement**: Graceful handling of optional dependencies
- **Configuration-First**: Config file loaded before argument parsing
- **Error Resilience**: Comprehensive error handling with retries and cleanup

The main `whisper-stream` script acts as an orchestrator, sourcing all modules and coordinating the transcription workflow.

## Authors

Yoichiro Hasebe [<yohasebe@gmail.com>]
Robert Pannick [<rwpannick@gmail.com>]

## License

This software is distributed under the [MIT License](http://www.opensource.org/licenses/mit-license.php).
