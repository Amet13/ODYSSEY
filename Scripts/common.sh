#!/bin/bash

# ODYSSEY Common Script Functions
# Shared utilities and functions used across all ODYSSEY scripts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'

NC='\033[0m' # No Color

# Function to print colored output (unified logging)
print_status() {
    local status=$1
    local message=$2
    case $status in
        "info") echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "error") echo -e "${RED}❌ $message${NC}" ;;
        "step") echo -e "${PURPLE}🔨 $message${NC}" ;;
    esac
}

# Alias functions for consistency
log_info() { print_status "info" "$1"; }
log_success() { print_status "success" "$1"; }
log_warning() { print_status "warning" "$1"; }
log_error() { print_status "error" "$1"; }

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to measure execution time
measure_time() {
    local start_time=$SECONDS
    "$@"
    local end_time=$SECONDS
    local duration=$((end_time - start_time))
    print_status "success" "Completed in ${duration}s"
}

# Function to check prerequisites
check_prerequisites() {
    local missing_tools=()

    # Check for required tools
    local required_tools=("xcodebuild" "xcodegen" "swift")
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_status "error" "Missing required tools: ${missing_tools[*]}"
        print_status "info" "Install missing tools with: brew install ${missing_tools[*]}"
        exit 1
    fi

    print_status "success" "All prerequisites satisfied"
}

# Function to check optional tools
check_optional_tools() {
    local optional_tools=("swiftlint" "swiftformat" "shellcheck" "yamllint" "markdownlint" "actionlint" "create-dmg")
    local missing_tools=()

    for tool in "${optional_tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_status "warning" "Optional tools missing: ${missing_tools[*]}"
        print_status "info" "Install with: brew install ${missing_tools[*]}"
    else
        print_status "success" "All optional tools available"
    fi
}

# Function to validate we're in the ODYSSEY directory
validate_project_root() {
    if [ ! -f "Package.swift" ] || [ ! -d "Sources" ]; then
        print_status "error" "This script must be run from the ODYSSEY project root"
        exit 1
    fi
}

# Function to clean previous builds
clean_builds() {
    print_status "step" "Cleaning previous builds..."

    # Clean Xcode build
    if [ -d "Config/ODYSSEY.xcodeproj" ]; then
        xcodebuild clean \
            -project Config/ODYSSEY.xcodeproj \
            -scheme ODYSSEY \
            -configuration Release \
            -quiet 2>/dev/null || true
    fi

    # Clean Swift build
    swift package clean 2>/dev/null || true

    # Remove previous DMG files
    rm -f ODYSSEY-*.dmg 2>/dev/null || true

    print_status "success" "Build cleaned"
}

# Function to generate Xcode project
generate_xcode_project() {
    print_status "step" "Generating Xcode project..."
    xcodegen --spec Config/project.yml
    print_status "success" "Xcode project generated"
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_status "error" "Invalid version format. Use MAJOR.MINOR.PATCH (e.g., 3.2.0)"
        exit 1
    fi
}

# Function to get current version from Info.plist
get_current_version() {
    # Try to get version from Info.plist first, then fallback to project.yml
    local version
    version=$(grep -A1 "CFBundleShortVersionString" Sources/App/Info.plist | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ -n "$version" ] && [ "$version" != "CFBundleShortVersionString" ]; then
        echo "$version"
    else
        # Fallback to project.yml if Info.plist doesn't have a valid version
        grep "MARKETING_VERSION:" Config/project.yml | sed 's/.*MARKETING_VERSION: "\(.*\)"/\1/' | head -1
    fi
}

# Function to show usage
show_usage() {
    local script_name
    script_name=$(basename "$0")
    echo "Usage: $script_name [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help        Show this help message"
    echo "  --dry-run     Show what would be done without making changes"
    echo ""
    echo "For more information, see Documentation/SCRIPTS.md"
}