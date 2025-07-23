# RPM spec file for whisper-stream
# Fedora 42 package specification

Name:           whisper-stream
Version:        2.1.1
Release:        2%{?dist}
Summary:        Continuous speech-to-text transcription using Groq API with interactive UI

License:        MIT
URL:            https://github.com/b08x/whisper-stream
Source0:        https://github.com/b08x/whisper-stream/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildArch:      noarch

# Core dependencies
Requires:       bash >= 4.0
Requires:       curl
Requires:       jq
Requires:       sox
# Optional dependencies (Recommends in Fedora)
Recommends:     wl-clipboard
Recommends:     xclip
Recommends:     xsel
Recommends:     pulseaudio-utils
Recommends:     alsa-utils
Recommends:     gum

# Build dependencies
BuildRequires:  sed
BuildRequires:  coreutils

# Package provides and conflicts
Provides:       %{name} = %{version}-%{release}

%description
whisper-stream is a modular bash script application that utilizes the Groq
Whisper API to transcribe continuous voice input into text. It uses SoX for
audio recording and includes a built-in feature that detects silence between
speech segments.

Key features:
- Modular architecture with 7 specialized modules
- Self-installing UI with automatic gum framework installation
- Config file support with persistent settings
- Interactive audio input device selection
- Cross-platform support for Linux and macOS
- Auto-destination for daily transcription files
- Error resilience with comprehensive error handling
- First-time setup wizard for new users

%prep
%autosetup -n %{name}-%{version}

# Update shebangs to use env for better portability
sed -i '1s|#!/bin/bash|#!/usr/bin/env bash|' whisper-stream

# Update shebangs for lib files
for lib_file in lib/*.sh; do
    if [[ -f "$lib_file" ]]; then
        sed -i '1s|#!/bin/bash|#!/usr/bin/env bash|' "$lib_file"
    fi
done

# Update shebangs for scripts files
for script_file in scripts/*.sh; do
    if [[ -f "$script_file" ]]; then
        sed -i '1s|#!/bin/bash|#!/usr/bin/env bash|' "$script_file"
    fi
done

%build
# No compilation needed - this is a shell script package

%install
# Create directory structure following FHS
install -d %{buildroot}%{_bindir}
install -d %{buildroot}%{_datadir}/%{name}
install -d %{buildroot}%{_datadir}/%{name}/lib
install -d %{buildroot}%{_datadir}/%{name}/scripts
install -d %{buildroot}%{_docdir}/%{name}
install -d %{buildroot}%{_sysconfdir}/%{name}

# Install main executable
install -m 755 whisper-stream %{buildroot}%{_bindir}/whisper-stream

# Install library modules
for lib_file in lib/*.sh; do
    if [[ -f "$lib_file" ]]; then
        install -m 644 "$lib_file" %{buildroot}%{_datadir}/%{name}/lib/
    fi
done

# Install scripts
for script_file in scripts/*.sh; do
    if [[ -f "$script_file" ]]; then
        install -m 755 "$script_file" %{buildroot}%{_datadir}/%{name}/scripts/
    fi
done

# Install documentation
install -m 644 README.md %{buildroot}%{_docdir}/%{name}/
install -m 644 docs/CLAUDE.md %{buildroot}%{_docdir}/%{name}/
install -m 644 docs/dictionary.md %{buildroot}%{_datadir}/%{name}/

# Create example configuration file
cat > %{buildroot}%{_sysconfdir}/%{name}/config.example << 'EOF'
# whisper-stream configuration file
# Copy this to ~/.config/whisper-stream/config and customize

# Groq API settings
#GROQ_API_KEY=your_api_key_here
MODEL=whisper-large-v3-turbo

# Audio settings
MIN_VOLUME=1%
SILENCE_LENGTH=1.5
ONESHOT=false
DURATION=0

# Output settings
OUTPUT_DIR=
DEST_FILE=
QUIET_MODE=false

# Transcription settings
PROMPT=
LANGUAGE=
TRANSLATE=false
GRANULARITIES=none

# Notebook settings
NOTEBOOK_ROOT=${HOME}/Notebooks
NOTEBOOK=

# Device settings (leave empty to prompt)
SELECTED_INPUT_DEVICE=

# Advanced settings
AUDIO_FILE=
PIPE_TO_CMD=
AUTOCORRECT=false
DICTIONARY=
EOF

%files
%license LICENSE
%doc %{_docdir}/%{name}/README.md
%doc %{_docdir}/%{name}/CLAUDE.md
%{_bindir}/whisper-stream
%{_datadir}/%{name}/
%config(noreplace) %{_sysconfdir}/%{name}/config.example

%post
# Post-installation script
echo "whisper-stream installation complete"
echo
echo "Configuration:"
echo "  - Example config: %{_sysconfdir}/%{name}/config.example"
echo "  - User config: ~/.config/%{name}/config"
echo
echo "Getting started:"
echo "  1. Set your Groq API key: export GROQ_API_KEY='your-key-here'"
echo "  2. Run: whisper-stream"
echo "  3. Follow the interactive prompts"
echo
echo "Documentation:"
echo "  - README: %{_docdir}/%{name}/README.md"
echo "  - Development guide: %{_docdir}/%{name}/CLAUDE.md"

%postun
# Post-uninstall cleanup
if [ $1 -eq 0 ]; then
    # Complete removal
    echo "whisper-stream removed"
    echo
    
    # Clean up temporary files
    rm -f /tmp/whisper-stream-error.log 2>/dev/null || true
    rm -f /tmp/.whisper-stream-* 2>/dev/null || true
    rm -f /tmp/whisper-stream-*.wav 2>/dev/null || true
    
    # Clean up any auto-installed gum binary if it was installed by whisper-stream
    if [[ -f "/usr/local/bin/gum" ]] && [[ -f "/tmp/.whisper-stream-gum-installed" ]]; then
        echo "Removing auto-installed gum binary..."
        rm -f /usr/local/bin/gum 2>/dev/null || true
        rm -f /tmp/.whisper-stream-gum-installed 2>/dev/null || true
    fi
    
    echo "User configuration preserved in: ~/.config/%{name}/"
    echo "To completely remove all data, run: rm -rf ~/.config/%{name}"
fi

%preun
# Pre-uninstall script
if [ $1 -eq 0 ]; then
    # Stop any running whisper-stream processes
    if pgrep -f "whisper-stream" >/dev/null 2>&1; then
        echo "Stopping running whisper-stream processes..."
        pkill -f "whisper-stream" || true
    fi
    
    # Clean up temporary files
    rm -f /tmp/whisper-stream-*.log 2>/dev/null || true
    rm -rf /tmp/.tmp.gum_* 2>/dev/null || true
    rm -f /tmp/whisper-stream-*.wav 2>/dev/null || true
    rm -f /tmp/test_audio.* 2>/dev/null || true
    
    # Clean up any cached downloads
    rm -rf /tmp/whisper-stream-cache 2>/dev/null || true
fi

%changelog
* Tue Jul 22 2025 Package Maintainer <maintainer@example.com> - 2.0.0-2
- Updated spec file for Fedora 42
- Added comprehensive post-install and cleanup scripts
- Improved dependency handling with Recommends
- Added proper file permissions and directory structure

* Mon Jul 14 2025 whisper-stream developers - 2.0.0-1
- Add notebook option to specify a notebook directory
- Add option to set notebooks root directory
- Added destination file option
- Enhanced destination file selection in whisper-stream
- Enhance audio input selection and destination file handling
- Add config file support and improved device selection
- Add error logging to /tmp/whisper-stream-error.log
- Add interactive directory and file selection prompts
- Simplify destination file selection in whisper-stream
- Move temporary files to /tmp directory
- Update version to 2.0.0 for release branch
- Update dictation destination and remove notebook selection
- Modularize script and enhance UI with gum wrapper
- Reorganize codebase with logical directory structure
- Update documentation to reflect modular architecture