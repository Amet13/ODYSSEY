#!/bin/bash

# ODYSSEY Build Script
# Builds and launches the ODYSSEY macOS application with comprehensive quality checks

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
PROJECT_NAME="ODYSSEY"
PROJECT_PATH="Config/project.yml"
XCODEPROJ_PATH="Config/ODYSSEY.xcodeproj"
SOURCES_PATH="Sources"
BUILD_CONFIG="Debug"
SCHEME_NAME="ODYSSEY"

echo -e "${CYAN}🥅 ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself (macOS Automation)${NC}"
echo -e "${CYAN}==================================================================${NC}"
echo ""

# Function to print colored output
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

# Check prerequisites
print_status "step" "Checking prerequisites..."

if ! command_exists xcodegen; then
    print_status "error" "XcodeGen is not installed. Please install it first:"
    echo "   brew install xcodegen"
    exit 1
fi

if ! command_exists xcodebuild; then
    print_status "error" "xcodebuild is not available. Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

if ! command_exists swiftlint; then
    print_status "warning" "SwiftLint not found. Installing..."
    brew install swiftlint
fi

if ! command_exists swiftformat; then
    print_status "warning" "SwiftFormat not found. Installing..."
    brew install swiftformat
fi

# Check for Node.js and npm for JavaScript linting
if ! command_exists node; then
    print_status "warning" "Node.js not found. Installing..."
    brew install node
fi

if ! command_exists npm; then
    print_status "warning" "npm not found. Installing..."
    brew install npm
fi

print_status "success" "All prerequisites satisfied"

# Generate Xcode project
print_status "step" "Generating Xcode project..."
measure_time xcodegen --spec "$PROJECT_PATH"

# Code quality checks
print_status "step" "Running code quality checks..."

# Format Swift code
if command_exists swiftformat; then
    print_status "info" "Formatting Swift code with SwiftFormat..."
    if swiftformat --lint "$SOURCES_PATH" >/dev/null 2>&1; then
        print_status "success" "Code formatting is correct"
    else
        print_status "warning" "Code formatting issues found. Running auto-format..."
        swiftformat "$SOURCES_PATH"
        print_status "success" "Code auto-formatted"
    fi
else
    print_status "warning" "SwiftFormat not found. Skipping code formatting."
fi

# Lint Swift code
if command_exists swiftlint; then
    print_status "info" "Linting Swift code with SwiftLint..."
    if swiftlint lint --config .swiftlint.yml --quiet --fix --format; then
        print_status "success" "Code linting passed"
    else
        print_status "warning" "Code linting issues found (non-blocking)"
    fi
else
    print_status "warning" "SwiftLint not found. Skipping linting."
fi

# Lint JavaScript code
if command_exists npm && [ -f "package.json" ]; then
    print_status "info" "Linting JavaScript code with ESLint..."
    if npm run lint:check >/dev/null 2>&1; then
        print_status "success" "JavaScript linting passed"
    else
        print_status "warning" "JavaScript linting issues found (non-blocking)"
        print_status "info" "Run 'npm run lint:fix' to auto-fix issues"
    fi
else
    print_status "warning" "npm or package.json not found. Skipping JavaScript linting."
fi

# Build project
print_status "step" "Building project..."
cd "$(dirname "$0")/.."

measure_time xcodebuild build \
    -project "$XCODEPROJ_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration "$BUILD_CONFIG" \
    -destination 'platform=macOS' \
    -quiet \
    -showBuildTimingSummary

# Find the built app
print_status "step" "Locating built application..."
LATEST_APP_PATH=$(ls -td ~/Library/Developer/Xcode/DerivedData/ODYSSEY-*/Build/Products/Debug/ODYSSEY.app 2>/dev/null | head -1)

if [ -z "$LATEST_APP_PATH" ]; then
    print_status "error" "Could not find built application"
    exit 1
fi

APP_PATH="$LATEST_APP_PATH"
print_status "success" "App built at: $APP_PATH"

# App analysis
print_status "step" "Analyzing built application..."

# Get app size
APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
print_status "info" "App size: $APP_SIZE"

# Check app size (should be under 10MB)
SIZE_BYTES=$(du -s "$APP_PATH" | cut -f1)
if [ "$SIZE_BYTES" -gt 10240 ]; then
    print_status "warning" "App size is larger than expected: $APP_SIZE"
else
    print_status "success" "App size is reasonable: $APP_SIZE"
fi

# Check app structure
print_status "info" "App structure analysis:"
if [ -f "$APP_PATH/Contents/Info.plist" ]; then
    print_status "success" "Info.plist found"
else
    print_status "error" "Info.plist missing"
fi

if [ -d "$APP_PATH/Contents/Resources" ]; then
    print_status "success" "Resources directory found"
else
    print_status "warning" "Resources directory missing"
fi

# Check code signing
print_status "info" "Code signing status:"
if codesign -dv "$APP_PATH" 2>/dev/null; then
    print_status "success" "App is code signed"
else
    print_status "warning" "App is not code signed (expected for development)"
fi

# Stop existing ODYSSEY instance if running
print_status "step" "Managing existing ODYSSEY instances..."
if pgrep -f "$PROJECT_NAME" > /dev/null; then
    print_status "info" "Found running $PROJECT_NAME process, terminating..."
    pkill -f "$PROJECT_NAME" 2>/dev/null || true
    
    # Wait for process to terminate
    print_status "info" "Waiting for process to terminate..."
    for i in {1..10}; do
        if ! pgrep -f "$PROJECT_NAME" > /dev/null; then
            print_status "success" "Process terminated successfully"
            break
        fi
        sleep 0.5
    done
    
    # Force kill if still running
    if pgrep -f "$PROJECT_NAME" > /dev/null; then
        print_status "warning" "Process still running, force killing..."
        pkill -9 -f "$PROJECT_NAME" 2>/dev/null || true
        sleep 1
    fi
else
    print_status "info" "No running $PROJECT_NAME process found"
fi

# Launch ODYSSEY
print_status "step" "Launching $PROJECT_NAME..."
open "$APP_PATH"

# Wait for the app to launch and verify it's running
print_status "info" "Waiting for app to launch..."
for i in {1..15}; do
    if pgrep -f "$PROJECT_NAME" > /dev/null; then
        print_status "success" "$PROJECT_NAME launched successfully!"
        break
    fi
    sleep 0.5
done

# Final check
if ! pgrep -f "$PROJECT_NAME" > /dev/null; then
    print_status "warning" "$PROJECT_NAME may not have launched properly"
fi

# Build summary
echo ""
print_status "step" "Build Summary"
echo -e "${CYAN}================================${NC}"
print_status "info" "Project: $PROJECT_NAME"
print_status "info" "Configuration: $BUILD_CONFIG"
print_status "info" "App Size: $APP_SIZE"
print_status "info" "Build Location: $APP_PATH"
print_status "info" "Status: Running in menu bar"

echo ""
print_status "success" "$PROJECT_NAME build process completed!"
echo ""
print_status "info" "Next steps:"
echo "1. Open $XCODEPROJ_PATH in Xcode for development"
echo "2. Run the app to configure your reservations"
echo "3. The app will appear in your menu bar"
echo ""
print_status "info" "For more information, see Documentation/README.md"
echo ""
print_status "success" "Happy coding! 🚀" 