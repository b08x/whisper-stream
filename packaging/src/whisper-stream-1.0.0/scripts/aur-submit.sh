#!/bin/bash

# AUR submission helper script for whisper-stream

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if required tools are available
check_tools() {
    local tools=("git" "makepkg" "updpkgsums")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing[*]}"
        print_info "Install them with: sudo pacman -S ${missing[*]}"
        exit 1
    fi
}

# Update checksums in PKGBUILD
update_checksums() {
    print_info "Updating checksums in PKGBUILD..."
    updpkgsums
    print_success "Checksums updated"
}

# Test build the package
test_build() {
    print_info "Testing package build..."
    
    if makepkg -sf --noconfirm; then
        print_success "Package built successfully"
        
        # Clean up build files
        rm -f *.pkg.tar.xz *.pkg.tar.zst
        rm -rf src/ pkg/
        
        return 0
    else
        print_error "Package build failed"
        return 1
    fi
}

# Validate PKGBUILD
validate_pkgbuild() {
    print_info "Validating PKGBUILD..."
    
    # Check if namcap is available
    if command -v namcap &> /dev/null; then
        namcap PKGBUILD
    else
        print_warning "namcap not available, skipping advanced validation"
    fi
    
    # Basic validation
    if ! source PKGBUILD; then
        print_error "PKGBUILD has syntax errors"
        return 1
    fi
    
    # Check required fields
    [[ -n "$pkgname" ]] || { print_error "pkgname is required"; return 1; }
    [[ -n "$pkgver" ]] || { print_error "pkgver is required"; return 1; }
    [[ -n "$pkgdesc" ]] || { print_error "pkgdesc is required"; return 1; }
    [[ -n "${arch[*]}" ]] || { print_error "arch is required"; return 1; }
    [[ -n "$license" ]] || { print_error "license is required"; return 1; }
    
    print_success "PKGBUILD validation passed"
}

# Main function
main() {
    print_info "AUR submission helper for whisper-stream"
    print_info "========================================="
    
    # Check if we're in the right directory
    if [[ ! -f "PKGBUILD" ]]; then
        print_error "PKGBUILD not found. Run this script from the project directory."
        exit 1
    fi
    
    # Check required tools
    check_tools
    
    # Validate PKGBUILD
    validate_pkgbuild
    
    # Update checksums
    update_checksums
    
    # Test build
    test_build
    
    print_success "All checks passed!"
    print_info ""
    print_info "To submit to AUR:"
    print_info "1. Clone the AUR repository: git clone ssh://aur@aur.archlinux.org/whisper-stream.git"
    print_info "2. Copy PKGBUILD to the cloned directory"
    print_info "3. Add any additional files (.install, .patch, etc.)"
    print_info "4. Generate .SRCINFO: makepkg --printsrcinfo > .SRCINFO"
    print_info "5. Commit and push: git add -A && git commit -m 'Initial import' && git push"
}

main "$@"