#!/bin/bash

# ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself
# Unified Development and CI/CD Script
#
# Usage: $0 <command> [options]
#
# This script consolidates all ODYSSEY development and deployment functionality
# into a single, unified command-line interface.

set -e

# Set Homebrew to not auto-update to prevent unnecessary updates
export HOMEBREW_NO_AUTO_UPDATE=1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
PROJECT_NAME="ODYSSEY"
PROJECT_PATH="Config/project.yml"
XCODEPROJ_PATH="Config/ODYSSEY.xcodeproj"
SOURCES_PATH="Sources"
BUILD_CONFIG="Debug"
SCHEME_NAME="ODYSSEY"

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
    print_status "success" "Completed in ${duration}s."
}

# Function to check prerequisites
check_prerequisites() {
    local missing_tools=()

    # Check for required tools
    local required_tools=("xcodebuild" "xcodegen" "swift" "swift-format")
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

# Function to install development tools
install_tools() {
    local tools=(
        "xcodegen"
        "swift-format"
        "shellcheck"
        "yamllint"
        "markdownlint-cli"
        "actionlint"
        "create-dmg"
    )

    # Check if all tools are already installed first
    local missing_tools=()
    for tool in "${tools[@]}"; do
        # Special case for markdownlint-cli - check for markdownlint binary
        if [ "$tool" = "markdownlint-cli" ]; then
            if ! command -v "markdownlint" &> /dev/null; then
                missing_tools+=("$tool")
            fi
        else
            if ! command -v "$tool" &> /dev/null; then
                missing_tools+=("$tool")
            fi
        fi
    done

    # If all tools are installed, skip installation
    if [ ${#missing_tools[@]} -eq 0 ]; then
        log_success "All development tools already installed"
        return 0
    fi

    # Install missing tools in batch for better performance
    log_info "Installing missing development tools: ${missing_tools[*]}..."

    # Install with minimal output and no analytics
    HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 brew install --quiet "${missing_tools[@]}"

    log_success "Development tools installation completed"
}

# Function to find the latest built app
find_built_app() {
    local config=${1:-Debug}
    local app_path

    # First try to find the app in the specified configuration
    app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -path "*/Build/Products/$config/*" -type d -exec ls -td {} + 2>/dev/null | head -1)

    # If not found, try the other configuration
    if [ -z "$app_path" ]; then
        if [ "$config" = "Debug" ]; then
            app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -path "*/Build/Products/Release/*" -type d -exec ls -td {} + 2>/dev/null | head -1)
        else
            app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -path "*/Build/Products/Debug/*" -type d -exec ls -td {} + 2>/dev/null | head -1)
        fi
    fi

    # Last resort: find any ODYSSEY.app
    if [ -z "$app_path" ]; then
        app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)
    fi

    if [ -z "$app_path" ]; then
        print_status "error" "Could not find built application"
        exit 1
    fi

    echo "$app_path"
}

# Function to find CLI path
find_cli_path() {
    local config=${1:-debug}
    local cli_path
    cli_path=$(swift build --product odyssey-cli --configuration "$config" --show-bin-path)/odyssey-cli

    if [ ! -f "$cli_path" ]; then
        print_status "error" "Could not find CLI. Run build first."
        exit 1
    fi

    echo "$cli_path"
}

# Function to validate app structure
validate_app_structure() {
    local app_path=$1

    print_status "info" "App structure analysis:"
    if [ -f "$app_path/Contents/Info.plist" ]; then
        print_status "success" "Info.plist found"
    else
        print_status "error" "Info.plist missing"
        return 1
    fi

    if [ -d "$app_path/Contents/Resources" ]; then
        print_status "success" "Resources directory found"
    else
        print_status "warning" "Resources directory missing"
    fi

    return 0
}

# Function to perform code signing
perform_code_signing() {
    local app_path=$1
    local cli_path=$2

    print_status "info" "Code signing status:"

    if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        local identity
        identity=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | cut -d'"' -f2)

        # Sign the app
        codesign --force --verify --verbose --sign "$identity" "$app_path"
        print_status "success" "App code signed"

        # Sign the CLI
        codesign --force --verify --verbose --sign "$identity" "$cli_path"
        print_status "success" "CLI code signed"

        print_status "success" "Code signing completed"
    else
        print_status "warning" "No Developer ID identity found, skipping code signing"
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
    echo "  clean       Clean build artifacts"
    echo ""
    echo "Release Commands:"
    echo "  release     Create a new release (version, build, tag, push)"
    echo "  ci          Run CI pipeline (setup, lint, build)"
    echo "  deploy      Deploy and create release artifacts"
    echo "  changelog   Generate commit-based changelog"
    echo ""
    echo "Utility Commands:"
    echo "  logs        Show application logs"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $script_name setup"
    echo "  $script_name build"
    echo "  $script_name release 1.1.1"
    echo "  $script_name ci"
    echo "  $script_name deploy"
}

# Function to check macOS requirements
check_macos_requirements() {
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi

    # Check macOS version
    local macos_version
    macos_version=$(sw_vers -productVersion)
    if [[ $(echo "$macos_version 15.0" | tr " " "\n" | sort -V | head -1) != "15.0" ]]; then
        log_error "macOS 15.0 or later is required. Current version: $macos_version"
        exit 1
    fi

    log_success "macOS version check passed: $macos_version"
}

# Function to install Homebrew if needed
install_homebrew() {
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
}

# Function to install Xcode command line tools
install_xcode_tools() {
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
}

# Function to run swift-format
run_swift_format() {
    if command_exists swift-format; then
        print_status "info" "Formatting and linting Swift code with swift-format..."
        if swift-format format --in-place --recursive "$SOURCES_PATH"; then
            print_status "success" "Code formatting is correct"
        else
            print_status "warning" "Code formatting issues found. Running auto-format..."
            swift-format format --in-place --recursive "$SOURCES_PATH"
            print_status "success" "Code auto-formatted"
        fi
    else
        print_status "warning" "swift-format not found. Skipping code formatting and linting."
    fi
}

# Function to build CLI
build_cli() {
    local config=${1:-debug}
    print_status "step" "Building CLI tool..."
    print_status "info" "Building CLI in $config configuration..."

    # Suppress warnings in release builds
    if [ "$config" = "release" ]; then
        # Redirect stderr to suppress warnings in release builds
        local start_time=$SECONDS
        swift build --product odyssey-cli --configuration "$config" 2>/dev/null || true
        local end_time=$SECONDS
        local duration=$((end_time - start_time))
        print_status "success" "Completed in ${duration}s."
    else
        measure_time swift build --product odyssey-cli --configuration "$config"
    fi

    # Check CLI build success
    CLI_PATH=$(find_cli_path "$config")
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
}

# Function to manage existing ODYSSEY instances
manage_existing_instances() {
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
}

# Function to launch ODYSSEY
launch_odyssey() {
    local app_path=$1
    print_status "step" "Launching $PROJECT_NAME..."
    open "$app_path"

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
}

# Function to show build summary
show_build_summary() {
    local app_path=$1
    local cli_path=$2
    echo ""
    print_status "step" "Build Summary"
    echo -e "${CYAN}================================${NC}"
    print_status "info" "Project: $PROJECT_NAME"
    print_status "info" "Configuration: $BUILD_CONFIG"
    print_status "info" "App Location: $app_path"
    print_status "info" "CLI Location: $cli_path"
    print_status "info" "Status: Running in menu bar"

    echo ""
    print_status "success" "$PROJECT_NAME build process completed!"
    echo ""
    print_status "info" "Next steps:"
    echo "1. Open $XCODEPROJ_PATH in Xcode for development"
    echo "2. Run the app to configure your reservations"
    echo "3. The app will appear in your menu bar"
    echo "4. Use CLI: $cli_path <command> for remote automation"
    echo ""
    print_status "info" "For more information, see Documentation/README.md"
    echo ""
    print_status "success" "Happy coding! 🚀"
}

# Function to setup development environment
setup_dev_environment() {
    print_status "step" "Setting up ODYSSEY development environment..."

    check_macos_requirements
    install_homebrew
    install_xcode_tools

    # Install development tools
    log_info "Installing development tools..."
    install_tools

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
    run_swift_format

    # Build project
    print_status "step" "Building project..."
    measure_time xcodebuild build \
        -project "$XCODEPROJ_PATH" \
        -scheme "$SCHEME_NAME" \
        -configuration "$BUILD_CONFIG" \
        -destination 'platform=macOS,arch=arm64' \
        -quiet \
        -showBuildTimingSummary

    # Build CLI
    build_cli debug

    # Find the built app
    print_status "step" "Locating built application..."
    LATEST_APP_PATH=$(find_built_app)

    if [ -z "$LATEST_APP_PATH" ]; then
        print_status "error" "Could not find built application"
        exit 1
    fi

    APP_PATH="$LATEST_APP_PATH"
    print_status "success" "App built at: $APP_PATH"

    # App analysis
    print_status "step" "Analyzing built application..."
    validate_app_structure "$APP_PATH"

    # Check code signing
    print_status "info" "Code signing status:"
    if codesign -dv "$APP_PATH" 2>/dev/null; then
        print_status "success" "App is code signed"
    else
        print_status "warning" "App is not code signed (expected for development)"
    fi

    # Manage existing instances and launch
    manage_existing_instances
    launch_odyssey "$APP_PATH"

    # Show build summary
    show_build_summary "$APP_PATH" "$CLI_PATH"
}

# Function to run comprehensive linting
run_linting() {
    print_status "step" "Running comprehensive linting..."

    # Check if linters are installed
    local missing_linters=()
    local required_linters=(
        "swift-format"
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

    # Run swift-format
    print_status "step" "Running swift-format..."
    if swift-format format --in-place --recursive "$SOURCES_PATH"; then
        print_status "success" "swift-format passed"
    else
        print_status "warning" "swift-format found issues (run 'swift-format format --configuration .swift-format --recursive Sources/' to fix)"
        failed_linters+=("swift-format")
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
    if yamllint -c .yamllint .; then
        print_status "success" "YAML Linting passed"
    else
        print_status "warning" "YAML Linting found issues (mostly style warnings)"
        failed_linters+=("YAML Linting")
    fi

    # Run Markdown Linting
    print_status "step" "Running Markdown Linting..."
    if markdownlint --config .markdownlint.json .; then
        print_status "success" "Markdown Linting passed"
    else
        print_status "warning" "Markdown Linting found issues (acceptable warnings ignored)"
        failed_linters+=("Markdown Linting")
    fi



    # Run GitHub Actions Linting
    print_status "step" "Running GitHub Actions Linting..."
    if actionlint .github/workflows/*.yml; then
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



# Function to run CI pipeline
run_ci() {
    print_status "step" "Running CI pipeline..."

    # Setup development environment
    setup_dev_environment

    # Run linting
    run_linting

    # Build application
    build_application

    print_status "success" "CI pipeline completed successfully"
}

# Function to update version files
update_version_files() {
    local version=$1
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
}

# Function to create release
create_release() {
    local version=$1

    if [ -z "$version" ]; then
        print_status "error" "Version is required. Usage: $0 release <version>"
        print_status "info" "Example: $0 release 1.1.1"
        exit 1
    fi

    # Validate version format
    validate_version "$version"

    print_status "step" "Creating release v$version..."

    # Check if we're in a clean git state
    if [ -n "$(git status --porcelain)" ]; then
        print_status "error" "Git working directory is not clean. Please commit or stash changes first."
        exit 1
    fi

    # Check if tag already exists
    if git tag -l "v$version" | grep -q "v$version"; then
        print_status "error" "Tag v$version already exists"
        exit 1
    fi

    # Update version files
    update_version_files "$version"

    # Build applications to ensure everything works
    print_status "step" "Building applications to validate changes..."
    build_application

    # Test CLI to ensure it works with new version
    print_status "step" "Testing CLI with new version..."
    CLI_PATH=$(find_cli_path debug)
    if "$CLI_PATH" version >/dev/null 2>&1; then
        print_status "success" "CLI test passed"
    else
        print_status "error" "CLI test failed"
        exit 1
    fi

    # Commit changes
    print_status "step" "Committing version changes..."
    git add .
    git commit -m "🔖 Release v$version

- Updated version to $version in all files
- Built and tested applications
- Validated CLI functionality"

    # Create and push tag
    print_status "step" "Creating git tag v$version..."
    git tag "v$version"

    # Push changes and tag
    print_status "step" "Pushing changes and tag to main..."
    git push origin main
    git push origin "v$version"

    print_status "success" "Release v$version created successfully!"
    print_status "info" "GitHub Actions will automatically build and publish the release"
    print_status "info" "Monitor the release at: https://github.com/Amet13/ODYSSEY/releases"
}



# Function to deploy and create release artifacts
deploy_release() {
    print_status "step" "Deploying release artifacts..."

    # Build application in release mode
    print_status "step" "Building application in release mode..."
    generate_xcode_project

    xcodebuild build \
        -project "$XCODEPROJ_PATH" \
        -scheme "$SCHEME_NAME" \
        -configuration Release \
        -destination 'platform=macOS,arch=arm64' \
        -quiet \
        -showBuildTimingSummary \
        GCC_WARN_INHIBIT_ALL_WARNINGS=YES

    # Find the built app
    APP_PATH=$(find_built_app Release)
    print_status "success" "Application built at: $APP_PATH"



    # Build CLI in release mode
    build_cli release

    # Create release_files directory and copy artifacts
    print_status "step" "Preparing release artifacts..."
    mkdir -p release_files

    # Copy app to release_files
    cp -R "$APP_PATH" release_files/
    print_status "success" "App copied to release_files/"



    # Copy CLI to release_files
    cp "$CLI_PATH" release_files/
    print_status "success" "CLI copied to release_files/"

    # Code sign
    print_status "step" "Code signing applications..."
    perform_code_signing "$APP_PATH" "$CLI_PATH"

    # Create DMG
    print_status "step" "Creating DMG installer..."
    if ! command -v create-dmg &> /dev/null; then
        print_status "info" "Installing create-dmg..."
        brew install create-dmg
    fi

    local version
    version=$(get_current_version)
    local release_name="ODYSSEY"

    create-dmg \
        --volname "ODYSSEY" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "ODYSSEY.app" 175 120 \
        --hide-extension "ODYSSEY.app" \
        --app-drop-link 425 120 \
        "${release_name}.dmg" \
        "$APP_PATH"

    print_status "success" "DMG created: ${release_name}.dmg"

    # Analyze build
    print_status "step" "Analyzing build..."
    validate_app_structure "$APP_PATH"

    print_status "success" "Deployment completed successfully!"
}





# Function to generate commit-based changelog
generate_changelog() {
    print_status "step" "Generating commit-based changelog..."

    # Get the current tag (version)
    local current_tag
    current_tag="${GITHUB_REF#refs/tags/}"
    current_tag="${current_tag#v}"

    # Get the previous tag
    local previous_tag
    previous_tag="$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || echo "")"

    local changelog=""
    if [ -n "$previous_tag" ]; then
        # Get commits between previous tag and current tag with better formatting
        changelog="$(git log --pretty=format:"- %s (%h)" --no-merges "${previous_tag}"..HEAD | grep -v "Merge pull request" | grep -v "Merge branch")"
        print_status "info" "Generating changelog from ${previous_tag} to ${current_tag}"
    else
        # If no previous tag, get all commits
        changelog="$(git log --pretty=format:"- %s (%h)" --no-merges HEAD | grep -v "Merge pull request" | grep -v "Merge branch")"
        print_status "info" "Generating changelog for all commits (no previous tag found)"
    fi

    # Output simple changelog without categorization
    local simple_changelog=""
    if [ -n "$changelog" ]; then
        simple_changelog="$changelog"
    else
        simple_changelog="- No commits found"
    fi

    # Output for GitHub Actions
    if [ -n "$GITHUB_OUTPUT" ]; then
        {
            echo "CHANGELOG<<EOF"
            echo "$simple_changelog"
            echo "EOF"
        } >> "$GITHUB_OUTPUT"
        print_status "success" "Simple changelog generated and sent to GitHub Actions"
    fi

    # Also output to stdout for local use
    echo "$simple_changelog"
    print_status "success" "Simple commit-based changelog generated"
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
    log stream --predicate 'process == "ODYSSEY"' --info --debug | grep debug
}

# Main script logic
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
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
    if [ $# -gt 0 ]; then
        shift
    fi

    # Execute command
    case "$command" in
        "setup")
            validate_project_root
            setup_dev_environment
            ;;
        "build")
            validate_project_root
            build_application
            ;;
        "lint")
            validate_project_root
            run_linting
            ;;

        "clean")
            validate_project_root
            clean_builds
            ;;
        "release")
            validate_project_root
            create_release "$1"
            ;;
        "ci")
            validate_project_root
            run_ci
            ;;
        "deploy")
            validate_project_root
            deploy_release
            ;;

        "changelog")
            validate_project_root
            generate_changelog
            ;;
        "logs")
            validate_project_root
            show_logs
            ;;
        "help")
            show_usage
            ;;
        "")
            show_usage
            ;;
        *)
            print_status "error" "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac

    if [ -n "$command" ]; then
        print_status "success" "Command '$command' completed successfully!"
    fi
}

# Run main function with all arguments
main "$@"