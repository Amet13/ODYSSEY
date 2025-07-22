#!/bin/bash

# ODYSSEY Release Management Script
# Automates version updates, changelog generation, and release preparation

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
INFO_PLIST_PATH="Sources/App/Info.plist"
CHANGELOG_PATH="Documentation/CHANGELOG.md"
PACKAGE_PATH="Package.swift"

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
    grep "MARKETING_VERSION:" "$PROJECT_PATH" | sed 's/.*MARKETING_VERSION: "\(.*\)"/\1/'
}

# Function to update version in project.yml
update_project_version() {
    local version=$1
    local dry_run=$2
    
    if [ "$dry_run" = "true" ]; then
        print_status "info" "Would update project.yml MARKETING_VERSION to $version"
    else
        sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$version\"/" "$PROJECT_PATH"
        print_status "success" "Updated project.yml MARKETING_VERSION to $version"
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

# Function to update changelog
update_changelog() {
    local version=$1
    local dry_run=$2
    local date=$(date +%Y-%m-%d)
    
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
    echo "  - $PROJECT_PATH"
    echo "  - $INFO_PLIST_PATH"
    echo "  - $CHANGELOG_PATH"
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
    local current_version=$(get_current_version)
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
    update_changelog "$version" "$dry_run"
    
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