# 📦 ODYSSEY Installation Guide

This document contains detailed installation instructions for ODYSSEY.

## 🚀 Quick Installation

### 🖥️ For Users

1. **Download the latest release**

   - Go to [GitHub Releases](https://github.com/Amet13/ODYSSEY/releases)
   - Download `ODYSSEY.dmg` (latest version)

2. **Install the application**

   - Double-click the DMG file to mount it
   - Drag ODYSSEY to your Applications folder
   - Eject the DMG file

3. **First Launch**

   - Right-click ODYSSEY in Applications and select "Open"
   - Click "Open" in the security dialog that appears
   - The app will appear in your menu bar (not Dock)

4. **Configure your settings**
   - Click the ODYSSEY icon in the menu bar
   - Go to Settings and configure your email and reservation preferences

### 💻 For CLI Users

1. **Download the CLI binary**

   - Go to [GitHub Releases](https://github.com/Amet13/ODYSSEY/releases)
   - Download `odyssey-cli` (latest version)

2. **Make it executable**

   ```bash
   chmod +x odyssey-cli
   ```

3. **Export configuration from GUI**

   - Open the GUI app
   - Go to Settings → Export
   - Copy the export token

4. **Set up environment variable**

   ```bash
   export ODYSSEY_EXPORT_TOKEN="your_export_token_here"
   ```

5. **Test the CLI**
   ```bash
   ./odyssey-cli configs
   ```

## 🔧 Development Installation

### 📋 Prerequisites

- **macOS 15.0 or later**
- **Xcode 16.0 or later**
- **Swift 6.1 or later**
- **Homebrew** (for installing development dependencies)

### ⚙️ Setup Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   ```

2. **Install development dependencies**

   ```bash
   ./Scripts/setup-dev.sh
   ```

3. **Build the project**

   ```bash
   ./Scripts/build.sh
   ```

4. **Open in Xcode**
   ```bash
   open Config/ODYSSEY.xcodeproj
   ```

## 🔧 Troubleshooting

### ⚠️ Common Installation Issues

- **"App is damaged" error**: This is normal for apps not from the App Store. Right-click and select "Open" instead of double-clicking.

- **"macOS version too old"**: Update to macOS 15.0 or later.

- **"Cannot be opened because it is from an unidentified developer"**:

  1. Right-click the app
  2. Select "Open" from the context menu
  3. Click "Open" in the security dialog

- **CLI not working**:
  1. Ensure you have an export token from the GUI app
  2. Check that the CLI is executable: `chmod +x odyssey-cli`
  3. Verify your export token: `./odyssey-cli configs`

### 🔧 Development Issues

- **Build failures**: Run `./Scripts/build.sh` to check for issues
- **Linting errors**: Run `./Scripts/lint-all.sh` to identify and fix issues
- **Dependency issues**: Run `brew update && brew upgrade` to update tools

## 📋 Next Steps

After installation:

1. **Configure your settings** in the GUI app
2. **Test email connection** in Settings
3. **Add your first reservation configuration**
4. **Test the automation** with a manual run

For more detailed information, see:

- [USER_GUIDE.md](USER_GUIDE.md) - Complete user guide
- [CLI.md](CLI.md) - CLI documentation
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
