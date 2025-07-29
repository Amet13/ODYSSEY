# 🛠️ ODYSSEY Scripts Documentation

This document provides comprehensive information about all the scripts available in the `Scripts/` directory of the ODYSSEY project.

## 📋 Overview

ODYSSEY includes 6 automation scripts to streamline development, building, deployment, and maintenance tasks. All scripts are designed to run on macOS and include proper error handling, logging, and follow bash best practices.

## 📋 Script Quality & Linting

All ODYSSEY scripts follow bash best practices and are validated using multiple linters. These checks are automatically run in the CI pipeline on every commit and pull request.

### 📊 Quality Standards

- **ShellCheck Compliance**: All scripts pass ShellCheck with minimal warnings
- **YAML Linting**: All YAML files validated with yamllint
- **Markdown Linting**: All documentation validated with markdownlint
- **GitHub Actions Linting**: All workflows validated with actionlint
- **Error Handling**: Proper error checking and graceful failure handling
- **Variable Safety**: All variables are properly quoted to prevent word splitting
- **Function Organization**: Clear function structure with descriptive names
- **Documentation**: Comprehensive inline comments and usage examples

### 📊 Linting Results

```bash
# Run all linters
shellcheck Scripts/*.sh
yamllint Config/project.yml .github/workflows/*.yml
markdownlint README.md Documentation/*.md .github/*.md
actionlint .github/workflows/*.yml
```

**Current Status**:

- ✅ **ShellCheck**: All scripts pass with only 1 minor info-level warning (acceptable)
- ✅ **YAML Linting**: All YAML files pass with only style warnings (acceptable)
- ✅ **Markdown Linting**: All documentation passes with only line length warnings (acceptable)
- ✅ **GitHub Actions**: All workflows pass with only ShellCheck warnings in embedded scripts (acceptable)

### 🧹 1. **lint-all.sh** - Comprehensive Linting Script

**Purpose**: Runs all linters for comprehensive code quality validation.

**Features**:

- ✅ Checks linter availability
- ✅ SwiftLint for Swift code quality
- ✅ SwiftFormat for code formatting
- ✅ ShellCheck for bash script quality
- ✅ YAML Linting for configuration files
- ✅ Markdown Linting for documentation
- ✅ GitHub Actions Linting for workflows
- ✅ Comprehensive reporting and summary

**Usage**:

```bash
./Scripts/lint-all.sh
```

**What it does**:

1. Verifies all required linters are installed
2. Runs SwiftLint on all Swift source files
3. Runs SwiftFormat linting check
4. Runs ShellCheck on all bash scripts
5. Runs yamllint on configuration and workflow files
6. Runs markdownlint on all documentation
7. Runs actionlint on GitHub Actions workflows
8. Provides comprehensive summary of all results

**Output**: Detailed linting results for all file types with status summary

**CI Integration**: This script is automatically run in the unified CI/CD pipeline to ensure code quality on every commit and pull request.

### 🔨 2. **build.sh** - Main Build Script

**Purpose**: Primary build script that handles the complete build process for both GUI and CLI versions.

**Features**:

- ✅ Prerequisites checking (Xcode, tools)
- ✅ Xcode project generation
- ✅ Code quality checks (SwiftLint, SwiftFormat)
- ✅ Building both GUI app and CLI tool
- ✅ Code signing
- ✅ App launching and testing
- ✅ Build analysis and reporting

**Usage**:

```bash
./Scripts/build.sh
```

**What it does**:

1. Checks for required tools (Xcode, XcodeGen, SwiftLint, SwiftFormat)
2. Generates Xcode project from `Config/project.yml`
3. Runs code formatting and linting
4. Builds the macOS app and CLI tool
5. Signs the CLI tool
6. Launches the app for testing
7. Provides build summary and next steps

**Output**: Built app in `~/Library/Developer/Xcode/DerivedData/` and CLI tool in `.build/arm64-apple-macosx/release/`

### ⚙️ 3. **setup-dev.sh** - Development Environment Setup

**Purpose**: Automates the complete setup of the development environment for new developers.

**Features**:

- ✅ macOS version validation (requires 15.0+)
- ✅ Homebrew installation and configuration
- ✅ Xcode command line tools installation
- ✅ Development tools installation (XcodeGen, SwiftLint, SwiftFormat, create-dmg, jazzy)
- ✅ Git hooks setup
- ✅ Development environment validation
- ✅ Helpful tips and next steps

**Usage**:

```bash
./Scripts/setup-dev.sh [command]
```

**Commands**:

- `setup` - Complete environment setup (default)
- `validate` - Check if environment is properly configured
- `tools` - Install/update development tools only
- `hooks` - Setup Git pre-commit hooks only
- `tips` - Show development tips

**Example**:

```bash
# Complete setup for new developer
./Scripts/setup-dev.sh setup

# Validate existing environment
./Scripts/setup-dev.sh validate
```

### 🚀 4. **deploy.sh** - Deployment Automation

**Purpose**: Automates the complete deployment process including building, packaging, and releasing.

**Features**:

- ✅ Prerequisites checking
- ✅ Clean build process
- ✅ DMG creation
- ✅ Code signing
- ✅ GitHub release creation
- ✅ Release notes generation
- ✅ Build analysis

**Usage**:

```bash
./Scripts/deploy.sh [command]
```

**Commands**:

- `build` - Build the application only
- `dmg` - Create DMG installer
- `sign` - Code sign the application
- `release` - Create GitHub release
- `clean` - Clean previous builds
- `analyze` - Analyze build artifacts

**Example**:

```bash
# Complete deployment
./Scripts/deploy.sh release

# Just build the app
./Scripts/deploy.sh build

# Create DMG installer
./Scripts/deploy.sh dmg
```

### 📦 5. **create-release.sh** - Release Management

**Purpose**: Manages version updates, changelog generation, and release preparation.

**Features**:

- ✅ Version validation and updating
- ✅ Changelog generation
- ✅ Release notes creation
- ✅ Git tag management
- ✅ Dry-run mode for testing

**Usage**:

```bash
./Scripts/create-release.sh [OPTIONS] <version>
```

**Options**:

- `--dry-run` - Show what would be done without making changes
- `--help` - Show help message

**Examples**:

```bash
# Create release v3.2.0
./Scripts/create-release.sh 3.2.0

# Preview changes for v3.2.0
./Scripts/create-release.sh --dry-run 3.2.0
```

### 📊 6. **logs.sh** - Log Monitoring

**Purpose**: Monitors system logs for ODYSSEY app activity and debugging.

**Features**:

- ✅ Real-time log streaming
- ✅ ODYSSEY-specific log filtering
- ✅ Console.app integration
- ✅ Debug and info level logging

**Usage**:

```bash
./Scripts/logs.sh
```

**What it does**:

1. Monitors Console.app logs for ODYSSEY process
2. Filters for relevant log entries
3. Displays real-time log output
4. Press Ctrl+C to stop monitoring

**Alternative monitoring**:

```bash
# Monitor specific subsystem
log stream --predicate 'subsystem == "com.odyssey.app"' --info --debug

# Monitor all ODYSSEY processes
log stream --predicate 'process == "ODYSSEY"' --info --debug
```

## 🚀 Quick Start Guide

### 👨‍💻 For New Developers

1. **Setup Environment**:

   ```bash
   ./Scripts/setup-dev.sh setup
   ```

2. **Build the Project**:

   ```bash
   ./Scripts/build.sh
   ```

3. **Monitor Logs** (in another terminal):
   ```bash
   ./Scripts/logs.sh
   ```

### 🔧 For Regular Development

1. **Build and Test**:

   ```bash
   ./Scripts/build.sh
   ```

2. **Monitor Logs** (when needed):

   ```bash
   ./Scripts/logs.sh
   ```

3. **Monitor Logs**:
   ```bash
   ./Scripts/logs.sh
   ```

### 📦 For Releases

1. **Create Release**:

   ```bash
   ./Scripts/create-release.sh 3.2.0
   ```

2. **Deploy**:
   ```bash
   ./Scripts/deploy.sh release
   ```

## 🔍 Troubleshooting

### ⚠️ Common Issues

**Build Script Issues**:

- **"Xcode not found"**: Run `./Scripts/setup-dev.sh tools`
- **"SwiftLint errors"**: Run `./Scripts/build.sh` to auto-format
- **"Build fails"**: Check Console.app for detailed error messages

**Setup Script Issues**:

- **"macOS version too old"**: Update to macOS 15.0+
- **"Homebrew installation fails"**: Check internet connection and try again
- **"Xcode tools not found"**: Complete Xcode installation manually

**Deploy Script Issues**:

- **"Code signing fails"**: Check Developer ID certificate
- **"DMG creation fails"**: Install create-dmg: `brew install create-dmg`
- **"GitHub release fails"**: Check GitHub token and permissions

### 🆘 Getting Help

1. **Check Script Help**:

   ```bash
   ./Scripts/setup-dev.sh --help
   ./Scripts/deploy.sh --help
   ./Scripts/create-release.sh --help
   ```

2. **Monitor Logs**:

   ```bash
   ./Scripts/logs.sh
   ```

3. **Validate Environment**:
   ```bash
   ./Scripts/setup-dev.sh validate
   ```

## 📚 Related Documentation

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Development workflow and guidelines
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[CLI.md](CLI.md)** - Command-line interface documentation
- **[USER_GUIDE.md](USER_GUIDE.md)** - User guide for the application

## 🎯 Best Practices

### 📋 Script Usage

1. **Always run from project root**: All scripts expect to be run from the ODYSSEY directory
2. **Check prerequisites**: Use `./Scripts/setup-dev.sh validate` to check your environment
3. **Monitor logs**: Use `./Scripts/logs.sh` during development and testing
4. **Use dry-run**: Test release scripts with `--dry-run` before actual releases

### ⚙️ Linting Configuration

The project includes configuration files to ignore acceptable warnings:

- **`.swiftlint.yml`**: SwiftLint configuration with relaxed rules for complex automation code
- **`.markdownlint.json`**: Markdown linting configuration that ignores acceptable documentation warnings
- **`.actionlintrc`**: GitHub Actions linting configuration that ignores acceptable ShellCheck warnings
- **`.swiftformat`**: SwiftFormat configuration for consistent code formatting

These configurations ensure that linting focuses on critical issues while ignoring acceptable warnings for:

- Complex automation logic (cyclomatic complexity)
- Documentation formatting (line length, HTML usage)
- CI/CD script warnings (ShellCheck in embedded scripts)
- Style preferences (opening brace spacing, trailing commas)

### 🔄 CI/CD Integration

The GitHub Actions pipeline (`.github/workflows/pipeline.yml`) automatically uses these configuration files:

- **SwiftLint**: Uses `.swiftlint.yml` configuration
- **Markdown Linting**: Uses `.markdownlint.json` configuration
- **GitHub Actions Linting**: Uses `.actionlintrc` configuration (clean output)
- **YAML Linting**: Uses `.yamllint` configuration

This ensures that CI/CD builds won't fail due to acceptable warnings, while still catching critical issues.

### 🔧 Development Workflow

1. **Setup**: `./Scripts/setup-dev.sh setup`
2. **Build**: `./Scripts/build.sh`
3. **Develop**: Make changes, test with logs
4. **Monitor**: Use `./Scripts/logs.sh` for debugging
5. **Release**: Use `./Scripts/create-release.sh` and `./Scripts/deploy.sh`

### 🔧 Maintenance

- **Regular validation**: Run `./Scripts/setup-dev.sh validate` periodically
- **Update tools**: Use `./Scripts/setup-dev.sh tools` to update development tools
- **Clean builds**: Use `./Scripts/deploy.sh clean` when experiencing build issues

## 📝 Script Maintenance

### ➕ Adding New Scripts

When adding new scripts:

1. **Follow naming convention**: Use descriptive names with `.sh` extension
2. **Include header**: Add comprehensive header with purpose and usage
3. **Add error handling**: Use `set -e` and proper error messages
4. **Add logging**: Use colored output functions for consistency
5. **Update documentation**: Add the script to this documentation

### 📋 Script Standards

All scripts should:

- ✅ Include proper shebang (`#!/bin/bash`)
- ✅ Use `set -e` for error handling
- ✅ Include colored logging functions
- ✅ Validate prerequisites
- ✅ Provide help/usage information
- ✅ Handle errors gracefully
- ✅ Include comprehensive comments

## 🎉 Conclusion

These scripts provide a complete automation suite for ODYSSEY development, building, and deployment. They ensure consistent processes across the development team and reduce manual errors.

For questions or issues with any script, check the troubleshooting section or refer to the individual script help commands.
