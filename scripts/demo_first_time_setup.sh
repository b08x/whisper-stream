#!/bin/bash

# Demo script for first-time setup functionality
# This shows how the first-time setup works without actually running it

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_demo() {
    echo -e "${BLUE}[DEMO]${NC} $1"
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

main() {
    print_demo "whisper-stream First-Time Setup Demo"
    echo
    
    print_info "This demo shows the first-time setup process for whisper-stream."
    echo
    
    print_step "1. Welcome Screen"
    echo "   - Shows welcome message with attractive styling"
    echo "   - Explains the setup process"
    echo "   - Asks for confirmation to proceed"
    echo
    
    print_step "2. API Key Configuration"
    echo "   - Checks for existing GROQ_API_KEY environment variable"
    echo "   - Provides link to get API key: https://console.groq.com/keys"
    echo "   - Validates API key format (should start with 'gsk_')"
    echo "   - Tests API key by making a simple request"
    echo "   - Saves validated key to configuration file"
    echo
    
    print_step "3. Audio Configuration"
    echo "   - Device selection: Auto-detect or select specific device"
    echo "   - Audio sensitivity: Default, Low, High, or Custom"
    echo "   - Configures MIN_VOLUME and SILENCE_LENGTH parameters"
    echo
    
    print_step "4. Workspace Configuration"
    echo "   - Notebook directory: Default ~/Notebooks, select existing, or create new"
    echo "   - Creates directory if it doesn't exist"
    echo "   - Saves path to configuration"
    echo
    
    print_step "5. Transcription Preferences"
    echo "   - Model selection: whisper-large-v3-turbo (fast) or whisper-large-v3 (accurate)"
    echo "   - Language: Auto-detect, English only, or specific language code"
    echo "   - Auto-correction: Enable/disable dictionary-based corrections"
    echo
    
    print_step "6. Additional Features"
    echo "   - File behavior: Auto-generate daily files, prompt, or single file"
    echo "   - Quiet mode: Reduce output messages"
    echo "   - Auto-clipboard: Copy transcriptions to clipboard"
    echo
    
    print_step "7. Configuration Summary"
    echo "   - Shows all configured settings"
    echo "   - Displays configuration file location"
    echo "   - Shows sample configuration content"
    echo
    
    print_step "8. Completion"
    echo "   - Marks first-time setup as complete"
    echo "   - Offers to start whisper-stream immediately"
    echo "   - Provides usage instructions"
    echo
    
    print_info "Configuration Features:"
    echo "   - Saves to: ~/.config/whisper-stream/config"
    echo "   - Validates all inputs"
    echo "   - Tests API connectivity"
    echo "   - Creates necessary directories"
    echo "   - Provides helpful defaults"
    echo "   - Can be reset with: whisper-stream --reset-config"
    echo
    
    print_info "Integration with Main Script:"
    echo "   - Automatically detects first run"
    echo "   - Runs setup before main application"
    echo "   - Loads configuration after setup"
    echo "   - Provides seamless user experience"
    echo
    
    print_demo "To see the actual setup, run: whisper-stream --reset-config"
    echo
}

main "$@"