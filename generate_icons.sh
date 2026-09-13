#!/bin/bash
set -e

SOURCE="mobile/assets/makko-pet.png"
RES_DIR="mobile/android/app/src/main/res"

# Generate launcher icons (with a solid background color #06b6d4 / brand primary)
# We'll put the pet inside a cyan circle for the launcher icon
magick "$SOURCE" -resize 70% temp_pet.png
magick -size 512x512 canvas:'#0C1527' -fill '#06b6d4' -draw "circle 256,256 256,0" temp_bg.png
magick composite -gravity center temp_pet.png temp_bg.png temp_icon.png

mkdir -p "$RES_DIR/mipmap-mdpi"
mkdir -p "$RES_DIR/mipmap-hdpi"
mkdir -p "$RES_DIR/mipmap-xhdpi"
mkdir -p "$RES_DIR/mipmap-xxhdpi"
mkdir -p "$RES_DIR/mipmap-xxxhdpi"

magick temp_icon.png -resize 48x48 "$RES_DIR/mipmap-mdpi/ic_launcher.png"
magick temp_icon.png -resize 72x72 "$RES_DIR/mipmap-hdpi/ic_launcher.png"
magick temp_icon.png -resize 96x96 "$RES_DIR/mipmap-xhdpi/ic_launcher.png"
magick temp_icon.png -resize 144x144 "$RES_DIR/mipmap-xxhdpi/ic_launcher.png"
magick temp_icon.png -resize 192x192 "$RES_DIR/mipmap-xxxhdpi/ic_launcher.png"

# Now splash screen
# Android 12+ uses splash screen API, but we'll set up the basic window background
mkdir -p "$RES_DIR/drawable"
mkdir -p "$RES_DIR/drawable-night"

magick temp_icon.png -resize 288x288 "$RES_DIR/drawable/splash_icon.png"

# Setup splash.xml
cat << 'XML' > "$RES_DIR/drawable/splash.xml"
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_bg" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_icon" />
    </item>
</layer-list>
XML

# Setup colors
mkdir -p "$RES_DIR/values"
mkdir -p "$RES_DIR/values-night"

cat << 'XML' > "$RES_DIR/values/colors.xml"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_bg">#F4F7FB</color>
</resources>
XML

cat << 'XML' > "$RES_DIR/values-night/colors.xml"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_bg">#070D18</color>
</resources>
XML

# Update styles
cat << 'XML' > "$RES_DIR/values/styles.xml"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/splash</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
XML

cat << 'XML' > "$RES_DIR/values-night/styles.xml"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/splash</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
XML

rm temp_pet.png temp_bg.png temp_icon.png
echo "Done setting up icons and splash!"
