# ODYSSEY User Guide

## 📖 Table of Contents

1. [Getting Started](#getting-started)
2. [GUI Version Guide](#gui-version-guide)
3. [CLI Version](#cli-version)
4. [Configuration Management](#configuration-management)
5. [Conflict Detection](#conflict-detection)
6. [Email Setup](#email-setup)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Features](#advanced-features)
9. [Security & Privacy](#security--privacy)

## 🚀 Getting Started

### System Requirements

See [REQUIREMENTS.md](REQUIREMENTS.md) for complete system requirements.

### Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed installation instructions.

## 🖥️ GUI Version Guide

### First Time Setup

1. **Launch ODYSSEY** - Click the menu bar icon
2. **Add Configuration** - Click the "+" button
3. **Configure Settings** - Set up your contact info and email
4. **Test Email** - Verify your email connection works
5. **Run Test** - Try a manual run to verify everything works

<div align="center">
  <img src="Images/main_empty.png" width="400" alt="Main screen with no configurations">
  <p><em>Main screen when no configurations are added</em></p>
</div>

### Adding a Reservation Configuration

1. Click **Add Configuration** or the "+" button
2. Fill in the required fields:
   - **Name**: A descriptive name for your reservation
   - **Facility URL**: The Ottawa recreation facility URL
   - **Sport Name**: The sport you want to book
   - **Number of People**: How many people in your group
   - **Time Slots**: Select days and times for your reservations
3. Click **Save**

<div align="center">
  <img src="Images/add_config.png" width="400" alt="Add configuration screen">
  <p><em>Adding a new reservation configuration</em></p>
</div>

### Configuration Details

#### Facility URL Format

```
https://reservation.frontdesksuite.ca/rcfs/[facility-name]
```

**Example**: `https://reservation.frontdesksuite.ca/rcfs/ottawa`

#### Sport Names

Common sport names include:

- Basketball
- Badminton
- Tennis
- Soccer
- Volleyball
- Swimming
- Fitness

#### Time Slots

- Select the day of the week
- Choose the time for your reservation
- You can have multiple configurations for different times

### Managing Configurations

#### Enable/Disable

- Use the toggle switch to enable/disable automatic runs
- Disabled configurations won't run automatically

#### Edit Configuration

- Click the pencil icon to edit a configuration
- All fields can be modified
- Changes are saved immediately

#### Delete Configuration

- Click the trash icon to delete a configuration
- This action cannot be undone

#### Run Manually

- Click the play button to run a configuration immediately
- Useful for testing or immediate bookings

<div align="center">
  <img src="Images/main_configs.png" width="400" alt="Main screen with configurations">
  <p><em>Main screen with active configurations</em></p>
</div>

## 💻 CLI Version

For detailed CLI usage, commands, and advanced features, see **[CLI.md](CLI.md)**.

**Quick Start**:

1. Export configuration from GUI app
2. Set environment variable: `export ODYSSEY_EXPORT_TOKEN="<token>"`
3. Run: `./odyssey-cli run`

## ⚙️ Configuration Management

### Best Practices

1. **Use Descriptive Names**: Name your configurations clearly
2. **Test First**: Always run a manual test before enabling auto-run
3. **Monitor Logs**: Check Console.app for detailed logs
4. **Backup Configurations**: Export your configurations regularly

### Configuration Validation

ODYSSEY automatically validates your configurations:

- ✅ Facility URL format
- ✅ Sport name requirements
- ✅ Time slot validity
- ✅ Contact information completeness

## 🔍 Conflict Detection

ODYSSEY automatically detects potential conflicts:

### Conflict Types

1. **Time Slot Overlaps**: When configurations have overlapping times

### Conflict Severity Levels

- **🔴 Critical**: Must be resolved before saving
- **🟡 Warning**: Should be reviewed
- **🔵 Information**: Informational only

### Resolving Conflicts

1. **Review Conflicts**: Check the conflict details
2. **Modify Configurations**: Adjust times, facilities, or settings
3. **Save Anyway**: If conflicts are acceptable, you can save anyway
4. **Disable Configurations**: Turn off conflicting auto-runs

## 📧 Email Setup

### Gmail Setup (Recommended)

1. **Enable 2-Factor Authentication** on your Google account
2. **Generate App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a password for "ODYSSEY"
3. **Configure in ODYSSEY**:
   - Email: your.email@gmail.com
   - IMAP Server: gmail.com
   - Password: Your 16-character app password

### Other Email Providers

#### Outlook/Hotmail

- IMAP Server: `outlook.office365.com`
- Port: 993 (SSL)

#### Yahoo

- IMAP Server: `imap.mail.yahoo.com`
- Port: 993 (SSL)

#### iCloud

- IMAP Server: `imap.mail.me.com`
- Port: 993 (SSL)

### Testing Email Connection

1. Click **Settings** in ODYSSEY
2. Fill in your email credentials
3. Click **Test Email**
4. Check your email for the test message
5. If successful, your email is properly configured

<div align="center">
  <img src="Images/settings.png" width="400" alt="Settings screen">
  <p><em>Settings screen for email configuration</em></p>
</div>

## 🔧 Troubleshooting

### Common Issues

#### Automation Fails

**Symptoms**: Automation stops or shows errors
**Solutions**:

- Check your internet connection
- Verify the facility URL is correct
- Try running at a different time
- Check Console.app for detailed logs

#### Email Verification Fails

**Symptoms**: No verification emails received
**Solutions**:

- Verify your email credentials
- Check spam/junk folders
- Ensure IMAP is enabled for your email
- For Gmail, use App Password, not regular password

#### App Not Appearing in Menu Bar

**Symptoms**: ODYSSEY icon not visible
**Solutions**:

- Check Applications folder for ODYSSEY
- Restart the app
- Ensure macOS 15+ is installed (see [REQUIREMENTS.md](REQUIREMENTS.md))
- Check System Preferences → Dock & Menu Bar

#### Keychain Errors

**Symptoms**: Credential storage errors
**Solutions**:

- Re-enter credentials in Settings
- Grant Keychain access when prompted
- Restart the app after updating credentials

### Getting Help

1. **Check Logs**: Use Console.app to view detailed logs
2. **GitHub Issues**: Report bugs on [GitHub](https://github.com/Amet13/ODYSSEY/issues)
3. **Documentation**: See [DEVELOPMENT.md](DEVELOPMENT.md) for advanced troubleshooting

## 🚀 Advanced Features

### Custom Autorun Times

- **Default**: 6:00 PM, 2 days before event
- **Custom**: Set your preferred time in Settings
- **Use Case**: When you need different timing for different facilities

### Debug Window

- **Purpose**: Monitor automation in real-time
- **Access**: Enable in Settings → Advanced
- **Use Case**: Troubleshooting automation issues

### Export/Import

- **Purpose**: Backup and share configurations
- **Access**: Settings → Export
- **Use Case**: Moving configurations between devices

## 🔒 Security & Privacy

### Data Protection

- **Local Processing**: All automation runs on your device
- **Secure Storage**: Credentials stored in macOS Keychain
- **No External Data**: No user data sent to external servers
- **HTTPS Only**: All network requests use secure connections

### Privacy Features

- **Masked Logs**: Sensitive data is masked in logs
- **Private Logging**: Email addresses and credentials are private
- **User Consent**: No data collection without explicit consent

### Security Best Practices

1. **Use App Passwords**: For Gmail, use App Passwords, not regular passwords
2. **Regular Updates**: Keep ODYSSEY updated to the latest version
3. **Monitor Logs**: Regularly check Console.app for unusual activity
4. **Export Backups**: Regularly export your configurations

## 📊 Monitoring & Logs

### Viewing Logs

1. Open **Console.app** (Applications → Utilities → Console)
2. Search for `com.odyssey.app`
3. Look for emoji indicators:
   - 🚀 Success messages
   - ⚠️ Warnings
   - ❌ Errors
   - 🔍 Debug information

### Log Levels

- **Info**: General operation messages
- **Warning**: Potential issues
- **Error**: Failed operations
- **Debug**: Detailed technical information

### Log Filtering

```bash
# Filter by subsystem
log stream --predicate 'subsystem == "com.odyssey.app"'

# Filter by category
log stream --predicate 'category == "WebKitService"'

# Filter by level
log stream --predicate 'level >= 2'
```

## 🎯 Tips & Tricks

### Optimization Tips

1. **Run During Off-Peak**: Schedule runs during less busy times
2. **Use Multiple Configurations**: Create separate configs for different times
3. **Monitor Success Rates**: Check logs to optimize timing
4. **Backup Regularly**: Export configurations before major changes

### Best Practices

1. **Test First**: Always test manually before enabling auto-run
2. **Monitor Logs**: Regularly check Console.app for issues
3. **Update Regularly**: Keep ODYSSEY updated
4. **Secure Credentials**: Use App Passwords for email accounts

### Advanced Usage

1. **Multiple Facilities**: Create configurations for different facilities
2. **Time Variations**: Use different times for different sports
3. **Group Bookings**: Coordinate with friends for group reservations
4. **Backup Strategy**: Export configurations regularly

---

**Need Help?** Check the [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues) or see [DEVELOPMENT.md](DEVELOPMENT.md) for advanced troubleshooting.
