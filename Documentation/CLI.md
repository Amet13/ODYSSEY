# 💻 ODYSSEY CLI - Command Line Interface

## 📋 Overview

The ODYSSEY CLI provides headless automation capabilities for sports reservation booking. It uses the same WebKit automation engine as the GUI application but runs without a graphical interface, making it perfect for CI/CD pipelines, remote servers, and automated scheduling.

## 🚀 Quick Start

### Prerequisites

- **macOS 15 or later**
- **Same requirements** as the GUI application
- **Export token** from the GUI application

### Installation

1. **Download the CLI** from [GitHub Releases](https://github.com/Amet13/ODYSSEY/releases)
2. **Export your token** from the GUI application
3. **Run reservations**: `./odyssey-cli run`

### Basic Usage

```bash
# Export your token from the GUI application
export ODYSSEY_EXPORT_TOKEN="your_export_token_here"

# Run reservations
./odyssey-cli run

# Show help
./odyssey-cli --help
```

## 📋 Commands

### `run`

Executes the reservation automation process.

```bash
./odyssey-cli run
```

**Environment Variables:**

- `ODYSSEY_EXPORT_TOKEN`: Required. Export token from GUI application

**Features:**

- Headless WebKit automation
- Parallel execution for multiple configurations
- Comprehensive logging
- Error handling and retry logic
- Email verification support

### `--help`

Shows comprehensive help information.

```bash
./odyssey-cli --help
```

## 🔧 Configuration

### Export Token

The CLI requires an export token from the GUI application:

1. **Open the GUI application**
2. **Go to Settings → Export**
3. **Copy the export token**
4. **Set the environment variable**:
   ```bash
   export ODYSSEY_EXPORT_TOKEN="your_token_here"
   ```

### Environment Variables

| Variable               | Required | Description                       |
| ---------------------- | -------- | --------------------------------- |
| `ODYSSEY_EXPORT_TOKEN` | Yes      | Export token from GUI application |

## 🏗️ Architecture

### Shared Core

The CLI uses the same backend services as the GUI application:

- **WebKitService**: Native web automation engine
- **ReservationOrchestrator**: Automation orchestration
- **EmailService**: IMAP integration and verification
- **ConfigurationManager**: Settings and data persistence
- **CentralizedLoggingService**: Unified logging

### Headless Mode

The CLI runs in headless mode by default:

- **No browser windows** displayed
- **Same automation logic** as GUI
- **Parallel execution** for multiple configurations
- **Comprehensive logging** for monitoring

## 🚀 CI/CD Integration

### GitHub Actions

The CLI is integrated into the ODYSSEY GitHub Actions workflow for automated scheduling. The workflow runs daily at 21:53 UTC (5:53 PM EST):

```yaml
# .github/workflows/scheduled-reservations.yml
name: Scheduled Reservations - Automated Booking

on:
  schedule:
    - cron: "53 21 * * *" # 21:53 UTC (5:53pm EST)
  workflow_dispatch: # Allow manual runs

jobs:
  run-reservations:
    runs-on: macos-15
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Xcode version
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: "16.4"

      - name: Run CI pipeline
        run: |
          ./Scripts/odyssey.sh ci

      - name: Download ODYSSEY CLI
        run: |
          curl -L -o odyssey-cli https://github.com/Amet13/ODYSSEY/releases/latest/download/odyssey-cli

      - name: Run Reservations
        run: |
          echo "🚀 Starting ODYSSEY reservation automation..."
          ./odyssey-cli run
        env:
          ODYSSEY_EXPORT_TOKEN: ${{ secrets.ODYSSEY_EXPORT_TOKEN }}
```

### Local Automation

```bash
# Run reservations locally
export ODYSSEY_EXPORT_TOKEN="your_token"
./odyssey-cli run

# Schedule with cron
# Add to crontab: 0 18 * * * /path/to/odyssey-cli run
```

## 📊 Monitoring

### Logs

The CLI provides comprehensive logging:

```bash
# Monitor logs in real-time
log stream --predicate 'process == "odyssey-cli"'

# Or use system logs
log stream --predicate 'process == "odyssey-cli"'
```

### Exit Codes

| Code | Meaning             |
| ---- | ------------------- |
| 0    | Success             |
| 1    | General error       |
| 2    | Configuration error |
| 3    | Network error       |
| 4    | Automation error    |

## 🛡️ Security

### Token Security

- **Export tokens** are required for CLI operation
- **Tokens are sensitive** - keep them secure
- **Use environment variables** for token storage
- **Never commit tokens** to version control

### Local Processing

- **All automation runs locally** on your machine
- **No data transmitted** without consent
- **Secure storage** in macOS Keychain
- **HTTPS connections** only

## 🐛 Troubleshooting

### Common Issues

#### "Export token not found"

```bash
# Set the environment variable
export ODYSSEY_EXPORT_TOKEN="your_token_here"
```

#### "CLI not found"

```bash
# Check if the CLI exists
ls -la odyssey-cli

# Make it executable if needed
chmod +x odyssey-cli
```

#### "Permission denied"

```bash
# Make the CLI executable
chmod +x odyssey-cli
```

#### "Network error"

- Check your internet connection
- Verify the Ottawa Recreation website is accessible
- Check firewall settings

### Debug Mode

```bash
# Run with debug output
./odyssey-cli run --debug

# Monitor system logs
log stream --predicate 'process == "odyssey-cli"'
```

## 📚 Related Documentation

- **[USER_GUIDE.md](USER_GUIDE.md)**: GUI application user guide
- **[DEVELOPMENT.md](DEVELOPMENT.md)**: Complete development guide
- **[README.md](../README.md)**: Project overview and quick start

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Amet13/ODYSSEY/discussions)
- **Documentation**: See the [Documentation](../Documentation/) folder

---

**Happy automating! 🚀**
