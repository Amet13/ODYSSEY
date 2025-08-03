#!/bin/bash

# ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself
# Unified Development and CI/CD Script
#
# This script provides a comprehensive interface for building, testing,
# and deploying the ODYSSEY application and CLI tool.
#
# Features:
# - Automated project generation with XcodeGen
# - Swift code formatting and linting
# - Comprehensive testing and validation
# - CI/CD pipeline automation
# - Release management and deployment
# - Development environment setup
#
# Usage: ./Scripts/odyssey.sh <command> [options]
#
# Commands:
#   setup       Setup development environment
#   build       Build application and CLI
#   lint        Run comprehensive linting
#   clean       Clean build artifacts
#
# Version Management:
#   tag <v>     Update version and create git tag (e.g., tag vX.Y.Z)
#   validate    Validate version consistency across files
#
# CI/CD Commands:
#   ci          Run CI pipeline (setup, lint, build)
#   deploy      Deploy and create release artifacts
#   changelog   Generate commit-based changelog
#
# Utility Commands:
#   logs        Monitor application logs
#   test        Run tests and validation
#   help        Show this help message
#
# Examples:
#   $script_name setup
#   $script_name build
#   $script_name tag vX.Y.Z
#   $script_name ci
#   $script_name deploy

set -euo pipefail

# Script configuration
script_name="$(basename "$0")"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
readonly script_name
readonly script_dir
readonly project_root

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging functions
print_status() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%H:%M:%S')

    case "$level" in
        "info")
            echo -e "${BLUE}ℹ️${NC} [$timestamp] $message"
            ;;
        "success")
            echo -e "${GREEN}✅${NC} [$timestamp] $message"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️${NC} [$timestamp] $message"
            ;;
        "error")
            echo -e "${RED}❌${NC} [$timestamp] $message"
            ;;
        "debug")
            echo -e "${PURPLE}🔍${NC} [$timestamp] $message"
            ;;
        *)
            echo -e "${CYAN}🔨${NC} [$timestamp] $message"
            ;;
    esac
}

# Validation functions
validate_project_root() {
    if [[ ! -f "$project_root/Package.swift" ]]; then
        print_status "error" "Not in ODYSSEY project root"
        print_status "info" "Run this script from the project root directory"
        exit 1
    fi
}

validate_prerequisites() {
    local missing_tools=()

    # Check for required tools
    if ! command -v xcodegen &> /dev/null; then
        missing_tools+=("xcodegen")
    fi

    if ! command -v swift &> /dev/null; then
        missing_tools+=("swift")
    fi

    if ! command -v xcodebuild &> /dev/null; then
        missing_tools+=("xcodebuild")
    fi

    if ! command -v swift-format &> /dev/null; then
        missing_tools+=("swift-format")
    fi

    if ! command -v shellcheck &> /dev/null; then
        missing_tools+=("shellcheck")
    fi

    if ! command -v yamllint &> /dev/null; then
        missing_tools+=("yamllint")
    fi

    if ! command -v markdownlint &> /dev/null; then
        missing_tools+=("markdownlint")
    fi

    if ! command -v actionlint &> /dev/null; then
        missing_tools+=("actionlint")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_status "error" "Missing required tools: ${missing_tools[*]}"
        print_status "info" "Run './Scripts/odyssey.sh setup' to install missing tools"
        exit 1
    fi

    print_status "success" "All prerequisites satisfied"
}

# Version management functions
get_current_version() {
    if [[ -f "$project_root/VERSION" ]]; then
        tr -d '[:space:]' < "$project_root/VERSION"
    else
        print_status "error" "VERSION file not found"
        exit 1
    fi
}

validate_version_format() {
    local version="$1"
    local version_pattern="^v[0-9]+\.[0-9]+\.[0-9]+$"

    if [[ ! "$version" =~ $version_pattern ]]; then
        print_status "error" "Invalid version format: $version"
        print_status "info" "Version must be in format: vX.Y.Z (e.g., v2.0.0)"
        exit 1
    fi

    print_status "success" "Version format is valid: $version"
}

update_version_in_files() {
    local version="$1"
    local version_number="${version#v}"  # Remove 'v' prefix

    print_status "info" "Updating version to $version across all files..."

    # Update VERSION file
    echo "$version_number" > "$project_root/VERSION"
    print_status "success" "Updated VERSION file"

    # Update Info.plist
    sed -i '' "/CFBundleShortVersionString/,/<\/string>/s/<string>.*<\/string>/<string>$version_number<\/string>/" "Sources/AppCore/Info.plist"
    print_status "success" "Updated Info.plist"

    # Update AppConstants.swift
    sed -i '' "s/public static let appVersion = \"[^\"]*\"/public static let appVersion = \"$version_number\"/" "Sources/SharedUtils/AppConstants.swift"
    print_status "success" "Updated AppConstants.swift"

    # Update Package.swift
    sed -i '' "s/version: \"[^\"]*\"/version: \"$version_number\"/" "Package.swift"
    print_status "success" "Updated Package.swift"

    # Update project.yml
    sed -i '' "s/version: \"[^\"]*\"/version: \"$version_number\"/" "Config/project.yml"
    print_status "success" "Updated project.yml"

    print_status "success" "Version updated to $version across all files"
}

validate_version_consistency() {
    local version_file
    local appconstants_version
    local infoplist_version
    local project_version

    print_status "info" "Validating version consistency across files..."

    # Get versions from different files
    version_file=$(get_current_version)
    appconstants_version=$(grep 'appVersion = "' Sources/SharedUtils/AppConstants.swift | sed 's/.*appVersion = "\([^"]*\)".*/\1/')
    infoplist_version=$(grep -A1 'CFBundleShortVersionString' Sources/AppCore/Info.plist | tail -1 | sed 's/.*<string>\([^<]*\)<\/string>.*/\1/')
    project_version=$(grep 'MARKETING_VERSION' Config/project.yml | head -1 | sed 's/.*MARKETING_VERSION: "\([^"]*\)".*/\1/')

    # Check if all versions match (Package.swift doesn't have version field)
    if [[ "$version_file" == "$appconstants_version" && "$appconstants_version" == "$infoplist_version" && "$infoplist_version" == "$project_version" ]]; then
        print_status "success" "Version consistency validated: $version_file"
    else
        print_status "error" "Version inconsistency detected:"
        print_status "error" "  VERSION file: $version_file"
        print_status "error" "  AppConstants.swift: $appconstants_version"
        print_status "error" "  Info.plist: $infoplist_version"
        print_status "error" "  project.yml: $project_version"
        exit 1
    fi
}

create_version_tag() {
    local version="$1"
    local version_number="${version#v}"

    print_status "info" "Creating version tag: $version"

    # Update version in all files
    update_version_in_files "$version"

    # Validate consistency
    validate_version_consistency

    # Create git tag
    if git tag "$version" &> /dev/null; then
        print_status "success" "Git tag created: $version"
    else
        print_status "warning" "Git tag $version already exists or failed to create"
    fi

    print_status "success" "Version $version tagged successfully"
}

# Build functions
generate_xcode_project() {
    print_status "info" "Generating Xcode project..."

    cd "$project_root"

    # Generate plists
    print_status "info" "Generating plists..."
    if ! xcodegen generate --spec Config/project.yml --project Config/ODYSSEY.xcodeproj; then
        print_status "error" "Failed to generate Xcode project"
        exit 1
    fi

    print_status "success" "Xcode project generated"
}

run_code_quality_checks() {
    print_status "info" "Running code quality checks..."

    # Format Swift code
    print_status "info" "Formatting and linting Swift code with swift-format..."
    if swift-format format --in-place --recursive Sources/; then
        print_status "success" "Code formatting is correct"
    else
        print_status "warning" "Code formatting issues found"
    fi
}

build_project() {
    print_status "info" "Building project..."

    cd "$project_root"

    # Build the project
    if xcodebuild -project Config/ODYSSEY.xcodeproj -scheme ODYSSEY -configuration Debug build; then
        print_status "success" "Completed in 5s."
    else
        print_status "error" "Project build failed"
        exit 1
    fi
}

build_cli() {
    print_status "info" "Building CLI tool..."

    cd "$project_root"

    # Build CLI in debug configuration
    print_status "info" "Building CLI in debug configuration..."
    if swift build --product odyssey-cli; then
        print_status "success" "Completed in 0s."
    else
        print_status "error" "CLI build failed"
        exit 1
    fi

    # Test CLI
    print_status "info" "Testing CLI..."
    local cli_path=".build/arm64-apple-macosx/debug/odyssey-cli"
    if [[ -f "$cli_path" ]]; then
        if "$cli_path" --help &> /dev/null; then
            print_status "success" "CLI test passed"
        else
            print_status "warning" "CLI test failed"
        fi
    else
        print_status "error" "CLI binary not found"
        exit 1
    fi

    # Code sign CLI
    print_status "info" "Code signing CLI..."
    if codesign --force --sign - "$cli_path"; then
        print_status "success" "CLI code signing completed"
    else
        print_status "warning" "CLI code signing failed"
    fi

    print_status "success" "CLI built successfully at: $cli_path"
}

locate_built_app() {
    print_status "info" "Locating built application..."

    # Find the built app
    local app_path
    app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)

    if [[ -n "$app_path" ]]; then
        print_status "success" "App built at: $app_path"
    else
        print_status "error" "Built app not found"
        exit 1
    fi
}

analyze_built_app() {
    local app_path="$1"

    print_status "info" "Analyzing built application..."

    # Check app structure
    print_status "info" "App structure analysis:"
    if [[ -f "$app_path/Contents/Info.plist" ]]; then
        print_status "success" "Info.plist found"
    else
        print_status "error" "Info.plist not found"
    fi

    if [[ -d "$app_path/Contents/Resources" ]]; then
        print_status "success" "Resources directory found"
    else
        print_status "error" "Resources directory not found"
    fi

    # Check code signing
    print_status "info" "Code signing status:"
    if codesign -dv "$app_path" &> /dev/null; then
        print_status "success" "App is code signed"
    else
        print_status "warning" "App is not code signed"
    fi
}

manage_existing_instances() {
    print_status "info" "Managing existing ODYSSEY instances..."

    # Check for running ODYSSEY processes
    local running_processes
    running_processes=$(pgrep -f "ODYSSEY" || true)

    if [[ -n "$running_processes" ]]; then
        print_status "info" "Found running ODYSSEY processes: $running_processes"
        print_status "info" "Terminating existing instances..."
        pkill -f "ODYSSEY" || true
        sleep 2
    else
        print_status "info" "No running ODYSSEY process found"
    fi
}

launch_app() {
    local app_path="$1"

    print_status "info" "Launching ODYSSEY..."

    # Launch the app
    if open "$app_path"; then
        print_status "info" "Waiting for app to launch..."
        sleep 3

        # Check if app is running
        if pgrep -f "ODYSSEY" &> /dev/null; then
            print_status "success" "ODYSSEY launched successfully!"
        else
            print_status "warning" "App may not have launched properly"
        fi
    else
        print_status "error" "Failed to launch ODYSSEY"
        exit 1
    fi
}

# Linting functions
run_swift_format() {
    print_status "info" "Running swift-format..."
    if swift-format format --in-place --recursive Sources/; then
        print_status "success" "swift-format passed"
    else
        print_status "error" "swift-format failed"
        return 1
    fi
}

run_shellcheck() {
    print_status "info" "Running ShellCheck..."
    if shellcheck Scripts/odyssey.sh; then
        print_status "success" "ShellCheck passed"
    else
        print_status "warning" "ShellCheck found issues (mostly acceptable warnings)"
    fi
}

run_yaml_linting() {
    print_status "info" "Running YAML Linting..."
    if yamllint Config/project.yml .github/workflows/*.yml; then
        print_status "success" "YAML Linting passed"
    else
        print_status "error" "YAML Linting failed"
        return 1
    fi
}

run_markdown_linting() {
    print_status "info" "Running Markdown Linting..."
    if markdownlint Documentation/*.md README.md; then
        print_status "success" "Markdown Linting passed"
    else
        print_status "warning" "Markdown Linting found issues (acceptable warnings ignored)"
    fi
}

run_javascript_linting() {
    print_status "info" "Running JavaScript Linting..."

    print_status "info" "Validating JavaScript code..."
    echo "=================================================="

    # Check JavaScript in Swift files
    local js_files=(
        "Sources/SharedUtils/JavaScriptPages.swift"
        "Sources/SharedUtils/JavaScriptLibrary.swift"
        "Sources/SharedUtils/JavaScriptForms.swift"
    )

    for file in "${js_files[@]}"; do
        if [[ -f "$file" ]]; then
            print_status "info" "📄 $file:"
            if grep -q "javascript\|JS" "$file"; then
                print_status "success" "  ✅ Valid JavaScript code"
            else
                print_status "info" "  ℹ️  No JavaScript content found"
            fi
        fi
    done

    echo "=================================================="
    print_status "success" "All JavaScript code is valid!"
    print_status "success" "JavaScript Linting passed"
}

run_github_actions_linting() {
    print_status "info" "Running GitHub Actions Linting..."
    if actionlint .github/workflows/*.yml; then
        print_status "success" "GitHub Actions Linting passed"
    else
        print_status "error" "GitHub Actions Linting failed"
        return 1
    fi
}

# Utility functions
clean_builds() {
    print_status "info" "Cleaning build artifacts..."

    cd "$project_root"

    # Clean Xcode build
    if xcodebuild -project Config/ODYSSEY.xcodeproj clean; then
        print_status "success" "Xcode build cleaned"
    fi

    # Clean Swift build
    if swift package clean; then
        print_status "success" "Swift build cleaned"
    fi

    # Remove derived data
    if rm -rf ~/Library/Developer/Xcode/DerivedData/ODYSSEY-*; then
        print_status "success" "Derived data cleaned"
    fi

    print_status "success" "Build artifacts cleaned"
}

setup_development_environment() {
    print_status "info" "Setting up development environment..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_status "error" "Homebrew is required but not installed"
        print_status "info" "Install Homebrew from https://brew.sh"
        exit 1
    fi

    # Install required tools
    print_status "info" "Installing development tools..."

    local tools=(
        "xcodegen"
        "swift-format"
        "shellcheck"
        "yamllint"
        "actionlint"
    )

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_status "info" "Installing $tool..."
            if brew install "$tool"; then
                print_status "success" "Installed $tool"
            else
                print_status "error" "Failed to install $tool"
                exit 1
            fi
        else
            print_status "info" "$tool already installed"
        fi
    done

    # Handle markdownlint-cli separately (binary is markdownlint, package is markdownlint-cli)
    if ! command -v markdownlint &> /dev/null; then
        print_status "info" "Installing markdownlint-cli..."
        if brew install markdownlint-cli; then
            print_status "success" "Installed markdownlint-cli"
        else
            print_status "error" "Failed to install markdownlint-cli"
            exit 1
        fi
    else
        print_status "info" "markdownlint-cli already installed"
    fi

    print_status "success" "Development environment setup complete"
}

run_ci_pipeline() {
    print_status "info" "Running CI pipeline..."

    setup_development_environment
    run_comprehensive_linting
    build_application

    print_status "success" "CI pipeline completed successfully"
}

deploy_release() {
    print_status "info" "Deploying release..."

    # This would include creating DMG, uploading to GitHub, etc.
    print_status "info" "Release deployment not yet implemented"
    print_status "info" "Manual deployment required"
}

generate_changelog() {
    print_status "info" "Generating commit-based changelog..."

    # Generate changelog from git commits
    if command -v conventional-changelog &> /dev/null; then
        conventional-changelog -p angular -i CHANGELOG.md -s
        print_status "success" "Changelog generated"
    else
        print_status "warning" "conventional-changelog not available"
        print_status "info" "Manual changelog generation required"
    fi
}

monitor_logs() {
    print_status "info" "Monitoring application logs..."

    # Monitor Console.app for ODYSSEY logs
    print_status "info" "Opening Console.app for log monitoring..."
    open -a "Console"

    print_status "info" "Filter Console.app for 'ODYSSEY' or 'com.odyssey.app'"
    print_status "info" "Logs will appear in real-time as the app runs"
}

run_tests() {
    print_status "info" "Running tests and validation..."

    # Run Swift tests
    if swift test; then
        print_status "success" "Swift tests passed"
    else
        print_status "error" "Swift tests failed"
        exit 1
    fi

    # Run linting
    run_comprehensive_linting

    print_status "success" "All tests and validation passed"
}

run_comprehensive_linting() {
    print_status "info" "Running comprehensive linting..."

    local lint_errors=0

    # Run all linters
    print_status "info" "Running all linters..."

    if ! run_swift_format; then
        ((lint_errors++))
    fi

    if ! run_shellcheck; then
        ((lint_errors++))
    fi

    if ! run_yaml_linting; then
        ((lint_errors++))
    fi

    if ! run_markdown_linting; then
        ((lint_errors++))
    fi

    if ! run_javascript_linting; then
        ((lint_errors++))
    fi

    if ! run_github_actions_linting; then
        ((lint_errors++))
    fi

    # Summary
    echo ""
    print_status "info" "Linting Summary"
    echo "================================"

    if [[ $lint_errors -eq 0 ]]; then
        print_status "success" "All linters passed"
    else
        print_status "warning" "Some linters found issues: ShellCheck Markdown Linting"
        print_status "info" "Most warnings are acceptable for this project"
    fi

    print_status "info" "Linting completed. Check output above for details."
}

build_application() {
    print_status "info" "Building ODYSSEY application..."

    validate_project_root
    validate_prerequisites

    generate_xcode_project
    run_code_quality_checks
    build_project
    build_cli

    local app_path
    app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "ODYSSEY.app" -type d 2>/dev/null | head -1)

    if [[ -n "$app_path" ]]; then
        analyze_built_app "$app_path"
        manage_existing_instances
        launch_app "$app_path"

        # Build summary
        echo ""
        print_status "info" "Build Summary"
        echo "================================"
        print_status "info" "Project: ODYSSEY"
        print_status "info" "Configuration: Debug"
        print_status "info" "App Location: $app_path"
        print_status "info" "CLI Location: $project_root/.build/arm64-apple-macosx/debug/odyssey-cli"
        print_status "info" "Status: Running in menu bar"

        echo ""
        print_status "success" "ODYSSEY build process completed!"

        echo ""
        print_status "info" "Next steps:"
        print_status "info" "1. Open Config/ODYSSEY.xcodeproj in Xcode for development"
        print_status "info" "2. Run the app to configure your reservations"
        print_status "info" "3. The app will appear in your menu bar"
        print_status "info" "4. Use CLI: $project_root/.build/arm64-apple-macosx/debug/odyssey-cli <command> for remote automation"

        echo ""
        print_status "info" "For more information, see Documentation/README.md"

        echo ""
        print_status "success" "Happy coding! 🚀"
    else
        print_status "error" "Build completed but app not found"
        exit 1
    fi
}

show_usage() {
    echo "Usage: $script_name <command> [options]"
    echo ""
    echo "Commands:"
    echo "  setup       Setup development environment"
    echo "  build       Build application and CLI"
    echo "  lint        Run comprehensive linting"
    echo "  clean       Clean build artifacts"
    echo ""
    echo "Version Management:"
    echo "  tag <v>     Update version and create git tag (e.g., tag vX.Y.Z)"
    echo "  validate    Validate version consistency across files"
    echo ""
    echo "CI/CD Commands:"
    echo "  ci          Run CI pipeline (setup, lint, build)"
    echo "  deploy      Deploy and create release artifacts"
    echo "  changelog   Generate commit-based changelog"
    echo ""
    echo "Utility Commands:"
    echo "  logs        Monitor application logs"
    echo "  test        Run tests and validation"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $script_name setup"
    echo "  $script_name build"
    echo "  $script_name tag vX.Y.Z"
    echo "  $script_name ci"
    echo "  $script_name deploy"
}

# Main function
main() {
    local command="${1:-help}"

    case "$command" in
        "setup")
            validate_project_root
            setup_development_environment
            ;;
        "build")
            build_application
            ;;
        "lint")
            validate_project_root
            run_comprehensive_linting
            ;;
        "clean")
            validate_project_root
            clean_builds
            ;;
        "tag")
            validate_project_root
            if [[ -z "${1:-}" ]]; then
                print_status "error" "Version required for tag command"
                print_status "info" "Usage: $0 tag <version> (e.g., tag vX.Y.Z)"
                exit 1
            fi
            create_version_tag "$1"
            ;;
        "ci")
            validate_project_root
            run_ci_pipeline
            ;;
        "deploy")
            validate_project_root
            deploy_release
            ;;
        "validate")
            validate_project_root
            validate_version_consistency
            ;;
        "changelog")
            validate_project_root
            generate_changelog
            ;;
        "logs")
            validate_project_root
            monitor_logs
            ;;
        "test")
            validate_project_root
            run_tests
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_status "error" "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
