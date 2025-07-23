#!/bin/bash

# whisper-stream installer script
# This script installs whisper-stream and its dependencies on Linux systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="/usr/bin"
SHARE_DIR="/usr/share/whisper-stream"
DOC_DIR="/usr/share/doc/whisper-stream"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to detect package manager
detect_package_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Function to install dependencies
install_dependencies() {
    local pm=$(detect_package_manager)
    
    print_info "Detected package manager: $pm"
    print_info "Installing dependencies..."
    
    case $pm in
        "pacman")
            pacman -Sy --noconfirm curl jq sox wl-clipboard
            ;;
        "apt")
            apt update
            apt install -y curl jq sox wl-clipboard
            ;;
        "dnf")
            dnf install -y curl jq sox wl-clipboard
            ;;
        "yum")
            yum install -y curl jq sox wl-clipboard
            ;;
        "zypper")
            zypper install -y curl jq sox wl-clipboard
            ;;
        "unknown")
            print_warning "Unknown package manager. Please install the following packages manually:"
            print_warning "  - curl"
            print_warning "  - jq"
            print_warning "  - sox"
            print_warning "  - wl-clipboard (Wayland) or xclip/xsel (X11)"
            read -p "Continue installation? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
            ;;
    esac
}

# Function to check dependencies
check_dependencies() {
    local missing=()
    
    command -v curl &> /dev/null || missing+=("curl")
    command -v jq &> /dev/null || missing+=("jq")
    command -v sox &> /dev/null || missing+=("sox")
    # Check for clipboard tools (prefer Wayland, fallback to X11)
    if ! (command -v wl-copy &> /dev/null || command -v xclip &> /dev/null || command -v xsel &> /dev/null); then
        missing+=("clipboard-tool")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Function to install whisper-stream
install_whisper_stream() {
    print_info "Installing whisper-stream..."
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$SHARE_DIR"
    mkdir -p "$DOC_DIR"
    
    # Copy main executable
    cp whisper-stream "$INSTALL_DIR/whisper-stream"
    chmod +x "$INSTALL_DIR/whisper-stream"
    
    # Copy library modules
    cp -r lib "$SHARE_DIR/"
    
    # Copy documentation
    cp README.md "$DOC_DIR/" 2>/dev/null || true
    cp docs/CLAUDE.md "$DOC_DIR/" 2>/dev/null || true
    cp docs/dictionary.md "$SHARE_DIR/" 2>/dev/null || true
    cp LICENSE "$DOC_DIR/" 2>/dev/null || true
    
    print_success "whisper-stream installed successfully!"
}

# Function to create uninstall script
create_uninstall_script() {
    cat > "$INSTALL_DIR/whisper-stream-uninstall" << 'EOF'
#!/bin/bash

# whisper-stream uninstaller script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_info "Removing whisper-stream..."

# Remove files
rm -f /usr/bin/whisper-stream
rm -f /usr/bin/whisper-stream-uninstall
rm -rf /usr/share/whisper-stream
rm -rf /usr/share/doc/whisper-stream

print_success "whisper-stream has been uninstalled successfully!"
print_info "User configuration files in ~/.config/whisper-stream/ are preserved"
EOF

    chmod +x "$INSTALL_DIR/whisper-stream-uninstall"
    print_info "Uninstall script created at $INSTALL_DIR/whisper-stream-uninstall"
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    if [[ -x "$INSTALL_DIR/whisper-stream" ]]; then
        print_success "whisper-stream executable found"
    else
        print_error "whisper-stream executable not found"
        return 1
    fi
    
    if [[ -d "$SHARE_DIR/lib" ]]; then
        print_success "Library modules found"
    else
        print_error "Library modules not found"
        return 1
    fi
    
    # # Test if whisper-stream can display help
    # if "$INSTALL_DIR/whisper-stream" --help &> /dev/null; then
    #     print_success "whisper-stream runs successfully"
    # else
    #     print_warning "whisper-stream may have issues running"
    # fi
}

# Main installation function
main() {
    print_info "Starting whisper-stream installation..."
    
    # Check if running as root
    check_root
    
    # Check if we're in the correct directory
    if [[ ! -f "whisper-stream" ]] || [[ ! -d "lib" ]]; then
        print_error "Installation files not found. Run this script from the whisper-stream directory."
        exit 1
    fi
    
    # Install dependencies
    install_dependencies
    
    # Verify dependencies are installed
    if ! check_dependencies; then
        print_error "Dependencies not properly installed. Please install them manually."
        exit 1
    fi
    
    # Install whisper-stream
    install_whisper_stream
    
    # Create uninstall script
    create_uninstall_script
    
    # Verify installation
    verify_installation
    
    print_success "Installation complete!"
    print_info "You can now run 'whisper-stream' from anywhere in your terminal"
    print_info "Documentation is available in $DOC_DIR"
    print_info "To uninstall, run: sudo whisper-stream-uninstall"
    print_info ""
    print_info "Don't forget to set your GROQ_API_KEY environment variable:"
    print_info "  export GROQ_API_KEY='your-api-key-here'"
}

# Run main function
main "$@"