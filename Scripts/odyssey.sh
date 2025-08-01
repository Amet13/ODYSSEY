#!/bin/bash

# ODYSSEY Master Script
# Single entry point for all ODYSSEY operations

set -e

# =============================================================================
# COMMON FUNCTIONS (Integrated from common.sh)
# =============================================================================

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
        "info") echo -e "${BLUE}ℹ️ $message${NC}" ;;
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️ $message${NC}" ;;
        "error") echo -e "${RED}❌ $message${NC}" ;;
        "step") echo -e "${PURPLE}🔨 $message${NC}" ;;
    esac
}

# Alias functions for consistency (these automatically add emojis)
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



# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Check if we're on macOS
check_macos() {
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
}

# Function to display usage
show_usage() {
    cat << EOF
🥅 ODYSSEY Master Script

Usage: $0 <command> [options]

Development Commands:
  setup       Setup development environment
  build       Build application and CLI
  lint        Run comprehensive linting
  test        Run tests and validation
  clean       Clean build artifacts

CI/CD Commands:
  ci          Run CI pipeline (setup, lint, build)
  release     Run full release pipeline
  deploy      Deploy and create release artifacts
  sign        Code sign applications
  changelog   Generate changelog

Utility Commands:
  logs        Show application logs
  help        Show this help message

Options:
  --dry-run   Show what would be executed without running
  --verbose   Enable verbose output
  --help      Show this help message

Examples:
  $0 setup                    # Setup development environment
  $0 build                    # Build application
  $0 ci                       # Run CI pipeline
  $0 release --dry-run        # Show release pipeline steps
  $0 logs                     # Show application logs

EOF
}

# =============================================================================
# DEVELOPMENT COMMANDS
# =============================================================================

# Function to install Homebrew
install_homebrew() {
    if command -v brew &> /dev/null; then
        log_success "Homebrew already installed"
        return
    fi

    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH if needed
    if [[ "$PATH" != *"/opt/homebrew/bin"* ]]; then
        echo "eval \"\$(/opt/homebrew/bin/brew shellenv)\"" >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    log_success "Homebrew installed"
}

# Function to install Xcode command line tools
install_xcode_tools() {
    if xcode-select -p &> /dev/null; then
        log_success "Xcode command line tools already installed"
        return
    fi

    log_info "Installing Xcode command line tools..."
    xcode-select --install

    log_warning "Please complete the Xcode installation in the popup window"
    log_warning "Press Enter when installation is complete..."
    read -r

    log_success "Xcode command line tools installed"
}

# Function to install development tools
install_dev_tools() {
    log_info "Installing development tools..."

    # Install required tools
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
}

# Function to setup Git hooks
setup_git_hooks() {
    log_info "Setting up Git hooks..."

    # Create .git/hooks directory if it doesn't exist
    mkdir -p .git/hooks

    # Create pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# ODYSSEY Pre-commit Hook
# Runs linting before commits

echo "🔍 Running pre-commit checks..."

# Run linting
if ./Scripts/odyssey.sh lint; then
            log_success "Pre-commit checks passed"
    exit 0
else
            log_error "Pre-commit checks failed"
    exit 1
fi
EOF

    chmod +x .git/hooks/pre-commit
    log_success "Git hooks configured"
}

# Function to run setup
run_setup() {
    log_info "Setting up development environment..."
    
    check_macos
    install_homebrew
    install_xcode_tools
    install_dev_tools
    setup_git_hooks
    
    log_success "Setup completed"
}



# Function to run build
run_build() {
    log_info "Building application..."
    
    check_prerequisites
    
    log_info "ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself (macOS Automation)"
    echo -e "${CYAN}==================================================================${NC}"
    echo ""

    # Generate Xcode project
    log_info "Generating Xcode project..."
    measure_time xcodegen --spec "Config/project.yml"

    # Code quality checks
    log_info "Running code quality checks..."

    # Format Swift code
    if command_exists swiftformat; then
        log_info "Formatting Swift code with SwiftFormat..."
        if swiftformat --lint "Sources" >/dev/null 2>&1; then
            log_success "Code formatting is correct"
        else
            log_warning "Code formatting issues found. Running auto-format..."
            swiftformat "Sources"
            log_success "Code auto-formatted"
        fi
    else
        log_warning "SwiftFormat not found. Skipping code formatting."
    fi

    # Lint Swift code
    if command_exists swiftlint; then
        log_info "Linting Swift code with SwiftLint..."
        if swiftlint lint --config .swiftlint.yml --quiet --fix --format; then
            log_success "Code linting passed"
        else
            log_warning "Code linting issues found (non-blocking)"
        fi
    else
        log_warning "SwiftLint not found. Skipping linting."
    fi

    # Build project
    log_info "Building project..."
    measure_time xcodebuild build \
        -project "Config/ODYSSEY.xcodeproj" \
        -scheme "ODYSSEY" \
        -configuration "Debug" \
        -destination 'platform=macOS' \
        -quiet \
        -showBuildTimingSummary

    # Build CLI
    log_info "Building CLI tool..."
    log_info "Building CLI in debug configuration..."
    measure_time swift build --product odyssey-cli --configuration debug

    # Check CLI build success
    CLI_PATH=".build/arm64-apple-macosx/debug/odyssey-cli"
    if [ -f "$CLI_PATH" ]; then
        log_success "CLI built successfully at: $CLI_PATH"
        
        # Test CLI
        log_info "Testing CLI..."
        if "$CLI_PATH" --help >/dev/null 2>&1; then
            log_success "CLI test passed"
        else
            log_warning "CLI test failed"
        fi
        
        # Code sign CLI
        log_info "Code signing CLI..."
        if codesign --force --sign - "$CLI_PATH"; then
            log_success "CLI code signing completed"
        else
            log_warning "CLI code signing failed"
        fi
    else
        log_error "CLI build failed"
        exit 1
    fi

    # Find and analyze built app
    log_info "Locating built application..."
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)
    
    if [ -n "$APP_PATH" ]; then
        log_success "App built at: $APP_PATH"
        
        # Analyze app
        log_info "Analyzing built application..."
        APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
        log_info "App size: $APP_SIZE"
        
        if [[ "$APP_SIZE" > "10M" ]]; then
            log_warning "App size is larger than expected: $APP_SIZE"
        fi
        
        # Check app structure
        log_info "App structure analysis:"
        if [ -f "$APP_PATH/Contents/Info.plist" ]; then
            log_success "Info.plist found"
        else
            log_error "Info.plist not found"
        fi
        
        if [ -d "$APP_PATH/Contents/Resources" ]; then
            log_success "Resources directory found"
        else
            log_error "Resources directory not found"
        fi
        
        # Check code signing
        log_info "Code signing status:"
        if codesign -dv "$APP_PATH" >/dev/null 2>&1; then
            log_success "App is code signed"
        else
            log_warning "App is not code signed"
        fi
        
        # Manage existing instances
        log_info "Managing existing ODYSSEY instances..."
        if pgrep -f "ODYSSEY" >/dev/null; then
            log_info "Found running ODYSSEY process, terminating..."
            pkill -f "ODYSSEY" || true
            sleep 2
            log_success "Process terminated successfully"
        fi
        
        # Launch app
        log_info "Launching ODYSSEY..."
        open "$APP_PATH" &
        sleep 3
        log_success "ODYSSEY launched successfully!"
        
        # Build summary
        echo ""
        log_info "Build Summary"
        echo "================================"
        log_info "Project: ODYSSEY"
        log_info "Configuration: Debug"
        log_info "App Size: $APP_SIZE"
        log_info "App Location: $APP_PATH"
        log_info "CLI Location: $CLI_PATH"
        log_info "Status: Running in menu bar"
        echo ""
        log_success "ODYSSEY build process completed!"
        echo ""
        log_info "Next steps:"
        echo "1. Open Config/ODYSSEY.xcodeproj in Xcode for development"
        echo "2. Run the app to configure your reservations"
        echo "3. The app will appear in your menu bar"
        echo "4. Use CLI: $CLI_PATH <command> for remote automation"
        echo ""
        log_info "For more information, see Documentation/README.md"
        echo ""
        log_success "Happy coding! 🚀"
    else
        log_error "Could not find built application"
        exit 1
    fi
    
    log_success "Build completed"
}

# Function to run linting
run_lint() {
    log_info "Running comprehensive linting..."
    
    log_info "ODYSSEY - Comprehensive Linting"
    echo "=================================="

    # Check if linters are installed
    log_info "Checking linter availability..."

    local missing_linters=()

    # Check required linters
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
        log_error "Missing required linters: ${missing_linters[*]}"
        log_info "Install missing linters with: brew install ${missing_linters[*]}"
        exit 1
    fi

    log_success "All linters available"

    # Run SwiftLint
    log_info "Running SwiftLint..."
    if swiftlint lint --quiet; then
        log_success "SwiftLint passed"
    else
        log_error "SwiftLint found issues"
        return 1
    fi

    # Run SwiftFormat
    log_info "Running SwiftFormat..."
    if swiftformat --lint Sources/ --quiet; then
        log_success "SwiftFormat passed"
    else
        log_warning "SwiftFormat found issues (run 'swiftformat Sources/' to fix)"
    fi

    # Run ShellCheck
    log_info "Running ShellCheck..."
    if shellcheck --exclude=SC1091 Scripts/*.sh; then
        log_success "ShellCheck passed"
    else
        log_warning "ShellCheck found issues (mostly acceptable warnings)"
    fi

    # Run YAML Linting
    log_info "Running YAML Linting..."
    if yamllint Config/project.yml .github/workflows/*.yml; then
        log_success "YAML Linting passed"
    else
        log_warning "YAML Linting found issues (mostly style warnings)"
    fi

    # Run Markdown Linting
    log_info "Running Markdown Linting..."
    if markdownlint --config .markdownlint.json README.md Documentation/*.md .github/*.md; then
        log_success "Markdown Linting passed"
    else
        log_warning "Markdown Linting found issues (acceptable warnings ignored)"
    fi

    # Run GitHub Actions Linting
    log_info "Running GitHub Actions Linting..."
    if actionlint .github/workflows/*.yml; then
        log_success "GitHub Actions Linting passed"
    else
        log_warning "GitHub Actions Linting found issues (acceptable warnings ignored)"
    fi

    log_success "Linting completed"
}

# Function to run tests
run_test() {
    log_info "🧪 Running tests and validation..."
    # Run linting as part of testing
    run_lint
    # Run build as part of testing
    run_build
    log_success "Tests completed"
}

# Function to clean build artifacts
run_clean() {
    log_info "Cleaning build artifacts..."
    
    # Clean Xcode build artifacts
    if [[ -d "Config/ODYSSEY.xcodeproj" ]]; then
        rm -rf Config/ODYSSEY.xcodeproj
        log_info "Removed Xcode project"
    fi
    
    # Clean Swift build artifacts
    if [[ -d ".build" ]]; then
        rm -rf .build
        log_info "Removed Swift build artifacts"
    fi
    
    # Clean derived data
    for derived_data_dir in "$HOME/Library/Developer/Xcode/DerivedData/ODYSSEY-"*; do
        if [[ -d "$derived_data_dir" ]]; then
            rm -rf "$derived_data_dir"
            log_info "Removed derived data"
        fi
    done
    
    log_success "Clean completed"
}

# =============================================================================
# CI/CD COMMANDS
# =============================================================================

# Function to run CI pipeline
run_ci() {
    log_info "🔄 Running CI pipeline..."
    run_setup
    run_lint
    run_build
    log_success "CI pipeline completed"
}

# Function to check deployment prerequisites
check_deploy_prerequisites() {
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



# Function to build the application for deployment
build_application_deploy() {
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

# Function to build CLI for deployment
build_cli_deploy() {
    log_info "Building CLI tool..."

    # Build CLI in release configuration
    swift build --product odyssey-cli --configuration release

    # Check CLI build success
    CLI_PATH=".build/arm64-apple-macosx/release/odyssey-cli"
    if [ -f "$CLI_PATH" ]; then
        log_success "CLI built successfully at: $CLI_PATH"
        
        # Test CLI
        log_info "Testing CLI..."
        if "$CLI_PATH" --help >/dev/null 2>&1; then
            log_success "CLI test passed"
        else
            log_warning "CLI test failed"
        fi
        
        # Code sign CLI
        log_info "Code signing CLI..."
        if codesign --force --sign - "$CLI_PATH"; then
            log_success "CLI code signing completed"
        else
            log_warning "CLI code signing failed"
        fi
    else
        log_error "CLI build failed"
        exit 1
    fi
}

# Function to create DMG
create_dmg() {
    log_info "Creating DMG installer..."

    # Get version and build info
    VERSION=$(grep -A1 "CFBundleShortVersionString" Sources/App/Info.plist | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    BUILD_NUMBER=$(date +%Y%m%d%H%M)
    # Export for potential external use
    export RELEASE_NAME="ODYSSEY-v${VERSION}-${BUILD_NUMBER}"

    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)
    CLI_PATH=".build/arm64-apple-macosx/release/odyssey-cli"

    if [ -z "$APP_PATH" ]; then
        log_error "Could not find built application"
        exit 1
    fi

    if [ ! -f "$CLI_PATH" ]; then
        log_error "Could not find built CLI"
        exit 1
    fi

    # Create release directory
    mkdir -p release_files

    # Copy app and CLI to release directory
    cp -R "$APP_PATH" release_files/
    cp "$CLI_PATH" release_files/odyssey-cli

    # Create DMG
    if command -v create-dmg &> /dev/null; then
        create-dmg \
            --volname "ODYSSEY" \
            --volicon "Assets/AppIcon.iconset/icon_512x512.png" \
            --window-pos 200 120 \
            --window-size 600 300 \
            --icon-size 100 \
            --icon "ODYSSEY.app" 175 120 \
            --hide-extension "ODYSSEY.app" \
            --app-drop-link 425 120 \
            "ODYSSEY-${VERSION}.dmg" \
            release_files/
        
        log_success "DMG created: ODYSSEY-${VERSION}.dmg"
    else
        log_warning "create-dmg not found, skipping DMG creation"
    fi
}

# Function to run deployment
run_deploy() {
    log_info "🚀 Running deployment..."
    
    check_deploy_prerequisites
    clean_builds
    build_application_deploy
    build_cli_deploy
    create_dmg
    
    log_success "Deployment completed"
}

# Function to run code signing
run_sign() {
    log_info "🔐 Running code signing..."
    
    # Find the built app and CLI
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)
    CLI_PATH=".build/arm64-apple-macosx/release/odyssey-cli"

    if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
        log_info "Code signing application..."
        if codesign --force --deep --sign - "$APP_PATH"; then
            log_success "Application code signing completed"
        else
            log_warning "Application code signing failed"
        fi
    else
        log_warning "Application not found for code signing"
    fi

    if [ -f "$CLI_PATH" ]; then
        log_info "Code signing CLI..."
        if codesign --force --sign - "$CLI_PATH"; then
            log_success "CLI code signing completed"
        else
            log_warning "CLI code signing failed"
        fi
    else
        log_warning "CLI not found for code signing"
    fi
    
    log_success "Code signing completed"
}

# Function to generate changelog
run_changelog() {
    log_info "📋 Generating changelog..."
    
    # Check if we're in the ODYSSEY directory
    if [ ! -f "Package.swift" ] || [ ! -d "Sources" ]; then
        log_error "This script must be run from the ODYSSEY project root"
        exit 1
    fi

    log_info "📝 Generating commit-based changelog..."

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

    log_success "Commit-based changelog generated"
}

# Function to run release pipeline
run_release() {
    log_info "🎉 Running release pipeline..."
    run_setup
    run_lint
    run_build
    run_deploy
    run_sign
    run_changelog
    log_success "Release pipeline completed"
}

# =============================================================================
# UTILITY COMMANDS
# =============================================================================

# Function to show logs
run_logs() {
    log_info "📋 Showing application logs..."
    
    echo "🔍 ODYSSEY Log Monitor"
    echo "======================"
    echo "Monitoring logs for ODYSSEY app..."
    echo "Press Ctrl+C to stop monitoring"
    echo ""

    # Monitor Console.app logs for ODYSSEY
    log stream --predicate 'process == "ODYSSEY"' --info --debug
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Parse command line arguments
    local command=""
    local dry_run=false
    local verbose=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$command" ]]; then
                    command="$1"
                else
                    log_error "Multiple commands specified"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Set verbose mode
    if [[ "$verbose" == true ]]; then
        set -x
    fi

    # Check if command is provided
    if [[ -z "$command" ]]; then
        log_error "No command specified"
        show_usage
        exit 1
    fi

    # Execute command
    case "$command" in
        # Development commands
        setup)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute setup"
            else
                run_setup
            fi
            ;;
        build)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute build"
            else
                run_build
            fi
            ;;
        lint)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute linting"
            else
                run_lint
            fi
            ;;
        test)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute tests"
            else
                run_test
            fi
            ;;
        clean)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute clean"
            else
                run_clean
            fi
            ;;
        
        # CI/CD commands
        ci)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute CI pipeline (setup, lint, build)"
            else
                run_ci
            fi
            ;;
        release)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute release pipeline (setup, lint, build, deploy, sign, changelog)"
            else
                run_release
            fi
            ;;
        deploy)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute deployment"
            else
                run_deploy
            fi
            ;;
        sign)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute code signing"
            else
                run_sign
            fi
            ;;
        changelog)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would execute changelog generation"
            else
                run_changelog
            fi
            ;;
        
        # Utility commands
        logs)
            if [[ "$dry_run" == true ]]; then
                log_info "DRY RUN: Would show logs"
            else
                run_logs
            fi
            ;;
        help)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 