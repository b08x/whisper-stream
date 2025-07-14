#!/bin/bash

# Test script for first-time setup functionality
# Disable strict error handling for testing environment
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Test environment setup
setup_test_env() {
    print_test "Setting up test environment..."
    
    # Create a temporary test directory
    export TEST_HOME="/tmp/whisper-stream-test"
    mkdir -p "$TEST_HOME"
    
    # Override HOME for testing
    export HOME="$TEST_HOME"
    export CONFIG_DIR="$TEST_HOME/.config/whisper-stream"
    
    print_pass "Test environment created at: $TEST_HOME"
}

# Clean up test environment
cleanup_test_env() {
    print_test "Cleaning up test environment..."
    if [[ -d "$TEST_HOME" ]]; then
        rm -rf "$TEST_HOME"
        print_pass "Test environment cleaned up"
    fi
}

# Test first-time setup detection
test_first_time_detection() {
    print_test "Testing first-time setup detection..."
    
    # Source the setup module
    source "lib/gum_wrapper.sh"
    source "scripts/first_time_setup.sh"
    
    # Should detect as first run
    if is_first_run; then
        print_pass "Correctly detected first run"
        return 0
    else
        print_fail "Failed to detect first run"
        return 1
    fi
}

# Test configuration directory creation
test_config_dir_creation() {
    print_test "Testing configuration directory creation..."
    
    create_config_directory
    
    if [[ -d "$CONFIG_DIR" ]]; then
        print_pass "Configuration directory created successfully"
        return 0
    else
        print_fail "Failed to create configuration directory"
        return 1
    fi
}

# Test API key validation
test_api_key_validation() {
    print_test "Testing API key validation..."
    
    # Test valid-looking key
    if validate_api_key "gsk_1234567890abcdef1234567890abcdef"; then
        print_pass "Valid API key accepted"
    else
        print_fail "Valid API key rejected"
        return 1
    fi
    
    # Test invalid key (too short)
    if ! validate_api_key "short"; then
        print_pass "Short API key correctly rejected"
    else
        print_fail "Short API key incorrectly accepted"
        return 1
    fi
    
    return 0
}

# Test configuration file creation
test_config_file_creation() {
    print_test "Testing configuration file creation..."
    
    # Create a test config file
    local config_file="$CONFIG_DIR/config"
    echo "# Test configuration" > "$config_file"
    echo "GROQ_API_KEY=test_key" >> "$config_file"
    echo "MODEL=whisper-large-v3-turbo" >> "$config_file"
    
    if [[ -f "$config_file" ]]; then
        print_pass "Configuration file created successfully"
        
        # Verify contents
        if grep -q "GROQ_API_KEY=test_key" "$config_file"; then
            print_pass "Configuration file contains expected content"
            return 0
        else
            print_fail "Configuration file missing expected content"
            return 1
        fi
    else
        print_fail "Configuration file not created"
        return 1
    fi
}

# Test completion flag
test_completion_flag() {
    print_test "Testing completion flag functionality..."
    
    # Mark as complete
    mark_first_run_complete
    
    # Should no longer detect as first run
    if ! is_first_run; then
        print_pass "Completion flag working correctly"
        return 0
    else
        print_fail "Completion flag not working"
        return 1
    fi
}

# Test configuration reset
test_config_reset() {
    print_test "Testing configuration reset..."
    
    # Reset configuration
    reset_configuration
    
    # Should detect as first run again
    if is_first_run; then
        print_pass "Configuration reset successful"
        return 0
    else
        print_fail "Configuration reset failed"
        return 1
    fi
}

# Main test runner
main() {
    print_info "Starting whisper-stream first-time setup tests..."
    echo
    
    local tests_passed=0
    local tests_total=0
    
    # Setup test environment
    setup_test_env
    
    # Run tests
    tests=(
        "test_first_time_detection"
        "test_config_dir_creation"
        "test_api_key_validation"
        "test_config_file_creation"
        "test_completion_flag"
        "test_config_reset"
    )
    
    for test in "${tests[@]}"; do
        tests_total=$((tests_total + 1))
        if $test; then
            tests_passed=$((tests_passed + 1))
        fi
        echo
    done
    
    # Cleanup
    cleanup_test_env
    
    # Results
    echo
    print_info "Test Results: $tests_passed/$tests_total passed"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        print_pass "All tests passed!"
        exit 0
    else
        print_fail "Some tests failed!"
        exit 1
    fi
}

# Run tests
main "$@"