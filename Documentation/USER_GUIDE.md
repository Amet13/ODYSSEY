# ODYSSEY User Guide

**Ottawa Drop-in Your Sports & Schedule Easily Yourself**

A comprehensive guide to using ODYSSEY for automated sports reservation booking.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Settings](#settings)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

## 🚀 Getting Started

### What is ODYSSEY?

ODYSSEY (Ottawa Drop-in Your Sports & Schedule Easily Yourself) is an automated sports reservation booking application designed specifically for Ottawa Recreation facilities. It helps you secure your preferred time slots without the hassle of manual booking.

### Prerequisites

- macOS 15.0 or later
- Internet connection
- Valid Ottawa Recreation account (if required by your facility)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   ```

2. **Build the application**

   ```bash
   ./Scripts/build.sh
   ```

3. **Launch ODYSSEY**
   - The app will appear in your menu bar
   - Click the ODYSSEY icon to open the main interface

## ⚙️ Configuration

### Step 1: Configure Your Settings

1. **Open Settings**

   - Click the ODYSSEY icon in your menu bar
   - Click the "Settings" button at the bottom

2. **Enter Contact Information**

   - **Name**: Your full name as it appears on your ID
   - **Phone Number**: 10-digit phone number (no dashes or spaces)
   - **Email Address**: Your email address for verification codes

3. **Configure Email Settings**

   - **Email Provider**: Select Gmail or IMAP
   - **IMAP Server**: Automatically filled for Gmail, or enter your server
   - **Password**:
     - For Gmail: Use an App Password (not your regular password)
     - For other providers: Use your regular email password

4. **Test Email Connection**
   - Click "Test Email" to verify your settings
   - Wait for the test to complete
   - Fix any errors before proceeding

### Step 2: Add Your First Reservation

1. **Open Configuration**

   - Click the "+" button in the main interface

2. **Enter Facility Information**

   - **Facility URL**: Copy from your Ottawa Recreation facility page
     - Format: `https://reservation.frontdesksuite.ca/rcfs/facility-name`
     - Example: `https://reservation.frontdesksuite.ca/rcfs/richcraft`
   - **Sport Name**: Select from the dropdown or enter manually
   - **Number of People**: How many people in your group

3. **Configure Scheduling**

   - **Add Day**: Click "Add Day" to select your preferred day
   - **Time Slot**: Choose your preferred time
   - **Enable**: Toggle to enable/disable automatic booking

4. **Save Configuration**
   - Click "Save" to create your reservation configuration
   - The configuration will appear in your main list

### Step 3: Monitor and Manage

1. **Check Status**

   - View the status of each configuration in the main interface
   - See when the next automatic run will occur
   - Check the last run status and results

2. **Manual Runs**

   - Click the play button (▶️) to run a configuration immediately
   - Useful for testing or immediate booking

3. **Edit Configurations**
   - Click the pencil icon to edit existing configurations
   - Modify times, sports, or facility settings

## 🎯 Advanced Configuration

### Multiple Reservations

You can create multiple configurations for different sports or facilities:

1. **Different Sports**: Create separate configurations for basketball, volleyball, etc.
2. **Different Times**: Set different time preferences for each sport
3. **Different Facilities**: Configure multiple Ottawa Recreation facilities
4. **Enable/Disable**: Toggle configurations on/off as needed

### Scheduling Details

- **Automatic Timing**: ODYSSEY runs at 6:00 PM, 2 days before your reservation
- **Manual Runs**: Available anytime by clicking the play button
- **Countdown Timer**: Shows time until next automatic run
- **Status Updates**: Real-time updates on booking progress

### Email Integration

- **Automatic Verification**: ODYSSEY handles email verification codes automatically
- **Gmail Support**: Special handling for Gmail accounts with App Passwords
- **IMAP Support**: Works with any IMAP email provider
- **Secure Storage**: Passwords are stored securely on your Mac

## 🔧 Settings

### Contact Information

**Name**

- Use your full legal name
- Must match your Ottawa Recreation account
- No special characters required

**Phone Number**

- Enter exactly 10 digits
- No dashes, spaces, or country codes
- Example: `6135551234`

**Email Address**

- Must be a valid email format
- Used for verification codes
- Should be accessible on your Mac

### Email Configuration

**Gmail Users**

- Enable 2-factor authentication on your Google account
- Generate an App Password:
  1. Go to Google Account settings
  2. Security → 2-Step Verification → App passwords
  3. Generate a password for "Mail"
  4. Use this 16-character password in ODYSSEY

**Other Email Providers**

- Use your regular email password
- Ensure IMAP is enabled in your email settings
- Check with your provider for IMAP settings

### Testing Email

Always test your email configuration:

1. Click "Test Email" in settings
2. Wait for the test to complete
3. Check the result message
4. Fix any errors before using ODYSSEY

## 🔧 Troubleshooting

### Common Issues

**Booking Not Working**

1. **Check Facility URL**

   - Ensure the URL is correct and accessible
   - Format: `https://reservation.frontdesksuite.ca/rcfs/facility-name`
   - Test the URL in your browser

2. **Verify Contact Information**

   - Name matches your Ottawa Recreation account
   - Phone number is exactly 10 digits
   - Email address is valid and accessible

3. **Check Sport Name**

   - Must match exactly what's on the website
   - Check for typos or extra spaces
   - Use the dropdown if available

4. **Review Logs**
   - Check Console.app → search for "ODYSSEY"
   - Look for error messages or warnings
   - Contact support with specific error details

**Email Verification Failing**

1. **Gmail Users**

   - Use an App Password, not your regular password
   - Enable 2-factor authentication
   - Generate a new App Password if needed

2. **Other Providers**

   - Enable IMAP in your email settings
   - Check server settings (usually `mail.yourprovider.com`)
   - Verify your password is correct

3. **Test Email Connection**
   - Use the "Test Email" button in settings
   - Check for specific error messages
   - Verify IMAP is working with other email clients

**App Not Appearing in Menu Bar**

1. **Check if Running**

   - Open Activity Monitor
   - Search for "ODYSSEY"
   - Force quit if multiple instances are running

2. **Restart the App**

   - Quit ODYSSEY completely
   - Rebuild and launch: `./Scripts/build.sh`
   - Check menu bar for the icon

3. **Check Permissions**
   - Ensure no special permissions are required
   - ODYSSEY uses standard app permissions only

### Getting Help

**App Logs**

- Open Console.app
- Search for "ODYSSEY" or "com.odyssey.app"
- Look for error messages or warnings
- Copy relevant log entries for support

**GitHub Issues**

- Report bugs with detailed information
- Include steps to reproduce the issue
- Attach relevant log files
- Provide system information (macOS version, etc.)

**Debug Mode**

- ODYSSEY includes built-in debugging tools
- Use the debug window for troubleshooting
- Monitor automation progress in real-time

## ❓ FAQ

**Q: How often does ODYSSEY run?**
A: ODYSSEY runs automatically at 6:00 PM, 2 days before your reservation. You can also run it manually anytime.

**Q: Can I use ODYSSEY for multiple sports?**
A: Yes! Create separate configurations for each sport, facility, or time preference.

**Q: Is my information secure?**
A: Yes. All data is stored locally on your Mac and never shared with external servers.

**Q: What if the booking fails?**
A: Check the logs for specific error messages. Common issues include incorrect URLs, contact information, or email settings.

**Q: Can I change my reservation times?**
A: Yes. Edit any configuration to change times, sports, or other settings.

**Q: Does ODYSSEY work with all Ottawa Recreation facilities?**
A: ODYSSEY works with facilities using the FrontDesk Suite reservation system. Check your facility's URL format.

**Q: What if I get a verification code?**
A: ODYSSEY handles verification codes automatically. Ensure your email settings are correct.

**Q: Can I disable automatic booking?**
A: Yes. Toggle any configuration on/off using the switch in the main interface.

---

**Need more help?** Check the [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues) or [Contributing Guidelines](CONTRIBUTING.md) for support.
