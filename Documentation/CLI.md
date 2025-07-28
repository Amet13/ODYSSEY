# ODYSSEY CLI Documentation

The ODYSSEY Command Line Interface (CLI) provides remote automation capabilities for running reservations without the GUI, perfect for CLI pipelines and server environments.

## 🎯 Overview

ODYSSEY is a **dual-interface application**:

- **🖥️ GUI Version**: Native macOS menu bar app with SwiftUI interface
- **💻 CLI Version**: Command-line interface for remote automation

Both versions use the same powerful WebKit automation engine, ensuring consistent behavior and reliability.

## 🚀 Quick Start

### Prerequisites

- macOS 15 or later
- Swift 6.1 or later
- Xcode Command Line Tools

### Installation

#### Option 1: Download Pre-built Binary (Recommended)

```bash
# Download from GitHub releases
# Make executable
chmod +x odyssey-cli

# Test the CLI
./odyssey-cli version
```

#### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/Amet13/ODYSSEY.git
cd ODYSSEY

# Build the CLI
swift build --product odyssey-cli
```

### Basic Usage

```bash
# Set your export token
export ODYSSEY_EXPORT_TOKEN="<exported_token>"

# Run all enabled configurations
./odyssey-cli run
```

## 📋 Environment Variables

| Variable               | Required | Default | Description                                                  |
| ---------------------- | -------- | ------- | ------------------------------------------------------------ |
| `ODYSSEY_EXPORT_TOKEN` | ✅ Yes   | -       | Export token from GUI containing configurations and settings |

### Example Environment Setup

```bash
# Required: Your export token from the GUI
export ODYSSEY_EXPORT_TOKEN="<exported_token>"

# CLI always runs in headless mode (no browser window)
```

## 🛠️ Commands

### `run [--now] [--prior <days>]`

Run real reservations for configurations scheduled N days before reservation day using the same automation engine as the GUI app.

```bash
# Run configurations at scheduled time (6:00 PM, 2 days before reservation)
./odyssey-cli run

# Run configurations immediately (ignore time checks)
./odyssey-cli run --now

# Run 3 days before reservation (instead of default 2)
./odyssey-cli run --prior 3

# Run 1 day before reservation
./odyssey-cli run --prior 1
```

**Features:**

- ✅ **Real Automation**: Uses the same WebKit automation as the GUI app
- ✅ **Parallel Execution**: Runs multiple reservations simultaneously using God Mode
- ✅ **Headless Mode**: Always runs without browser window (perfect for CI/CD)
- ✅ **Progress Tracking**: Shows real-time progress and status updates
- ✅ **Error Handling**: Displays detailed error messages if reservation fails
- ✅ **Timeout Protection**: 5-minute timeout to prevent hanging

### `configs`

List all available configurations from the export token.

```bash
./odyssey-cli configs
```

**Output:**

```
📋 Available Configurations:
==================================================
1. ✅ Mintobarrhaven - Volleyball - adult
   **Sport**: Volleyball
   **Facility**: Mintobarrhaven
   **People**: 6
   **Time Slots**:
     Mon: 7:00 PM, 8:00 PM
     Wed: 6:00 PM, 7:00 PM

2. ✅ Richcraftkanata - Volleyball - adult
   **Sport**: Volleyball
   **Facility**: Richcraftkanata
   **People**: 4
   **Time Slots**:
     Tue: 6:30 PM
     Thu: 7:30 PM
```

### `settings [--unmask]`

Show user settings from export token.

```bash
# Show masked settings (default)
./odyssey-cli settings

# Show unmasked settings (for debugging)
./odyssey-cli settings --unmask
```

**Output:**

```
📋 User Settings:
==============================
**Name**: John Doe
**Phone**: ***123
**Email**: ***@gmail.com
**IMAP Password**: ***
**IMAP Server**: imap.gmail.com
```

### `help`

Show CLI help and usage information.

```bash
./odyssey-cli help
```

### `version`

Show CLI version information.

```bash
./odyssey-cli version
```

## 🔧 Export Token Details

The export token is a compressed, base64-encoded configuration optimized for CLI automation. It contains only essential data:

### ✅ Included Data:

- **User Settings**: Name, phone, email credentials, IMAP server (email provider excluded)
- **Selected Configurations**: All reservation configurations chosen for export
- **Export Metadata**: Version, export date, unique ID

### ❌ Excluded Data (for CLI efficiency):

- **Language Settings**: Not needed for automation
- **Fixed Timing**: CLI uses fixed 6:00 PM execution time
- **Email Provider**: Redundant since both IMAP and Gmail use IMAP protocol
- **UI Preferences**: Browser window settings, debug preferences
- **Timezone**: Hardcoded to America/Toronto (Ottawa facilities)
- **Timeout Settings**: Hardcoded to optimal values for automation

This optimization results in smaller, more focused export tokens that are perfect for CI/CD environments.

## 🧪 Verifying Your Configuration

### Step 1: Generate Export Token

1. Open the ODYSSEY GUI app
2. Click "Export" in the main view
3. Select the configurations you want to export
4. Click "Export Token"
5. The token will be copied to your clipboard

<div align="center">
  <img src="../Images/export.png" width="300">
</div>

### Step 2: Set Environment Variable

```bash
export ODYSSEY_EXPORT_TOKEN="<exported_token>"
```

### Step 3: Verify the Configuration

```bash
# List available configurations
./odyssey-cli configs

# Show user settings
./odyssey-cli settings

# Run all configurations
./odyssey-cli run
```

## 🔄 CLI Integration

### GitHub Actions Integration

The CLI can be integrated into GitHub Actions for automated reservation booking.

#### Step 1: Fork the Repository

1. **Fork ODYSSEY**: Go to [https://github.com/Amet13/ODYSSEY](https://github.com/Amet13/ODYSSEY) and click "Fork"
2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ODYSSEY.git
   cd ODYSSEY
   ```

#### Step 2: Add GitHub Secret

1. **Go to your fork**: Navigate to your forked repository on GitHub
2. **Settings**: Click on "Settings" tab
3. **Secrets**: Click on "Secrets and variables" → "Actions"
4. **New repository secret**: Click "New repository secret"
5. **Add secret**:
   - **Name**: `ODYSSEY_EXPORT_TOKEN`
   - **Value**: Your exported token from the GUI app
6. **Save**: Click "Add secret"

#### Step 3: Use the Workflow

The workflow file is already included in the repository. It will automatically:

- Download the latest CLI from releases
- Run reservations using your export token
- Upload logs for debugging

#### Workflow Example

```yaml
name: ODYSSEY Reservation Automation

on:
  schedule:
    - cron: "0 18 * * *" # 6:00 PM daily
  workflow_dispatch: # Allow manual runs

jobs:
  run-reservations:
    runs-on: macos-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download ODYSSEY CLI
        run: |
          # Download latest CLI from releases
          curl -L -o odyssey-cli "https://github.com/Amet13/ODYSSEY/releases/latest/download/odyssey-cli-$(curl -s https://api.github.com/repos/Amet13/ODYSSEY/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)"
          chmod +x odyssey-cli

      - name: Run Reservations
        run: ./odyssey-cli run
        env:
          ODYSSEY_EXPORT_TOKEN: ${{ secrets.ODYSSEY_EXPORT_TOKEN }}

      - name: Upload Logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: odyssey-logs
          path: |
            ~/.odyssey-cli/
            *.log
```

### Cron Job (macOS)

```bash
#!/bin/bash
# /etc/cron.d/odyssey-reservations

# Set environment variables
export ODYSSEY_EXPORT_TOKEN="<exported_token>"

# Change to ODYSSEY directory
cd /path/to/ODYSSEY

# Run reservations
./odyssey-cli run >> /var/log/odyssey.log 2>&1
```

## 🔍 Troubleshooting

### Common Issues

#### Token Decoding Fails

```bash
# Verify token format
./odyssey-cli configs
```

#### Configuration Not Found

```bash
# List all configurations
./odyssey-cli configs

# Check configuration name exactly
./odyssey-cli configs | grep -A 5 "Selected Configurations"
```

#### WebKit Issues

```bash
# CLI always runs in headless mode
# Check system logs for WebKit errors
log show --predicate 'subsystem == "com.odyssey.cli"' --last 1h
```

## 📊 Token Decoding Tools

### CLI Tool

```bash
./odyssey-cli configs
```

## 🔒 Security

- Export tokens contain sensitive information (email credentials, phone numbers)
- Store tokens securely in CLI secrets
- Never commit tokens to version control
- Use environment variables for token storage
- Tokens are base64-encoded and LZFSE-compressed for efficiency

## 🖥️ Remote Server Deployment

### Server Requirements

The CLI uses WebKit which requires macOS and a graphical environment. For remote server deployment:

#### macOS Servers (Recommended)

```bash
# macOS servers with GUI capabilities work out of the box
# For headless macOS servers, use Screen Sharing or VNC
./odyssey-cli run
```

### Important Notes

- **Linux servers are not supported** due to WebKit dependencies
- **Only macOS servers** with GUI capabilities are supported
- **CI/CD pipelines** should use macOS runners exclusively
- **Virtual displays** are not needed on macOS servers

## 📝 Examples

### Complete Workflow

```bash
# 1. Download CLI from releases
# chmod +x odyssey-cli

# 2. Set environment variables
export ODYSSEY_EXPORT_TOKEN="<exported_token>"

# 3. Verify token contents
./odyssey-cli configs

# 4. Show user settings
./odyssey-cli settings

# 5. Run all configurations
./odyssey-cli run
```

### Automated Script

```bash
#!/bin/bash
# run-odyssey.sh

set -e

# Configuration
export ODYSSEY_EXPORT_TOKEN="<exported_token>"

# Download CLI
echo "📥 Downloading ODYSSEY CLI..."
curl -L -o odyssey-cli "https://github.com/Amet13/ODYSSEY/releases/latest/download/odyssey-cli-$(curl -s https://api.github.com/repos/Amet13/ODYSSEY/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)"
chmod +x odyssey-cli

# Verify token
echo "🔍 Verifying export token..."
./odyssey-cli configs

# Run reservations
echo "🚀 Running reservations..."
./odyssey-cli run

echo "✅ ODYSSEY automation completed!"
```

## 🤝 Support

- [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
- [Development Documentation](DEVELOPMENT.md)
- [Contributing Guidelines](CONTRIBUTING.md)
