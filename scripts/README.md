# ODYSSEY Scripts

This directory contains build and deployment scripts for the ODYSSEY project.

## Available Scripts

### `build.sh`

Builds and launches the ODYSSEY application for development.

**Usage:**

```bash
./Scripts/build.sh
```

**What it does:**

- Generates Xcode project using XcodeGen
- Builds the app in Debug configuration
- **Robustly stops any existing ODYSSEY instances**
- Launches the app automatically
- Shows build status and app size

### `create-release.sh`

Creates a release build with DMG installer.

**Usage:**

```bash
./Scripts/create-release.sh
```

**What it does:**

- Prompts for version number
- Builds the app in Release configuration
- Code signs the application
- Creates a DMG installer
- Provides next steps for GitHub release

### `generate_automation_icons.sh`

Generates icon assets from the SVG logo for the ODYSSEY application.

**Usage:**

```bash
./Scripts/generate_automation_icons.sh
```

**Requirements:**

- `librsvg` (install with `brew install librsvg`)

**What it does:**

- Converts SVG logo to PNG at multiple sizes
- Creates icon set for Xcode
- Generates ICNS file for the app
- Cleans up temporary files

## Prerequisites

Make sure you have the following tools installed:

```bash
# Install XcodeGen
brew install xcodegen

# Install create-dmg (for releases)
brew install create-dmg

# Install librsvg (for icon generation)
brew install librsvg

# Install Xcode Command Line Tools
xcode-select --install
```

## Script Permissions

Make sure the scripts are executable:

```bash
chmod +x Scripts/*.sh
```

## Integration

These scripts are used by:

- **Development workflow** - `build.sh` for local development
- **CI/CD pipeline** - GitHub Actions uses similar build steps
- **Release process** - `create-release.sh` for creating releases
