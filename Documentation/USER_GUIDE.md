# 👤 **ODYSSEY User Guide**

## 📦 Installation

1. **Download** the `ODYSSEY.dmg` file from the [latest release](https://github.com/Amet13/ODYSSEY/releases/latest/).
2. **Install:** Open the installer and drag `ODYSSEY.app` to **Applications**. Eject the `.dmg` archive.
3. **Add ODYSSEY to the trust list:** Run `sudo xattr -rd com.apple.quarantine /Applications/ODYSSEY.app` in your terminal.
4. **Launch:** Open the app. You'll see a new "Sports Court" icon in your menu bar.

For CLI installation and setup, see the complete **[CLI documentation](CLI.md)**.

## ⚙️ Configuration

### 🎯 First-time setup

1. **Launch ODYSSEY:** Click the menu bar icon.
2. **Add configuration:** Click the **+** or **Add Configuration** button.
3. **Configure settings:** Set up your contact info and email.
4. **Test email:** Verify your email connection works.

<div align="center">
  <img src="Images/main_empty.png" width="400" alt="Main screen with no configurations">
  <p><em>Main screen when no configurations are added</em></p>
</div>

### ➕ Adding a reservation configuration

1. **Add configuration:** Click the **+** or **Add Configuration** button.
2. **Fill in the required fields:**
   - **Facility URL:** The facility URL in format `https://reservation.frontdesksuite.ca/rcfs/[facility-name]`.
   - **Sport name:** Select the sport.
   - **Number of people:** How many people in your group.
   - **Configuration name:** You can change it if you want.
   - **Time slot:** Select day and time for your reservations.
3. **Add:** Click **Add**.

<div align="center">
  <img src="Images/add_config.png" width="400" alt="Add configuration screen">
  <p><em>Adding a new reservation configuration</em></p>
</div>

### 🔧 Managing configurations

#### ▶️ Run manually

- **Run:** Click the play button to run a configuration immediately.
- **Test:** Useful for testing or immediate bookings.

#### ✅ Enable/disable

- **Toggle:** Use the toggle switch to enable or disable automatic runs (2 days prior at 6 p.m.).
- **Disabled:** Disabled configurations won't run automatically.

#### ✏️ Edit configuration

- **Edit:** Click the pencil icon to edit a configuration.
- **Modify:** All fields can be modified.
- **Save:** Changes are saved immediately.

#### 🗑️ Delete configuration

- **Delete:** Click the trash icon to delete a configuration.
- **Confirm:** You'll be asked to confirm this action to prevent accidental deletion.

<div align="center">
  <img src="Images/main_configs.png" width="400" alt="Main screen with configurations">
  <p><em>Main screen with active configurations</em></p>
</div>

### 📧 Email setup

The app can connect to your email account using IMAP and automatically parse verification codes for approving reservations.

Gmail does not support using your regular password for IMAP. You need to generate an [App Password](https://support.google.com/mail/answer/185833?hl=en) and use it with ODYSSEY.

<div align="center">
  <img src="Images/settings.png" width="400" alt="Settings screen">
  <p><em>Settings screen for email configuration</em></p>
</div>

## 📊 Logs

1. **Open Console.app:** (Applications → Utilities → Console).
2. **Search:** Search for `com.odyssey.app`.
3. **Look for emoji indicators:**
   - 🚀 _Success messages._
   - ⚠️ _Warnings._
   - ❌ _Errors._
   - 🔍 _Debug information._
