#!/bin/bash

# ODYSSEY Build Script
# Builds and launches the ODYSSEY macOS application with comprehensive quality checks

set -e

# Source common functions
source "$(dirname "$0")/common.sh"

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

# Build CLI (Debug only for development)
print_status "step" "Building CLI tool..."
print_status "info" "Building CLI in debug configuration..."
measure_time swift build --product odyssey-cli --configuration debug

# Check CLI build success
CLI_PATH=$(swift build --product odyssey-cli --configuration debug --show-bin-path)/odyssey-cli
if [ -f "$CLI_PATH" ]; then
    chmod +x "$CLI_PATH"

    print_status "success" "CLI built successfully at: $CLI_PATH"

    # Test CLI
    print_status "info" "Testing CLI..."
    if "$CLI_PATH" version >/dev/null 2>&1; then
        print_status "success" "CLI test passed"
    else
        print_status "warning" "CLI test failed"
    fi

    # Code sign CLI
    print_status "info" "Code signing CLI..."
    codesign --remove-signature "$CLI_PATH" 2>/dev/null || true
    codesign --force --deep --sign - "$CLI_PATH"
    print_status "success" "CLI code signing completed"
else
    print_status "error" "CLI build failed"
    exit 1
fi

# Find the built app
print_status "step" "Locating built application..."
LATEST_APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -path "*/Build/Products/Debug/*" -type d -exec ls -td {} + 2>/dev/null | head -1)

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
    for _ in {1..10}; do
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
for _ in {1..15}; do
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
print_status "info" "App Location: $APP_PATH"
print_status "info" "CLI Location: $CLI_PATH"
print_status "info" "Status: Running in menu bar"

echo ""
print_status "success" "$PROJECT_NAME build process completed!"
echo ""
print_status "info" "Next steps:"
echo "1. Open $XCODEPROJ_PATH in Xcode for development"
echo "2. Run the app to configure your reservations"
echo "3. The app will appear in your menu bar"
echo "4. Use CLI: $CLI_PATH <command> for remote automation"
echo ""
print_status "info" "For more information, see Documentation/README.md"
echo ""
print_status "success" "Happy coding! 🚀"