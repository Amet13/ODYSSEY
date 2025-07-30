#!/bin/bash

# ODYSSEY Release Management Script
# Automates version updates, changelog generation, and release preparation

set -e

# Source common functions
source "$(dirname "$0")/common.sh"

# Configuration
PROJECT_PATH="Config/project.yml"
INFO_PLIST_PATH="Sources/App/Info.plist"
CHANGELOG_PATH="CHANGELOG.md"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <version>"
    echo ""
    echo "Options:"
    echo "  --dry-run     Show what would be done without making changes"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 3.2.0              # Create release v3.2.0"
    echo "  $0 --dry-run 3.2.0    # Preview changes for v3.2.0"
    echo ""
    echo "Version format: MAJOR.MINOR.PATCH (e.g., 3.2.0)"
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_status "error" "Invalid version format. Use MAJOR.MINOR.PATCH (e.g., 3.2.0)"
        exit 1
    fi
}

# Function to extract current version from project.yml
get_current_version() {
    # Try to get version from Info.plist first, then fallback to project.yml
    local version
    version=$(grep -A1 "CFBundleShortVersionString" "$INFO_PLIST_PATH" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ -n "$version" ] && [ "$version" != "CFBundleShortVersionString" ]; then
        echo "$version"
    else
        # Fallback to project.yml if Info.plist doesn't have a valid version
        grep "MARKETING_VERSION:" "$PROJECT_PATH" | sed 's/.*MARKETING_VERSION: "\(.*\)"/\1/' | head -1
    fi
}

# Function to update version in project.yml
update_project_version() {
    local version=$1
    local dry_run=$2

    if [ "$dry_run" = "true" ]; then
        print_status "info" "Would update project.yml MARKETING_VERSION to $version"
        print_status "info" "Would update project.yml CFBundleShortVersionString to $version"
    else
        sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$version\"/" "$PROJECT_PATH"
        sed -i '' "s/CFBundleShortVersionString: .*/CFBundleShortVersionString: $version/" "$PROJECT_PATH"
        print_status "success" "Updated project.yml MARKETING_VERSION and CFBundleShortVersionString to $version"
    fi
}

# Function to update version in Info.plist
update_info_plist_version() {
    local version=$1
    local dry_run=$2

    if [ "$dry_run" = "true" ]; then
        print_status "info" "Would update Info.plist CFBundleShortVersionString to $version"
    else
        sed -i '' "s/<string>.*<\/string>.*CFBundleShortVersionString/<string>$version<\/string> <!-- CFBundleShortVersionString/" "$INFO_PLIST_PATH"
        print_status "success" "Updated Info.plist CFBundleShortVersionString to $version"
    fi
}

# Function to update version in AppConstants.swift
update_app_constants_version() {
    local version=$1
    local dry_run=$2
    local app_constants_path="Sources/Utils/AppConstants.swift"

    if [ "$dry_run" = "true" ]; then
        print_status "info" "Would update AppConstants.swift appVersion to $version"
    else
        sed -i '' "s/appVersion = \".*\"/appVersion = \"$version\"/" "$app_constants_path"
        print_status "success" "Updated AppConstants.swift appVersion to $version"
    fi
}

# Function to update version in CLIExportService.swift
update_cli_export_version() {
    local version=$1
    local dry_run=$2
    local cli_export_path="Sources/Services/CLIExportService.swift"

    if [ "$dry_run" = "true" ]; then
        print_status "info" "Would update CLIExportService.swift version to $version"
    else
        sed -i '' "s/version: String = \".*\"/version: String = \"$version\"/" "$cli_export_path"
        print_status "success" "Updated CLIExportService.swift version to $version"
    fi
}

# Function to update changelog
update_changelog() {
    local version=$1
    local dry_run=$2
    local date
    date=$(date +%Y-%m-%d)

    if [ "$dry_run" = "true" ]; then
        print_status "info" "Would add version $version to changelog with date $date"
    else
        # Create temporary changelog entry
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
        sed -i '' "3r /tmp/changelog_entry.md" "$CHANGELOG_PATH"
        rm /tmp/changelog_entry.md

        print_status "success" "Added version $version to changelog"
    fi
}

# Function to generate git commands
generate_git_commands() {
    local version=$1
    local dry_run=$2

    if [ "$dry_run" = "true" ]; then
        print_status "info" "Would run the following git commands:"
        echo "  git add ."
        echo "  git commit -m \"chore: prepare release v$version\""
        echo "  git tag v$version"
        echo "  git push origin main"
        echo "  git push origin v$version"
    else
        print_status "step" "Committing changes..."
        git add .
        git commit -m "chore: prepare release v$version"

        print_status "step" "Creating tag v$version..."
        git tag "v$version"

        print_status "step" "Pushing changes..."
        git push origin main
        git push origin "v$version"

        print_status "success" "Release v$version prepared and pushed"
    fi
}

# Function to validate git status
validate_git_status() {
    if ! git diff-index --quiet HEAD --; then
        print_status "error" "Working directory is not clean. Please commit or stash changes first."
        git status --short
        exit 1
    fi

    if [ "$(git branch --show-current)" != "main" ]; then
        print_status "warning" "Not on main branch. Current branch: $(git branch --show-current)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to show release summary
show_release_summary() {
    local version=$1
    local current_version=$2
    local dry_run=$3

    echo ""
    print_status "step" "Release Summary"
    echo -e "${CYAN}================================${NC}"
    print_status "info" "Current version: $current_version"
    print_status "info" "New version: $version"
    print_status "info" "Mode: $([ "$dry_run" = "true" ] && echo "Dry run" || echo "Live")"
    echo ""
    print_status "info" "Files to be updated:"
    echo "  - $PROJECT_PATH (MARKETING_VERSION and CFBundleShortVersionString)"
    echo "  - $INFO_PLIST_PATH (CFBundleShortVersionString)"
    echo "  - Sources/Utils/AppConstants.swift (appVersion)"
    echo "  - Sources/Services/CLIExportService.swift (version)"
    echo "  - $CHANGELOG_PATH (new version entry)"
    echo ""

    if [ "$dry_run" = "false" ]; then
        print_status "info" "After running this script:"
        echo "  1. CI/CD pipeline will automatically build and release"
        echo "  2. GitHub release will be created with DMG installer"
        echo "  3. Release notes will be generated from changelog"
        echo ""
        print_status "warning" "Make sure to test the build before pushing!"
    fi
}

# Main script logic
main() {
    local dry_run=false
    local version=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
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
                if [ -z "$version" ]; then
                    version=$1
                else
                    print_status "error" "Multiple versions specified"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Check if version was provided
    if [ -z "$version" ]; then
        print_status "error" "Version is required"
        show_usage
        exit 1
    fi

    # Validate version format
    validate_version "$version"

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

    # Show release summary
    show_release_summary "$version" "$current_version" "$dry_run"

    if [ "$dry_run" = "false" ]; then
        read -p "Proceed with release? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "info" "Release cancelled"
            exit 0
        fi
    fi

    # Validate git status
    validate_git_status

    # Update files
    print_status "step" "Updating version files..."
    update_project_version "$version" "$dry_run"
    update_info_plist_version "$version" "$dry_run"
    update_app_constants_version "$version" "$dry_run"
    update_cli_export_version "$version" "$dry_run"
    update_changelog "$version" "$dry_run"

    # Build CLI release version
    if [ "$dry_run" = "false" ]; then
        print_status "step" "Building CLI release version..."

        # Generate Xcode project
        print_status "info" "Generating Xcode project..."
        xcodegen --spec Config/project.yml

        # Build CLI in release configuration
        print_status "info" "Building CLI in release configuration..."
        swift build --product odyssey-cli --configuration release

        # Get CLI path and make executable
        CLI_PATH=$(swift build --product odyssey-cli --configuration release --show-bin-path)/odyssey-cli
        if [ -f "$CLI_PATH" ]; then
            chmod +x "$CLI_PATH"
            print_status "success" "CLI release built successfully at: $CLI_PATH"

            # Test CLI
            print_status "info" "Testing CLI release..."
            if "$CLI_PATH" version >/dev/null 2>&1; then
                print_status "success" "CLI release test passed"
            else
                print_status "warning" "CLI release test failed"
            fi

            # Code sign CLI
            print_status "info" "Code signing CLI release..."
            codesign --remove-signature "$CLI_PATH" 2>/dev/null || true
            codesign --force --deep --sign - "$CLI_PATH"
            print_status "success" "CLI release code signing completed"
        else
            print_status "error" "CLI release build failed"
            exit 1
        fi
    else
        print_status "info" "Would build CLI release version"
    fi

    # Generate git commands
    generate_git_commands "$version" "$dry_run"

    # Final summary
    echo ""
    if [ "$dry_run" = "true" ]; then
        print_status "success" "Dry run completed. Review the changes above."
        print_status "info" "Run without --dry-run to apply changes"
    else
        print_status "success" "Release v$version prepared successfully!"
        print_status "info" "CI/CD pipeline will automatically build and release"
    fi
}

# Run main function with all arguments
main "$@"