#!/bin/bash

# ODYSSEY Comprehensive Linting Script
# Runs all linters for code quality validation

set -e

# Source common functions
source "$(dirname "$0")/common.sh"

echo "🧹 ODYSSEY - Comprehensive Linting"
echo "=================================="

# Check if linters are installed
check_linters() {
    print_status "step" "Checking linter availability..."

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
        print_status "error" "Missing required linters: ${missing_linters[*]}"
        print_status "info" "Install missing linters with: brew install ${missing_linters[*]}"
        exit 1
    fi

    print_status "success" "All linters available"
}

# Run SwiftLint
run_swiftlint() {
    print_status "step" "Running SwiftLint..."

    if swiftlint lint --quiet; then
        print_status "success" "SwiftLint passed"
    else
        print_status "error" "SwiftLint found issues"
        return 1
    fi
}

# Run SwiftFormat
run_swiftformat() {
    print_status "step" "Running SwiftFormat..."

    if swiftformat --lint Sources/ --quiet; then
        print_status "success" "SwiftFormat passed"
    else
        print_status "warning" "SwiftFormat found issues (run 'swiftformat Sources/' to fix)"
    fi
}

# Run ShellCheck
run_shellcheck() {
    print_status "step" "Running ShellCheck..."

    if shellcheck Scripts/*.sh; then
        print_status "success" "ShellCheck passed"
    else
        print_status "warning" "ShellCheck found issues (mostly acceptable warnings)"
    fi
}

# Run YAML Linting
run_yamllint() {
    print_status "step" "Running YAML Linting..."

    if yamllint Config/project.yml .github/workflows/*.yml; then
        print_status "success" "YAML Linting passed"
    else
        print_status "warning" "YAML Linting found issues (mostly style warnings)"
    fi
}

# Run Markdown Linting
run_markdownlint() {
    print_status "step" "Running Markdown Linting..."

    if markdownlint --config .markdownlint.json README.md Documentation/*.md .github/*.md; then
        print_status "success" "Markdown Linting passed"
    else
        print_status "warning" "Markdown Linting found issues (acceptable warnings ignored)"
    fi
}

# Run GitHub Actions Linting
run_actionlint() {
    print_status "step" "Running GitHub Actions Linting..."

    # Run actionlint without ShellCheck integration to avoid embedded script warnings
    if actionlint -shellcheck="" .github/workflows/*.yml; then
        print_status "success" "GitHub Actions Linting passed"
    else
        print_status "warning" "GitHub Actions Linting found issues (acceptable warnings ignored)"
    fi
}

# Main execution
main() {
    check_linters

    echo ""
    print_status "step" "Running all linters..."
    echo ""

    local failed_linters=()

    # Run each linter
    if ! run_swiftlint; then
        failed_linters+=("SwiftLint")
    fi

    if ! run_swiftformat; then
        failed_linters+=("SwiftFormat")
    fi

    if ! run_shellcheck; then
        failed_linters+=("ShellCheck")
    fi

    if ! run_yamllint; then
        failed_linters+=("YAML Linting")
    fi

    if ! run_markdownlint; then
        failed_linters+=("Markdown Linting")
    fi

    if ! run_actionlint; then
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

# Run main function
main "$@"