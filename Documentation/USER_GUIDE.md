# 👤 ODYSSEY User Guide

## 📦 Installation

- **Download** the `ODYSSEY.dmg` file from the [latest release](https://github.com/Amet13/ODYSSEY/releases/latest/).
- **Install:** Open the installer and drag `ODYSSEY.app` to **Applications**. Eject the `.dmg` archive.
- **Add to the quarantine:** Run in your terminal:

  ```bash
  sudo xattr -rd com.apple.quarantine /Applications/ODYSSEY.app
  ```

- **Launch:** Open the app. You'll see a new icon in your menu bar.

## ⚙️ Configuration

<div align="center">
  <img src="Images/main-screen-empty.png" width="400" alt="Main screen with no configurations">
</div>

### 🎯 First-time Setup

1. **Launch ODYSSEY:** Click the menu bar icon.
2. **Add configuration:** Click the **+** or **Add Configuration** button.
3. **Configure settings:** Set up your contact info and email.
4. **Test email:** Verify your email connection works.
5. **Save the settings.**

#### 📧 Email Setup

The app can connect to your email account using IMAP and automatically parse verification codes for approving reservations.

Gmail does not support using your regular password for IMAP. You need to generate an [App Password](https://support.google.com/mail/answer/185833?hl=en) and use it with ODYSSEY.

<div align="center">
  <img src="Images/settings-screen.png" width="400" alt="Settings screen">
</div>

### ➕ Adding a Reservation Configuration

1. **Add configuration:** Click the **+** or **Add Configuration** button.
2. **Fill in the required fields:**
   - **Facility URL:** The facility URL in format `https://reservation.frontdesksuite.ca/rcfs/[facility-name]`.
   - **Sport name:** Select the sport.
   - **Number of people:** How many people in your group.
   - **Configuration name:** You can change it if you want.
   - **Time slot:** Select day and time for your reservations.
3. **Add:** Click **Add**.

<div align="center">
  <img src="Images/add-configuration-screen.png" width="400" alt="Add configuration screen">
</div>

### 🔧 Managing Configurations

#### ▶️ Run Manually

- **Run:** Click the play button to run a configuration immediately.
- **Test:** Useful for testing or immediate bookings.

#### ✅ Enable/Disable

- **Toggle:** Use the toggle switch to enable or disable automatic runs (2 days prior at 6 p.m.).
- **Disabled:** Disabled configurations won't run automatically.

### 💤 Sleep and Autorun Reliability

- ODYSSEY schedules automatic runs two days prior at 6:00 p.m. If your Mac is sleeping at that time, the run may be missed.
- To ensure reliability, keep your Mac awake around 6:00 p.m. on autorun days. You can use third-party utilities such as [Caffeine](https://www.caffeine-app.net) to temporarily prevent sleep.

#### ✏️ Edit Configuration

- **Edit:** Click the pencil icon to edit a configuration.
- **Modify:** All fields can be modified.
- **Save:** Changes are saved immediately.

#### 🗑️ Delete Configuration

- **Delete:** Click the trash icon to delete a configuration.
- **Confirm:** You'll be asked to confirm this action to prevent accidental deletion.

<div align="center">
  <img src="Images/main-screen-with-configs.png" width="400" alt="Main screen with configurations">
</div>
