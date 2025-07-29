#!/bin/bash

# ODYSSEY Development Environment Setup Script
# Sets up the complete development environment for ODYSSEY

set -e

# Source common functions
source "$(dirname "$0")/common.sh"

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
        "markdownlint"
        "actionlint"
        "create-dmg"
        "jazzy"
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
# Runs code quality checks before commits

echo "🔍 Running pre-commit checks..."

# Run SwiftLint
if command -v swiftlint &> /dev/null; then
    swiftlint lint --quiet
    if [ $? -ne 0 ]; then
        echo "❌ SwiftLint found issues. Please fix them before committing."
        exit 1
    fi
    echo "✅ SwiftLint passed"
else
    echo "⚠️ SwiftLint not found, skipping"
fi

# Run SwiftFormat check
if command -v swiftformat &> /dev/null; then
    swiftformat --lint Sources/ --quiet
    if [ $? -ne 0 ]; then
        echo "❌ SwiftFormat found issues. Run 'swiftformat Sources/' to fix."
        exit 1
    fi
    echo "✅ SwiftFormat passed"
else
    echo "⚠️ SwiftFormat not found, skipping"
fi

# Run ShellCheck
if command -v shellcheck &> /dev/null; then
    shellcheck Scripts/*.sh --quiet || echo "⚠️ ShellCheck found issues (mostly acceptable warnings)"
    echo "✅ ShellCheck completed"
else
    echo "⚠️ ShellCheck not found, skipping"
fi

# Run YAML Linting
if command -v yamllint &> /dev/null; then
    yamllint Config/project.yml .github/workflows/*.yml --quiet || echo "⚠️ YAML Linting found issues (mostly style warnings)"
    echo "✅ YAML Linting completed"
else
    echo "⚠️ yamllint not found, skipping"
fi

# Run Markdown Linting
if command -v markdownlint &> /dev/null; then
    markdownlint README.md Documentation/*.md .github/*.md --quiet || echo "⚠️ Markdown Linting found issues (mostly line length warnings)"
    echo "✅ Markdown Linting completed"
else
    echo "⚠️ markdownlint not found, skipping"
fi

echo "✅ Pre-commit checks passed"
EOF

    # Make hook executable
    chmod +x .git/hooks/pre-commit

    log_success "Git hooks configured"
}

# Function to setup development environment
setup_dev_environment() {
    log_info "Setting up development environment..."

    # Create development configuration
    if [ ! -f ".env.development" ]; then
        cat > .env.development << EOF
# ODYSSEY Development Environment Configuration

# Development settings
DEBUG=true
LOG_LEVEL=debug
ENABLE_DEBUG_WINDOW=true

# Automation settings
ENABLE_GOD_MODE=false
AUTOMATION_TIMEOUT=300

# Email settings (for testing)
TEST_EMAIL_ENABLED=true
TEST_EMAIL_SERVER=localhost
TEST_EMAIL_PORT=1025

# WebKit settings
WEBKIT_DEBUG_ENABLED=true
WEBKIT_TIMEOUT=30
EOF
        log_success "Development configuration created"
    fi

    # Create .gitignore additions if needed
    if ! grep -q ".env.development" .gitignore; then
        {
            echo ""
            echo "# Development files"
            echo ".env.development"
            echo "*.dmg"
            echo "RELEASE_NOTES.md"
        } >> .gitignore
        log_success "Gitignore updated"
    fi
}

# Function to validate setup
validate_setup() {
    log_info "Validating development setup..."

    local missing_tools=()

    # Check required tools
    local required_tools=(
        "xcodebuild"
        "swift"
        "xcodegen"
        "swiftlint"
        "swiftformat"
    )

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi

    # Check project structure
    local required_files=(
        "Package.swift"
        "Config/project.yml"
        "Sources/App/ODYSSEYApp.swift"
        "Sources/Views/Main/ContentView.swift"
        ".yamllint"
        ".markdownlint.json"
        "Scripts/lint-all.sh"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Missing required file: $file"
            return 1
        fi
    done

    # Test build
    log_info "Testing build..."
    if ./Scripts/build.sh &> /dev/null; then
        log_success "Build test passed"
    else
        log_error "Build test failed"
        return 1
    fi

    log_success "Development setup validation passed"
    return 0
}

# Function to show development tips
show_dev_tips() {
    echo ""
    echo "🎉 ODYSSEY Development Environment Setup Complete!"
    echo ""
    echo "📚 Development Tips:"
    echo "  • Run './Scripts/build.sh' to build the project"
    echo "  • Run './Scripts/lint-all.sh' to run all linters"
    echo "  • Run './Scripts/deploy.sh' to create releases"
    echo "  • Use 'swiftlint lint' to check Swift code quality"
    echo "  • Use 'swiftformat Sources/' to format Swift code"
    echo "  • Use 'shellcheck Scripts/*.sh' to check bash scripts"
    echo "  • Use 'yamllint Config/project.yml' to check YAML files"
    echo "  • Use 'markdownlint README.md' to check documentation"
    echo ""
    echo "🔧 Useful Commands:"
    echo "  • Build: ./Scripts/build.sh"
    echo "  • Lint all: ./Scripts/lint-all.sh"
    echo "  • Create release: ./Scripts/deploy.sh release"
    echo ""
    echo "📖 Documentation:"
    echo "  • User Guide: Documentation/USER_GUIDE.md"
    echo "  • Development: Documentation/DEVELOPMENT.md"
    echo ""
    echo "🚀 Happy coding!"
}

# Function to show usage
show_usage() {
    echo "ODYSSEY Development Environment Setup"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  setup         Complete development environment setup"
    echo "  validate      Validate the current setup"
    echo "  tools         Install development tools only"
    echo "  hooks         Setup Git hooks only"
    echo "  tips          Show development tips"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 validate"
}

# Main script logic
case "${1:-}" in
    "setup")
        log_info "Setting up ODYSSEY development environment..."
        install_homebrew
        install_xcode_tools
        install_dev_tools
        setup_git_hooks
        setup_dev_environment
        validate_setup
        show_dev_tips
        ;;
    "validate")
        validate_setup
        ;;
    "tools")
        install_homebrew
        install_xcode_tools
        install_dev_tools
        ;;
    "hooks")
        setup_git_hooks
        ;;
    "tips")
        show_dev_tips
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

log_success "Setup completed!" 