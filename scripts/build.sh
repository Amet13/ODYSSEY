#!/bin/bash

# ODYSSEY Build Script
# Builds and launches the ODYSSEY macOS application

set -e

echo "🏀 ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself (macOS Automation)"
echo "=================================================================="
echo ""

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "❌ XcodeGen is not installed. Please install it first:"
    echo "   brew install xcodegen"
    exit 1
fi

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ xcodebuild is not available. Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

# Generate Xcode project
echo "🔨 Generating Xcode project..."
cd "$(dirname "$0")/.." && xcodegen --spec Config/project.yml

# Build project
echo "🔨 Building project..."
cd "$(dirname "$0")/.." && xcodebuild build \
    -project Config/ODYSSEY.xcodeproj \
    -scheme ODYSSEY \
    -configuration Debug \
    -destination 'platform=macOS' \
    -quiet

echo "✅ Build successful! (took $(($SECONDS))s)"

# Find the built app
echo "🔨 Locating built application..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built application"
    exit 1
fi

echo "✅ App built at: $APP_PATH"

# Get app size
APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
echo "ℹ️ App size: $APP_SIZE"

# Stop existing ODYSSEY instance if running
echo "🔨 Stopping existing ODYSSEY instance..."
if pgrep -f "ODYSSEY" > /dev/null; then
    echo "   Found running ODYSSEY process, terminating..."
    pkill -f "ODYSSEY" 2>/dev/null || true
    
    # Wait for process to terminate
    echo "   Waiting for process to terminate..."
    for i in {1..10}; do
        if ! pgrep -f "ODYSSEY" > /dev/null; then
            echo "   ✅ Process terminated successfully"
            break
        fi
        sleep 0.5
    done
    
    # Force kill if still running
    if pgrep -f "ODYSSEY" > /dev/null; then
        echo "   ⚠️ Process still running, force killing..."
        pkill -9 -f "ODYSSEY" 2>/dev/null || true
        sleep 1
    fi
else
    echo "   No running ODYSSEY process found"
fi

# Launch ODYSSEY
echo "🔨 Launching ODYSSEY..."
open "$APP_PATH"

# Wait for the app to launch and verify it's running
echo "   Waiting for app to launch..."
for i in {1..15}; do
    if pgrep -f "ODYSSEY" > /dev/null; then
        echo "✅ ODYSSEY launched successfully!"
        break
    fi
    sleep 0.5
done

# Final check
if ! pgrep -f "ODYSSEY" > /dev/null; then
    echo "⚠️ ODYSSEY may not have launched properly"
fi

echo ""
echo "🎉 ODYSSEY build process completed!"
echo ""
echo "Next steps:"
echo "1. Open Config/ODYSSEY.xcodeproj in Xcode for development"
echo "2. Run the app to configure your reservations"
echo "3. The app will appear in your menu bar"
echo ""
echo "For more information, see Documentation/README.md"
echo ""
echo "Happy coding! 🚀" 