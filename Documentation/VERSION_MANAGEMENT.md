# 🏷️ ODYSSEY Version Management

## Overview

ODYSSEY uses a centralized version management system that ensures consistency across all project files. The version is stored in a single `VERSION` file and automatically synchronized across all relevant files.

## 📋 Version Management Commands

### Tag Command

The main version management command is `tag`, which updates the version across all files and creates a git tag.

```bash
./Scripts/odyssey.sh tag <version>
```

**Examples:**
```bash
./Scripts/odyssey.sh tag vX.Y.Z
./Scripts/odyssey.sh tag v1.2.3
./Scripts/odyssey.sh tag v3.0.0-beta.1
```

### Validate Command

Check version consistency across all files:

```bash
./Scripts/odyssey.sh validate
```

## 🔄 How the Tag Command Works

When you run `./Scripts/odyssey.sh tag vX.Y.Z`, the following happens:

1. **Version Validation**: Checks if the version format is valid (MAJOR.MINOR.PATCH)
2. **Git Repository Check**: Ensures you're in a git repository
3. **Uncommitted Changes Check**: Verifies no uncommitted changes exist
4. **Tag Existence Check**: Confirms the tag doesn't already exist
5. **Version Update**: Updates version in all files:
   - `VERSION` file
   - `Sources/AppCore/Info.plist`
   - `Sources/SharedUtils/AppConstants.swift`
   - `Sources/Services/CLIExportService.swift`
   - `Config/project.yml`
6. **Consistency Validation**: Verifies all files have the same version
7. **Git Operations**:
   - Commits version changes
   - Creates annotated git tag
   - Pushes changes and tag to remote

## 📁 Files Updated by Version Management

### Core Version File

- **`VERSION`** - Single source of truth for version

### Application Files

- **`Sources/AppCore/Info.plist`** - macOS app bundle version
- **`Sources/SharedUtils/AppConstants.swift`** - Runtime version constant
- **`Sources/Services/CLIExportService.swift`** - CLI version

### Build Configuration

- **`Config/project.yml`** - XcodeGen project configuration

## 🛡️ Safety Features

### Pre-flight Checks

- ✅ Validates version format (MAJOR.MINOR.PATCH)
- ✅ Ensures git repository exists
- ✅ Checks for uncommitted changes
- ✅ Verifies tag doesn't already exist
- ✅ Validates version consistency after updates

### Error Handling

- ❌ Invalid version format
- ❌ Not in git repository
- ❌ Uncommitted changes present
- ❌ Tag already exists
- ❌ Version inconsistency detected

## 📝 Version Format

### Supported Formats

- **Standard**: `vX.Y.Z` (recommended)
- **Without prefix**: `X.Y.Z` (automatically handled)

### Semantic Versioning

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

## 🔧 Manual Version Updates

If you need to update versions manually:

### Update VERSION File

```bash
echo "X.Y.Z" > VERSION
```

### Update Individual Files

```bash
# Info.plist
sed -i '' "/CFBundleShortVersionString/,/<\/string>/s/<string>.*<\/string>/<string>X.Y.Z<\/string>/" Sources/AppCore/Info.plist

# AppConstants.swift
sed -i '' "s/appVersion = \".*\"/appVersion = \"X.Y.Z\"/" Sources/SharedUtils/AppConstants.swift

# CLIExportService.swift
sed -i '' "s/version: String = \".*\"/version: String = \"X.Y.Z\"/" Sources/Services/CLIExportService.swift

# project.yml
sed -i '' "s/CFBundleShortVersionString: .*/CFBundleShortVersionString: X.Y.Z/" Config/project.yml
```

## 🚀 Best Practices

### Before Creating a Tag

1. **Ensure clean working directory**:

   ```bash
   git status
   ```

2. **Run validation**:

   ```bash
   ./Scripts/odyssey.sh validate
   ```

3. **Test the build**:

   ```bash
   ./Scripts/odyssey.sh build
   ```

### Creating Release Tags

1. **Use semantic versioning**:

   ```bash
   ./Scripts/odyssey.sh tag vX.Y.Z  # Major release
   ./Scripts/odyssey.sh tag vX.Y.Z  # Minor release
   ./Scripts/odyssey.sh tag vX.Y.Z  # Patch release
   ```

2. **Follow git flow**:

   ```bash
   git checkout main
   git pull origin main
   ./Scripts/odyssey.sh tag vX.Y.Z
   ```

### After Creating a Tag

1. **Verify the tag was created**:

   ```bash
   git tag -l
   ```

2. **Check remote tags**:

   ```bash
   git ls-remote --tags origin
   ```

3. **Validate version consistency**:

   ```bash
   ./Scripts/odyssey.sh validate
   ```

## 🔍 Troubleshooting

### Common Issues

#### "There are uncommitted changes"

```bash
# Commit or stash changes first
git add .
git commit -m "feat: your changes"
# Then run tag command
./Scripts/odyssey.sh tag vX.Y.Z
```

#### "Tag already exists"

```bash
# Delete local tag
git tag -d vX.Y.Z
# Delete remote tag
git push origin :refs/tags/vX.Y.Z
# Then create new tag
./Scripts/odyssey.sh tag vX.Y.Z
```

#### "Version consistency validation failed"

```bash
# Check current versions
cat VERSION
grep "CFBundleShortVersionString" Sources/AppCore/Info.plist
grep "appVersion" Sources/SharedUtils/AppConstants.swift
# Manually fix inconsistencies, then validate
./Scripts/odyssey.sh validate
```

#### "Invalid version format"

```bash
# Use correct format
./Scripts/odyssey.sh tag vX.Y.Z  # ✅ Correct
./Scripts/odyssey.sh tag X.Y.Z   # ✅ Also works
./Scripts/odyssey.sh tag vX.Y    # ❌ Missing patch
./Scripts/odyssey.sh tag X.Y.Z.W # ❌ Too many components
```

### Debugging Version Issues

#### Check All Version Locations

```bash
echo "VERSION file: $(cat VERSION)"
echo "Info.plist: $(grep -A1 "CFBundleShortVersionString" Sources/AppCore/Info.plist | tail -1)"
echo "AppConstants: $(grep "appVersion" Sources/SharedUtils/AppConstants.swift)"
echo "CLIExport: $(grep "version: String" Sources/Services/CLIExportService.swift)"
echo "project.yml: $(grep "CFBundleShortVersionString" Config/project.yml)"
```

#### Manual Version Synchronization

```bash
# Get current version
VERSION=$(cat VERSION)

# Update all files manually
echo "$VERSION" > VERSION
sed -i '' "/CFBundleShortVersionString/,/<\/string>/s/<string>.*<\/string>/<string>$VERSION<\/string>/" Sources/AppCore/Info.plist
sed -i '' "s/appVersion = \".*\"/appVersion = \"$VERSION\"/" Sources/SharedUtils/AppConstants.swift
sed -i '' "s/version: String = \".*\"/version: String = \"$VERSION\"/" Sources/Services/CLIExportService.swift
sed -i '' "s/CFBundleShortVersionString: .*/CFBundleShortVersionString: $VERSION/" Config/project.yml

# Validate
./Scripts/odyssey.sh validate
```

## 📚 Related Documentation

- [Development Guide](DEVELOPMENT.md) - General development workflow
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues and solutions
- [CLI Documentation](CLI.md) - Command-line interface usage

## 🎯 Integration with CI/CD

The version management system integrates with the CI/CD pipeline:

1. **GitHub Actions** automatically detects version tags
2. **Release workflow** triggers on version tags
3. **Changelog generation** uses git tags
4. **Build artifacts** are versioned with git tags

### Automated Release Process

```bash
# Create version tag
./Scripts/odyssey.sh tag vX.Y.Z

# GitHub Actions automatically:
# - Builds the application
# - Creates DMG installer
# - Generates changelog
# - Publishes to GitHub Releases
```

---

**Need help?** Check the [Troubleshooting Guide](TROUBLESHOOTING.md) for common issues and solutions. 