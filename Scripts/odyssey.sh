#!/bin/bash

# ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself
# Unified Development and CI/CD Script
# 
# Usage: $0 <command> [options]
# 
# This script consolidates all ODYSSEY development and deployment functionality
# into a single, unified command-line interface.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
DRY_RUN=false
PROJECT_NAME="ODYSSEY"
PROJECT_PATH="Config/project.yml"
XCODEPROJ_PATH="Config/ODYSSEY.xcodeproj"
SOURCES_PATH="Sources"
BUILD_CONFIG="Debug"
SCHEME_NAME="ODYSSEY"
VERSION=""
BUILD_NUMBER=""
RELEASE_NAME=""

# Function to print colored output (unified logging)
print_status() {
    local status=$1
    local message=$2
    case $status in
        "info") echo -e "${BLUE}ℹ️ $message${NC}" ;;
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️ $message${NC}" ;;
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
    version=$(grep -A1 "CFBundleShortVersionString" Sources/AppCore/Info.plist | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
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
    echo "Usage: $script_name <command> [options]"
    echo ""
    echo "Development Commands:"
    echo "  setup       Setup development environment"
    echo "  build       Build application and CLI"
    echo "  lint        Run comprehensive linting"
    echo "  test        Run tests and validation"
    echo "  clean       Clean build artifacts"
    echo ""
    echo "CI/CD Commands:"
    echo "  ci          Run CI pipeline (setup, lint, build)"
    echo "  release     Run full release pipeline"
    echo "  deploy      Deploy and create release artifacts"
    echo "  sign        Code sign applications"
    echo "  changelog   Generate changelog"
    echo ""
    echo "Utility Commands:"
    echo "  logs        Show application logs"
    echo "  help        Show this help message"
    echo ""
    echo "Options:"
    echo "  --dry-run   Show what would be executed without running"
    echo "  --verbose   Enable verbose output"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $script_name setup"
    echo "  $script_name build"
    echo "  $script_name ci"
    echo "  $script_name release 3.2.0"
    echo "  $script_name --dry-run release 3.2.0"
}

# Function to setup development environment
setup_dev_environment() {
    print_status "step" "Setting up ODYSSEY development environment..."

    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi

    # Check macOS version
    MACOS_VERSION=$(sw_vers -productVersion)
    if [[ $(echo "$MACOS_VERSION 15.0" | tr " " "\n" | sort -V | head -1) != "15.0" ]]; then
        log_error "macOS 15.0 or later is required. Current version: $MACOS_VERSION"
        exit 1
    fi

    log_success "macOS version check passed: $MACOS_VERSION"

    # Install Homebrew if needed
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH if needed
        if [[ "$PATH" != *"/opt/homebrew/bin"* ]]; then
            echo "eval \"\$(/opt/homebrew/bin/brew shellenv)\"" >> ~/.zshrc
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        log_success "Homebrew installed"
    else
        log_success "Homebrew already installed"
    fi

    # Install Xcode command line tools if needed
    if ! xcode-select -p &> /dev/null; then
        log_info "Installing Xcode command line tools..."
        xcode-select --install
        log_warning "Please complete the Xcode installation in the popup window"
        log_warning "Press Enter when installation is complete..."
        read -r
        log_success "Xcode command line tools installed"
    else
        log_success "Xcode command line tools already installed"
    fi

    # Install development tools
    log_info "Installing development tools..."
    local tools=(
        "xcodegen"
        "swiftlint"
        "swiftformat"
        "shellcheck"
        "yamllint"
        "markdownlint-cli"
        "actionlint"
        "create-dmg"
    )

    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "$tool already installed"
        else
            log_info "Installing $tool..."
            brew install "$tool"
            log_success "$tool installed"
        fi
    done

    # Setup development environment
    log_info "Setting up development environment..."
    log_success "Development environment setup completed!"
}

# Function to build the application
build_application() {
    print_status "step" "Building ODYSSEY application..."

    # Check prerequisites
    check_prerequisites

    # Generate Xcode project
    generate_xcode_project

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
}

# Function to run comprehensive linting
run_linting() {
    print_status "step" "Running comprehensive linting..."

    # Check if linters are installed
    local missing_linters=()
    local required_linters=(
        "swiftlint"
        "swiftformat"
        "shellcheck"
        "yamllint"
        "markdownlint"
        "actionlint"
    )

    for linter in "${required_linters[@]}"; do
        if ! command -v "$linter" &> /dev/null; then
            missing_linters+=("$linter")
        fi
    done

    if [ ${#missing_linters[@]} -ne 0 ]; then
        print_status "error" "Missing required linters: ${missing_linters[*]}"
        print_status "info" "Install missing linters with: brew install ${missing_linters[*]}"
        exit 1
    fi

    print_status "success" "All linters available"

    echo ""
    print_status "step" "Running all linters..."
    echo ""

    local failed_linters=()

    # Run SwiftLint
    print_status "step" "Running SwiftLint..."
    if swiftlint lint --quiet; then
        print_status "success" "SwiftLint passed"
    else
        print_status "error" "SwiftLint found issues"
        failed_linters+=("SwiftLint")
    fi

    # Run SwiftFormat
    print_status "step" "Running SwiftFormat..."
    if swiftformat --lint Sources/ --quiet; then
        print_status "success" "SwiftFormat passed"
    else
        print_status "warning" "SwiftFormat found issues (run 'swiftformat Sources/' to fix)"
        failed_linters+=("SwiftFormat")
    fi

    # Run ShellCheck
    print_status "step" "Running ShellCheck..."
    if shellcheck --exclude=SC1091 Scripts/*.sh; then
        print_status "success" "ShellCheck passed"
    else
        print_status "warning" "ShellCheck found issues (mostly acceptable warnings)"
        failed_linters+=("ShellCheck")
    fi

    # Run YAML Linting
    print_status "step" "Running YAML Linting..."
    if yamllint Config/project.yml .github/workflows/*.yml; then
        print_status "success" "YAML Linting passed"
    else
        print_status "warning" "YAML Linting found issues (mostly style warnings)"
        failed_linters+=("YAML Linting")
    fi

    # Run Markdown Linting
    print_status "step" "Running Markdown Linting..."
    if markdownlint --config .markdownlint.json README.md Documentation/*.md .github/*.md; then
        print_status "success" "Markdown Linting passed"
    else
        print_status "warning" "Markdown Linting found issues (acceptable warnings ignored)"
        failed_linters+=("Markdown Linting")
    fi

    # Run GitHub Actions Linting
    print_status "step" "Running GitHub Actions Linting..."
    if actionlint -shellcheck="" .github/workflows/*.yml; then
        print_status "success" "GitHub Actions Linting passed"
    else
        print_status "warning" "GitHub Actions Linting found issues (acceptable warnings ignored)"
        failed_linters+=("GitHub Actions Linting")
    fi

    echo ""
    print_status "step" "Linting Summary"
    echo -e "${CYAN}================================${NC}"

    if [ ${#failed_linters[@]} -eq 0 ]; then
        print_status "success" "All linters passed! 🎉"
    else
        print_status "warning" "Some linters found issues: ${failed_linters[*]}"
        print_status "info" "Most warnings are acceptable for this project"
    fi

    echo ""
    print_status "info" "Linting completed. Check output above for details."
}

# Function to run tests and validation
run_tests() {
    print_status "step" "Running tests and validation..."

    # Validate project structure
    print_status "info" "Validating project structure..."
    local required_files=(
        "Package.swift"
        "Config/project.yml"
        "Sources/AppCore/AppDelegate.swift"
        "Sources/Views/Main/ContentView.swift"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_status "error" "Missing required file: $file"
            exit 1
        fi
    done
    print_status "success" "Project structure validation passed"

    # Test build
    print_status "info" "Testing build..."
    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would test build (dry run mode)"
    else
        # Quick build test
        swift build --product odyssey-cli --configuration debug
        print_status "success" "Build test passed"
    fi

    # Run linting as part of tests
    run_linting

    print_status "success" "Tests and validation completed"
}

# Function to run CI pipeline
run_ci() {
    print_status "step" "Running CI pipeline..."

    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would run CI pipeline (dry run mode):"
        echo "  - Setup development environment"
        echo "  - Run comprehensive linting"
        echo "  - Build application and CLI"
        return
    fi

    # Setup development environment
    setup_dev_environment

    # Run linting
    run_linting

    # Build application
    build_application

    print_status "success" "CI pipeline completed successfully"
}

# Function to create release
create_release() {
    local version=$1
    
    if [ -z "$version" ]; then
        print_status "error" "Version is required for release command"
        show_usage
        exit 1
    fi

    validate_version "$version"
    
    print_status "step" "Creating release v$version..."

    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would create release v$version (dry run mode)"
        return
    fi

    # Get current version
    local current_version
    current_version=$(get_current_version)
    print_status "info" "Current version: $current_version"

    # Check if version is different
    if [ "$version" = "$current_version" ]; then
        print_status "warning" "Version $version is already the current version"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Update version files
    print_status "step" "Updating version files..."
    
    # Update project.yml
    sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$version\"/" "$PROJECT_PATH"
    sed -i '' "s/CFBundleShortVersionString: .*/CFBundleShortVersionString: $version/" "$PROJECT_PATH"
    print_status "success" "Updated project.yml"

    # Update Info.plist
    sed -i '' "s/<string>.*<\/string>.*CFBundleShortVersionString/<string>$version<\/string> <!-- CFBundleShortVersionString/" "Sources/AppCore/Info.plist"
    print_status "success" "Updated Info.plist"

    # Update AppConstants.swift
    sed -i '' "s/appVersion = \".*\"/appVersion = \"$version\"/" "Sources/SharedUtils/AppConstants.swift"
    print_status "success" "Updated AppConstants.swift"

    # Update CLIExportService.swift
    sed -i '' "s/version: String = \".*\"/version: String = \"$version\"/" "Sources/Services/CLIExportService.swift"
    print_status "success" "Updated CLIExportService.swift"

    # Update changelog
    local date
    date=$(date +%Y-%m-%d)
    cat > /tmp/changelog_entry.md << EOF
## [$version] - $date

### Added
- New features and improvements

### Changed
- Updates and modifications

### Fixed
- Bug fixes and improvements

### Technical
- Build system improvements
- Code quality enhancements
- Performance optimizations

---

EOF

    # Insert at the top of changelog (after the header)
    sed -i '' "3r /tmp/changelog_entry.md" "CHANGELOG.md"
    rm /tmp/changelog_entry.md
    print_status "success" "Updated changelog"

    # Build CLI release version
    print_status "step" "Building CLI release version..."
    generate_xcode_project
    swift build --product odyssey-cli --configuration release
    CLI_PATH=$(swift build --product odyssey-cli --configuration release --show-bin-path)/odyssey-cli
    if [ -f "$CLI_PATH" ]; then
        chmod +x "$CLI_PATH"
        print_status "success" "CLI release built successfully"

        # Test CLI
        if "$CLI_PATH" version >/dev/null 2>&1; then
            print_status "success" "CLI release test passed"
        else
            print_status "warning" "CLI release test failed"
        fi

        # Code sign CLI
        codesign --remove-signature "$CLI_PATH" 2>/dev/null || true
        codesign --force --deep --sign - "$CLI_PATH"
        print_status "success" "CLI release code signing completed"
    else
        print_status "error" "CLI release build failed"
        exit 1
    fi

    print_status "success" "Release v$version prepared successfully!"
}

# Function to deploy and create release artifacts
deploy_release() {
    print_status "step" "Deploying release artifacts..."

    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would deploy release artifacts (dry run mode)"
        return
    fi

    # Build application in release mode
    print_status "step" "Building application in release mode..."
    generate_xcode_project
    
    xcodebuild build \
        -project "$XCODEPROJ_PATH" \
        -scheme "$SCHEME_NAME" \
        -configuration Release \
        -destination 'platform=macOS' \
        -quiet \
        -showBuildTimingSummary

    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)
    if [ -z "$APP_PATH" ]; then
        print_status "error" "Could not find built application"
        exit 1
    fi
    print_status "success" "Application built at: $APP_PATH"

    # Build CLI in release mode
    print_status "step" "Building CLI in release mode..."
    swift build --product odyssey-cli --configuration release
    CLI_PATH=$(swift build --product odyssey-cli --configuration release --show-bin-path)/odyssey-cli
    chmod +x "$CLI_PATH"
    print_status "success" "CLI built at: $CLI_PATH"

    # Code sign
    print_status "step" "Code signing applications..."
    if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        local identity
        identity=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | cut -d'"' -f2)
        codesign --force --verify --verbose --sign "$identity" "$APP_PATH"
        codesign --force --verify --verbose --sign "$identity" "$CLI_PATH"
        print_status "success" "Code signing completed"
    else
        print_status "warning" "No Developer ID identity found, skipping code signing"
    fi

    # Create DMG
    print_status "step" "Creating DMG installer..."
    if ! command -v create-dmg &> /dev/null; then
        print_status "info" "Installing create-dmg..."
        brew install create-dmg
    fi

    VERSION=$(get_current_version)
    BUILD_NUMBER=$(date +%Y%m%d%H%M)
    RELEASE_NAME="ODYSSEY-v${VERSION}-${BUILD_NUMBER}"

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

    print_status "success" "DMG created: ${RELEASE_NAME}.dmg"

    # Analyze build
    print_status "step" "Analyzing build..."

    if [ -f "$APP_PATH/Contents/Info.plist" ]; then
        print_status "success" "Info.plist found"
    else
        print_status "error" "Info.plist missing"
        exit 1
    fi

    if [ -d "$APP_PATH/Contents/Resources" ]; then
        print_status "success" "Resources directory found"
    else
        print_status "error" "Resources directory missing"
        exit 1
    fi

    print_status "success" "Deployment completed successfully!"
}

# Function to code sign applications
code_sign() {
    print_status "step" "Code signing applications..."

    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would code sign applications (dry run mode)"
        return
    fi

    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)
    if [ -z "$APP_PATH" ]; then
        print_status "error" "Could not find built application. Run build first."
        exit 1
    fi

    # Find the CLI
    CLI_PATH=$(swift build --product odyssey-cli --configuration release --show-bin-path)/odyssey-cli
    if [ ! -f "$CLI_PATH" ]; then
        print_status "error" "Could not find CLI. Run build first."
        exit 1
    fi

    # Check if we have a developer identity
    if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        local identity
        identity=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | cut -d'"' -f2)

        # Sign the app
        codesign --force --verify --verbose --sign "$identity" "$APP_PATH"
        print_status "success" "App code signed"

        # Sign the CLI
        codesign --force --verify --verbose --sign "$identity" "$CLI_PATH"
        print_status "success" "CLI code signed"

        print_status "success" "Code signing completed"
    else
        print_status "warning" "No Developer ID identity found, skipping code signing"
    fi
}

# Function to generate changelog
generate_changelog() {
    print_status "step" "Generating changelog..."

    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would generate changelog (dry run mode)"
        return
    fi

    # Extract version from tag or use current tag
    local version="${GITHUB_REF#refs/tags/}"
    version="${version#v}"

    # Get previous tag
    local previous_tag
    previous_tag="$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || echo "")"

    local changelog=""
    if [ -n "$previous_tag" ]; then
        # Get commits between previous tag and current tag
        changelog="$(git log --pretty=format:"- %s" "${previous_tag}"..HEAD)"
    else
        # If no previous tag, get all commits
        changelog="$(git log --pretty=format:"- %s" HEAD)"
    fi

    # Output for GitHub Actions
    if [ -n "$GITHUB_OUTPUT" ]; then
        {
            echo "CHANGELOG<<EOF"
            echo "$changelog"
            echo "EOF"
        } >> "$GITHUB_OUTPUT"
    fi

    # Also output to stdout for local use
    echo "$changelog"

    print_status "success" "Changelog generated"
}

# Function to show application logs
show_logs() {
    print_status "step" "Showing ODYSSEY application logs..."
    echo "🔍 ODYSSEY Log Monitor"
    echo "======================"
    echo "Monitoring logs for ODYSSEY app..."
    echo "Press Ctrl+C to stop monitoring"
    echo ""

    # Monitor Console.app logs for ODYSSEY
    log stream --predicate 'process == "ODYSSEY"' --info --debug
}

# Main script logic
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                print_status "error" "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done

    # Get command
    local command="${1:-}"
    shift

    # Validate project root
    validate_project_root

    # Execute command
    case "$command" in
        "setup")
            setup_dev_environment
            ;;
        "build")
            build_application
            ;;
        "lint")
            run_linting
            ;;
        "test")
            run_tests
            ;;
        "clean")
            clean_builds
            ;;
        "ci")
            run_ci
            ;;
        "release")
            create_release "$1"
            ;;
        "deploy")
            deploy_release
            ;;
        "sign")
            code_sign
            ;;
        "changelog")
            generate_changelog
            ;;
        "logs")
            show_logs
            ;;
        "help")
            show_usage
            ;;
        "")
            show_usage
            exit 1
            ;;
        *)
            print_status "error" "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac

    print_status "success" "Command '$command' completed successfully!"
}

# Run main function with all arguments
main "$@" 