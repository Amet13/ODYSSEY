# 🛠️ ODYSSEY Scripts

This directory contains various scripts for building, testing, and maintaining the ODYSSEY project.

## 📋 Available Scripts

### 🔨 Build Scripts

#### `build.sh`

The main build script that handles the complete build process.

**Usage:**

```bash
./Scripts/build.sh
```

**Features:**

- ✅ Checks prerequisites (Xcode, SwiftFormat, SwiftLint, Node.js)
- 🔨 Generates Xcode project using XcodeGen
- ⚙️ Runs code quality checks (SwiftFormat, SwiftLint, ESLint)
- 🏗️ Builds the project with Xcode
- 📱 Analyzes the built application
- 🚀 Launches the app in menu bar
- 📊 Provides build summary

**Prerequisites:**

- Xcode 15.0+
- SwiftFormat
- SwiftLint
- Node.js and npm
- XcodeGen

#### `create-release.sh`

Creates a release package with proper code signing and notarization.

**Usage:**

```bash
./Scripts/create-release.sh [version]
```

**Features:**

- 📦 Creates DMG installer
- 🔐 Code signs with Developer ID
- ✅ Notarizes for macOS security
- 🏷️ Tags git repository
- 📝 Updates version numbers
- 🚀 Creates GitHub release

### 🎨 Asset Generation

#### `generate_automation_icons.sh`

Generates automation icons for different sports and activities.

**Usage:**

```bash
./Scripts/generate_automation_icons.sh
```

**Features:**

- 🎨 Creates SVG icons for various sports
- 📐 Generates multiple sizes (16x16 to 512x512)
- 🎯 Optimizes for menu bar display
- 📁 Organizes icons in Assets.xcassets

### 📊 Development Tools

#### `logs.sh`

Quick access to view application logs.

**Usage:**

```bash
./Scripts/logs.sh
```

**Features:**

- 📋 Opens Console.app with ODYSSEY filter
- 🔍 Shows real-time log streaming
- 📊 Displays log statistics

## 🚀 Quick Commands

### Development Workflow

```bash
# Build and run
./Scripts/build.sh

# View logs
./Scripts/logs.sh

# Create release
./Scripts/create-release.sh 1.2.0
```

### Code Quality

```bash
# Format code
swiftformat Sources/

# Lint Swift code
swiftlint lint

# Lint JavaScript code
npm run lint

# Fix JavaScript issues
npm run lint:fix
```

### Project Management

```bash
# Generate Xcode project
xcodegen generate

# Clean build artifacts
xcodebuild clean

# Build for distribution
xcodebuild -configuration Release
```

## ⚙️ Configuration

### Environment Variables

Set these environment variables for release builds:

```bash
export DEVELOPER_ID="Your Developer ID"
export APPLE_ID="your-apple-id@example.com"
export APP_SPECIFIC_PASSWORD="your-app-specific-password"
```

### Build Configuration

The build script supports different configurations:

- **Debug**: Development build with debug symbols
- **Release**: Production build optimized for distribution
- **Development**: Build with additional debugging features

## 🔧 Troubleshooting

### Common Issues

1. **Build Fails**

   - Check Xcode version compatibility
   - Verify all prerequisites are installed
   - Clean build artifacts: `xcodebuild clean`

2. **Code Signing Issues**

   - Ensure Developer ID certificate is installed
   - Check certificate validity in Keychain Access
   - Verify provisioning profiles

3. **Notarization Fails**
   - Check Apple ID credentials
   - Verify app-specific password
   - Ensure app meets notarization requirements

### Debug Mode

Enable debug mode for verbose output:

```bash
DEBUG=1 ./Scripts/build.sh
```

## 📚 Related Documentation

- [Development Guide](../Documentation/DEVELOPMENT.md)
- [User Guide](../Documentation/USER_GUIDE.md)
- [Contributing Guidelines](../Documentation/CONTRIBUTING.md)

## 🤝 Contributing

When adding new scripts:

1. **Follow naming conventions**: Use descriptive names with `.sh` extension
2. **Add documentation**: Update this README with usage instructions
3. **Include error handling**: Add proper error checking and exit codes
4. **Test thoroughly**: Verify scripts work on different macOS versions
5. **Add shebang**: Include `#!/bin/bash` at the top of each script

## 📄 License

These scripts are part of the ODYSSEY project and are licensed under the MIT License.
