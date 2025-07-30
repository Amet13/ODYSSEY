#!/bin/bash

# ODYSSEY Changelog Generation Script
# Generates changelog from git commits for releases

set -e

# Source common functions
source "$(dirname "$0")/common.sh"

# Check if we're in the ODYSSEY directory
if [ ! -f "Package.swift" ] || [ ! -d "Sources" ]; then
    log_error "This script must be run from the ODYSSEY project root"
    exit 1
fi

# Function to generate changelog
generate_changelog() {
    log_info "📝 Generating commit-based changelog..."

    # Extract version from tag or use current tag
    local version="${GITHUB_REF#refs/tags/}"
    version="${version#v}"

    # Get previous tag
    local previous_tag="$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || echo "")"

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

    log_success "✅ Commit-based changelog generated"
}

# Main execution
generate_changelog 