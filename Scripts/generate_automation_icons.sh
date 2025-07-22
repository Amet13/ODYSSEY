#!/bin/bash

# ODYSSEY Icon Generation Script
# Generates icon assets from the minimal sportscourt automation logo

set -e

SVG_FILE="../logo.svg"

echo "🥅 Generating ODYSSEY Icon Assets"
echo "=================================="

# Check if rsvg-convert is installed
if ! command -v rsvg-convert &> /dev/null; then
    echo "❌ rsvg-convert is not installed. Please install it first:"
    echo "   brew install librsvg"
    exit 1
fi

# Create temp directory for icon generation
TEMP_DIR="temp_automation_icons"
mkdir -p "$TEMP_DIR"

# Define icon sizes for macOS
SIZES=(
    "16x16"
    "32x32"
    "64x64"
    "128x128"
    "256x256"
    "512x512"
    "1024x1024"
)

echo "🔨 Converting SVG to PNG at different sizes using rsvg-convert..."

# Convert SVG to PNG at different sizes
for size in "${SIZES[@]}"; do
    WIDTH=$(echo $size | cut -d'x' -f1)
    HEIGHT=$(echo $size | cut -d'x' -f2)
    echo "   Generating $size..."
    rsvg-convert -w $WIDTH -h $HEIGHT "$SVG_FILE" -o "$TEMP_DIR/icon_$size.png"
done

echo "📦 Creating icon set structure..."

# Create icon set directory
ICON_SET_DIR="Sources/Resources/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ICON_SET_DIR"

# Create Contents.json for the icon set
cat > "$ICON_SET_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "📋 Copying icons to icon set..."

# Copy icons to the appropriate locations
cp "$TEMP_DIR/icon_16x16.png" "$ICON_SET_DIR/icon_16x16.png"
cp "$TEMP_DIR/icon_32x32.png" "$ICON_SET_DIR/icon_16x16@2x.png"
cp "$TEMP_DIR/icon_32x32.png" "$ICON_SET_DIR/icon_32x32.png"
cp "$TEMP_DIR/icon_64x64.png" "$ICON_SET_DIR/icon_32x32@2x.png"
cp "$TEMP_DIR/icon_128x128.png" "$ICON_SET_DIR/icon_128x128.png"
cp "$TEMP_DIR/icon_256x256.png" "$ICON_SET_DIR/icon_128x128@2x.png"
cp "$TEMP_DIR/icon_256x256.png" "$ICON_SET_DIR/icon_256x256.png"
cp "$TEMP_DIR/icon_512x512.png" "$ICON_SET_DIR/icon_256x256@2x.png"
cp "$TEMP_DIR/icon_512x512.png" "$ICON_SET_DIR/icon_512x512.png"
cp "$TEMP_DIR/icon_1024x1024.png" "$ICON_SET_DIR/icon_512x512@2x.png"

echo "🎨 Creating ICNS file..."

# Create ICNS file for the app
mkdir -p "$TEMP_DIR/icon.iconset"
cp "$TEMP_DIR/icon_16x16.png" "$TEMP_DIR/icon.iconset/icon_16x16.png"
cp "$TEMP_DIR/icon_32x32.png" "$TEMP_DIR/icon.iconset/icon_16x16@2x.png"
cp "$TEMP_DIR/icon_32x32.png" "$TEMP_DIR/icon.iconset/icon_32x32.png"
cp "$TEMP_DIR/icon_64x64.png" "$TEMP_DIR/icon.iconset/icon_32x32@2x.png"
cp "$TEMP_DIR/icon_128x128.png" "$TEMP_DIR/icon.iconset/icon_128x128.png"
cp "$TEMP_DIR/icon_256x256.png" "$TEMP_DIR/icon.iconset/icon_128x128@2x.png"
cp "$TEMP_DIR/icon_256x256.png" "$TEMP_DIR/icon.iconset/icon_256x256.png"
cp "$TEMP_DIR/icon_512x512.png" "$TEMP_DIR/icon.iconset/icon_256x256@2x.png"
cp "$TEMP_DIR/icon_512x512.png" "$TEMP_DIR/icon.iconset/icon_512x512.png"
cp "$TEMP_DIR/icon_1024x1024.png" "$TEMP_DIR/icon.iconset/icon_512x512@2x.png"

# Generate ICNS file
iconutil -c icns "$TEMP_DIR/icon.iconset" -o "Sources/Resources/AppIcon.icns"

echo "🧹 Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Icon generation completed!"
echo ""
echo "Generated files:"
echo "  📁 Sources/Resources/Assets.xcassets/AppIcon.appiconset/ - Icon set for Xcode"
echo "  📄 Sources/Resources/AppIcon.icns - ICNS file for the app"
echo ""
echo "The new sportscourt automation logo is now ready to use! 🥅⚙️⏰" 