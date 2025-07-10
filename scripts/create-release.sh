#!/bin/bash

# ORRMAT Release Script
# This script helps create new releases with proper versioning

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to show help
show_help() {
    echo "ORRMAT Release Script"
    echo ""
    echo "Usage: $0 [options] <version>"
    echo ""
    echo "Options:"
    echo "  --help      Show this help message"
    echo "  --dry-run   Show what would be done without executing"
    echo ""
    echo "Examples:"
    echo "  $0 1.0.0              # Create release v1.0.0"
    echo "  $0 --dry-run 1.1.0    # Preview release v1.1.0"
    echo ""
    echo "Version format: X.Y.Z (e.g., 1.0.0, 2.1.3)"
}

# Parse command line arguments
DRY_RUN=false
VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$VERSION" ]; then
                VERSION="$1"
            else
                print_error "Multiple versions specified: $VERSION and $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate version
if [ -z "$VERSION" ]; then
    print_error "Version is required"
    show_help
    exit 1
fi

# Check version format (X.Y.Z)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format: $VERSION"
    echo "Version must be in format X.Y.Z (e.g., 1.0.0)"
    exit 1
fi

TAG="v$VERSION"

# Check if tag already exists
if git tag -l "$TAG" | grep -q "$TAG"; then
    print_error "Tag $TAG already exists"
    exit 1
fi

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    print_error "Working directory is not clean. Please commit or stash changes."
    git status --short
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_warning "Not on main branch (currently on $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_status "Creating release $TAG"

if [ "$DRY_RUN" = true ]; then
    print_warning "DRY RUN - No changes will be made"
    echo ""
    echo "Would create:"
    echo "  - Git tag: $TAG"
    echo "  - GitHub release: $TAG"
    echo "  - DMG installer: ORRMAT-$TAG.dmg"
    echo ""
    echo "To create the actual release, run:"
    echo "  $0 $VERSION"
    exit 0
fi

# Update version in project files
print_status "Updating version in project files..."

# Update project.yml version
sed -i '' "s/MARKETING_VERSION: .*/MARKETING_VERSION: $VERSION/" project.yml
sed -i '' "s/CFBundleShortVersionString: .*/CFBundleShortVersionString: $VERSION/" project.yml

# Update Info.plist version
sed -i '' "s/<key>CFBundleShortVersionString<\/key>/<key>CFBundleShortVersionString<\/key>/" ORRMAT/Info.plist
sed -i '' "s/<string>.*<\/string>/<string>$VERSION<\/string>/" ORRMAT/Info.plist

print_success "Version updated to $VERSION"

# Commit version changes
print_status "Committing version changes..."
git add project.yml ORRMAT/Info.plist
git commit -m "Bump version to $VERSION"

# Create and push tag
print_status "Creating tag $TAG..."
git tag -a "$TAG" -m "Release $TAG"

print_status "Pushing changes and tag..."
git push origin main
git push origin "$TAG"

print_success "Release $TAG created successfully!"
echo ""
echo "Next steps:"
echo "1. GitHub Actions will automatically build the release"
echo "2. Check the Actions tab for build progress"
echo "3. Once complete, the release will be available at:"
echo "   https://github.com/Amet13/orrmat/releases/tag/$TAG"
echo ""
echo "Users can download the DMG installer from the release page." 