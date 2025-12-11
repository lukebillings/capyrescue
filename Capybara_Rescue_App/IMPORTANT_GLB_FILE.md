# ⚠️ IMPORTANT: Add Capybara.glb to Xcode Project

Your `Capybara.glb` file exists in the project folder, but it needs to be added to the Xcode project for the app to use it.

## Steps to Add the File:

1. **Open your Xcode project**
2. **Right-click** on your project folder in the Project Navigator (left sidebar)
3. Select **"Add Files to 'Capybara Rescue Universe'..."**
4. Navigate to your project folder and select **`Capybara.glb`**
5. **IMPORTANT**: Make sure these checkboxes are selected:
   - ✅ **"Copy items if needed"** (if not already copied)
   - ✅ **Your app target** (Capybara Rescue Universe) is checked under "Add to targets"
6. Click **"Add"**

## GLB vs USDZ Format:

**Important Note**: GLB files may not load properly in iOS. For best results:

1. **Convert GLB to USDZ** using Reality Converter (free Mac App Store app):

   - Download "Reality Converter" from the App Store
   - Open Reality Converter
   - Drag `Capybara.glb` into it
   - Click "Export" and save as `Capybara.usdz`
   - Add the USDZ file to Xcode instead

2. **Or use an online converter**:
   - Search for "GLB to USDZ converter" online
   - Upload your GLB file and download the USDZ version

## Verify It's Working:

After adding the file, check the Xcode console when you run the app. You should see:

- ✅ "Found Capybara.usdz" or "Found Capybara.glb"
- ✅ "Successfully loaded" message

If you see "⚠️ Capybara.glb not found in bundle", the file isn't properly added to the project.
