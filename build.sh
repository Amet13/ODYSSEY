#!/bin/bash

# ORRMAT Build Script
# This script helps build and run the ORRMAT macOS application
# Repository: https://github.com/Amet13/orrmat
# 
# Usage: ./build.sh [options]
# Options:
#   --clean     Clean build directory before building
#   --release   Build in Release configuration
#   --help      Show this help message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ORRMAT"
SCHEME_NAME="ORRMAT"
CONFIGURATION="Debug"
CLEAN_BUILD=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔨${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

# Function to show help
show_help() {
    echo "ORRMAT Build Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --clean     Clean build directory before building"
    echo "  --release   Build in Release configuration"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Build in Debug mode"
    echo "  $0 --clean      # Clean and build in Debug mode"
    echo "  $0 --release    # Build in Release mode"
    echo "  $0 --clean --release  # Clean and build in Release mode"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --release)
            CONFIGURATION="Release"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Header
echo -e "${PURPLE}🏀 ORRMAT - Ottawa Recreation Reservation macOS Automation Tool${NC}"
echo "=================================================================="
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode command line tools not found."
    echo "Please install Xcode from the App Store or run: xcode-select --install"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "ORRMAT.xcodeproj/project.pbxproj" ]; then
    print_error "ORRMAT.xcodeproj not found in current directory."
    echo "Please run this script from the project root directory."
    exit 1
fi

# Check if XcodeGen is needed
if [ ! -f "ORRMAT.xcodeproj/project.pbxproj" ] && [ -f "project.yml" ]; then
    print_warning "Xcode project not found, but project.yml exists."
    echo "Generating Xcode project from project.yml..."
    
    if ! command -v xcodegen &> /dev/null; then
        print_error "XcodeGen not found. Please install it with: brew install xcodegen"
        exit 1
    fi
    
    xcodegen
    print_success "Xcode project generated successfully!"
fi

print_status "Building ORRMAT in $CONFIGURATION configuration..."

# Clean previous builds if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_status "Cleaning previous builds..."
    xcodebuild clean -project ORRMAT.xcodeproj -scheme ORRMAT
    print_success "Clean completed!"
fi

# Build the project
print_status "Building project..."
BUILD_START_TIME=$(date +%s)

xcodebuild build \
    -project ORRMAT.xcodeproj \
    -scheme ORRMAT \
    -configuration $CONFIGURATION \
    -quiet

BUILD_EXIT_CODE=$?
BUILD_END_TIME=$(date +%s)
BUILD_DURATION=$((BUILD_END_TIME - BUILD_START_TIME))

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    print_success "Build successful! (took ${BUILD_DURATION}s)"
    
    # Find the built app
    print_status "Locating built application..."
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ORRMAT.app" -type d 2>/dev/null | head -1)
    
    if [ -n "$APP_PATH" ]; then
        print_success "App built at: $APP_PATH"
        
        # Get app size
        APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
        print_info "App size: $APP_SIZE"
        
        # Stop existing instance
        print_status "Stopping existing ORRMAT instance..."
        pkill ORRMAT 2>/dev/null || true
        sleep 1
        
        # Launch the app
        print_status "Launching ORRMAT..."
        open "$APP_PATH"
        
        print_success "ORRMAT launched successfully!"
    else
        print_warning "Could not locate built app."
        echo "You may need to open the project in Xcode to run it."
    fi
else
    print_error "Build failed!"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 ORRMAT build process completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Open ORRMAT.xcodeproj in Xcode for development"
echo "2. Run the app to configure your reservations"
echo "3. The app will appear in your menu bar"
echo ""
echo "For more information, see README.md"
echo ""
echo -e "${CYAN}Happy coding! 🚀${NC}" 