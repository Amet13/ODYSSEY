# ODYSSEY Localization Checklist

This checklist ensures every new or changed UI string in ODYSSEY is always fully localized (including French).

---

## 📝 ODYSSEY Localization Checklist

### 1. **Wrap All User-Facing Strings**

- **Always** use:
  ```swift
  userSettingsManager.userSettings.localized("Your String Here")
  ```
  for every `Text`, `Button`, `alert`, `.help`, etc.

---

### 2. **Add to Localization Dictionaries**

- In `Sources/Models/UserSettings.swift`, find the `englishLocalizations` and `frenchLocalizations` dictionaries.
- **Add your new string** to both, using the _exact same key_.

**Example:**

```swift
private var englishLocalizations: [String: String] {
    [
        // ...existing...
        "Book Now": "Book Now", // <-- Add here
    ]
}

private var frenchLocalizations: [String: String] {
    [
        // ...existing...
        "Book Now": "Réserver maintenant", // <-- Add here
    ]
}
```

---

### 3. **Test in Both Languages**

- Switch the app language in the settings.
- Confirm your new/changed string appears correctly in both English and French.

---

## 🏷️ **Template for Adding a New Localized String**

1. **In your SwiftUI view:**

   ```swift
   Text(userSettingsManager.userSettings.localized("Book Now"))
   ```

2. **In `UserSettings.swift`:**
   ```swift
   // English
   "Book Now": "Book Now",
   // French
   "Book Now": "Réserver maintenant",
   ```

---

## ✅ **Quick Review Before Committing**

- [ ] All new UI strings use `.localized("..." )`
- [ ] Both English and French entries are present in the dictionaries
- [ ] App tested in both languages

---

**If you follow this checklist, your app will always be fully localized and ready for French users!**
