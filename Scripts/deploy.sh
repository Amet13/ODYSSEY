#!/bin/bash

# ODYSSEY Deployment Script
# Automates the release and deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the ODYSSEY directory
if [ ! -f "Package.swift" ] || [ ! -d "Sources" ]; then
    log_error "This script must be run from the ODYSSEY project root"
    exit 1
fi

# Configuration
VERSION=$(grep -o 'version: "[^"]*"' Config/project.yml | cut -d'"' -f2)
BUILD_NUMBER=$(date +%Y%m%d%H%M)
RELEASE_NAME="ODYSSEY-v${VERSION}-${BUILD_NUMBER}"

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check for required tools
    local missing_tools=()
    
    if ! command -v xcodebuild &> /dev/null; then
        missing_tools+=("xcodebuild")
    fi
    
    if ! command -v xcodegen &> /dev/null; then
        missing_tools+=("xcodegen")
    fi
    
    if ! command -v swift &> /dev/null; then
        missing_tools+=("swift")
    fi
    
    if ! command -v create-dmg &> /dev/null; then
        log_warning "create-dmg not found, will install if needed"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Function to clean previous builds
clean_builds() {
    log_info "Cleaning previous builds..."
    
    # Clean Xcode build
    xcodebuild clean \
        -project Config/ODYSSEY.xcodeproj \
        -scheme ODYSSEY \
        -configuration Release \
        -quiet
    
    # Clean Swift build
    swift package clean
    
    # Remove previous DMG files
    rm -f ODYSSEY-*.dmg
    
    log_success "Build cleaned"
}

# Function to build the application
build_application() {
    log_info "Building ODYSSEY application..."
    
    # Generate Xcode project
    xcodegen --spec Config/project.yml
    
    # Build the app
    xcodebuild build \
        -project Config/ODYSSEY.xcodeproj \
        -scheme ODYSSEY \
        -configuration Release \
        -destination 'platform=macOS' \
        -quiet \
        -showBuildTimingSummary
    
    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)
    
    if [ -z "$APP_PATH" ]; then
        log_error "Could not find built application"
        exit 1
    fi
    
    echo "APP_PATH=$APP_PATH" >> "$GITHUB_ENV"
    log_success "Application built at: $APP_PATH"
}

# Function to build CLI
build_cli() {
    log_info "Building ODYSSEY CLI..."
    
    # Build CLI
    swift build --product odyssey-cli --configuration release
    
    # Get CLI path
    CLI_PATH=$(swift build --product odyssey-cli --configuration release --show-bin-path)/odyssey-cli
    
    # Make executable
    chmod +x "$CLI_PATH"
    
    # Test CLI
    "$CLI_PATH" version
    
    echo "CLI_PATH=$CLI_PATH" >> "$GITHUB_ENV"
    log_success "CLI built at: $CLI_PATH"
}

# Function to create DMG
create_dmg() {
    log_info "Creating DMG installer..."
    
    # Install create-dmg if not available
    if ! command -v create-dmg &> /dev/null; then
        log_info "Installing create-dmg..."
        brew install create-dmg
    fi
    
    # Create DMG
    create-dmg \
        --volname "ODYSSEY" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "ODYSSEY.app" 175 120 \
        --hide-extension "ODYSSEY.app" \
        --app-drop-link 425 120 \
        "${RELEASE_NAME}.dmg" \
        "$APP_PATH"
    
    log_success "DMG created: ${RELEASE_NAME}.dmg"
}

# Function to code sign
code_sign() {
    log_info "Code signing application..."
    
    # Check if we have a developer identity
    if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        local identity
        identity=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | cut -d'"' -f2)
        
        # Sign the app
        codesign --force --verify --verbose --sign "$identity" "$APP_PATH"
        
        # Sign the CLI
        codesign --force --verify --verbose --sign "$identity" "$CLI_PATH"
        
        log_success "Code signing completed"
    else
        log_warning "No Developer ID identity found, skipping code signing"
    fi
}

# Function to analyze build
analyze_build() {
    log_info "Analyzing build..."
    
    # Check app size
    APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
    log_info "App size: $APP_SIZE"
    
    # Check app structure
    if [ -f "$APP_PATH/Contents/Info.plist" ]; then
        log_success "Info.plist found"
    else
        log_error "Info.plist missing"
        exit 1
    fi
    
    if [ -d "$APP_PATH/Contents/Resources" ]; then
        log_success "Resources directory found"
    else
        log_error "Resources directory missing"
        exit 1
    fi
    
    # Check for required frameworks
    local required_frameworks=("WebKit.framework" "AppKit.framework")
    for framework in "${required_frameworks[@]}"; do
        if [ -d "$APP_PATH/Contents/Frameworks/$framework" ]; then
            log_success "Framework found: $framework"
        else
            log_warning "Framework missing: $framework"
        fi
    done
    
    log_success "Build analysis completed"
}

# Function to create release notes
create_release_notes() {
    log_info "Creating release notes..."
    
    # Get the last tag
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [ -n "$last_tag" ]; then
        # Generate release notes from commits since last tag
        git log --oneline --since="$last_tag" > RELEASE_NOTES.md
    else
        # Generate release notes from all commits
        git log --oneline > RELEASE_NOTES.md
    fi
    
    # Add header
    cat > RELEASE_NOTES_TEMP.md << EOF
# ODYSSEY v${VERSION} Release Notes

Build: ${BUILD_NUMBER}
Date: $(date)

## Changes

EOF
    
    cat RELEASE_NOTES.md >> RELEASE_NOTES_TEMP.md
    mv RELEASE_NOTES_TEMP.md RELEASE_NOTES.md
    
    log_success "Release notes created: RELEASE_NOTES.md"
}

# Function to create GitHub release
create_github_release() {
    if [ -z "$GITHUB_TOKEN" ]; then
        log_warning "GITHUB_TOKEN not set, skipping GitHub release"
        return
    fi
    
    log_info "Creating GitHub release..."
    
    # Create release using GitHub CLI or curl
    if command -v gh &> /dev/null; then
        gh release create "v${VERSION}" \
            --title "ODYSSEY v${VERSION}" \
            --notes-file RELEASE_NOTES.md \
            "${RELEASE_NAME}.dmg" \
            "$CLI_PATH"
    else
        log_warning "GitHub CLI not available, skipping GitHub release"
    fi
    
    log_success "GitHub release created"
}

# Function to show usage
show_usage() {
    echo "ODYSSEY Deployment Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build        Build the application and CLI"
    echo "  dmg          Create DMG installer"
    echo "  sign         Code sign the application"
    echo "  release      Full release process"
    echo "  clean        Clean previous builds"
    echo "  analyze      Analyze the build"
    echo ""
    echo "Environment Variables:"
    echo "  GITHUB_TOKEN    GitHub token for releases"
    echo "  DEVELOPER_ID    Developer ID for code signing"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 release"
    echo "  GITHUB_TOKEN=xxx $0 release"
}

# Main script logic
case "${1:-}" in
    "build")
        check_prerequisites
        clean_builds
        build_application
        build_cli
        analyze_build
        ;;
    "dmg")
        if [ -z "$APP_PATH" ]; then
            log_error "APP_PATH not set, run build first"
            exit 1
        fi
        create_dmg
        ;;
    "sign")
        if [ -z "$APP_PATH" ]; then
            log_error "APP_PATH not set, run build first"
            exit 1
        fi
        code_sign
        ;;
    "release")
        check_prerequisites
        clean_builds
        build_application
        build_cli
        code_sign
        create_dmg
        analyze_build
        create_release_notes
        create_github_release
        log_success "Release completed: ${RELEASE_NAME}"
        ;;
    "clean")
        clean_builds
        ;;
    "analyze")
        if [ -z "$APP_PATH" ]; then
            log_error "APP_PATH not set, run build first"
            exit 1
        fi
        analyze_build
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

log_success "Deployment completed!" 