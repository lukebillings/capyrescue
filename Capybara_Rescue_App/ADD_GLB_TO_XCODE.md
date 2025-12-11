# How to Add Capybara.glb to Xcode

## Step 1: Convert GLB to USDZ (Recommended)

GLB files work, but USDZ is the preferred format for iOS. Here are two easy ways to convert:

### Option A: Using Reality Converter (Easiest - Free Mac App)

1. **Download Reality Converter** from the Mac App Store (it's free from Apple)
2. Open Reality Converter
3. Drag your `Capybara.glb` file into Reality Converter
4. Click "Export" and save as `Capybara.usdz`
5. The file is now ready to use!

### Option B: Online Converter

1. Go to https://products.aspose.app/3d/conversion/glb-to-usdz (or search "GLB to USDZ converter")
2. Upload your `Capybara.glb` file
3. Download the converted `Capybara.usdz` file

## Step 2: Add File to Xcode Project

1. **Open your Xcode project**
2. **Right-click** on your project folder in the Project Navigator (left sidebar)
3. Select **"Add Files to 'Capybara_Rescue_App'..."**
4. Navigate to your project folder and select:
   - `Capybara.usdz` (if you converted it) OR
   - `Capybara.glb` (the code will try both formats)
5. **IMPORTANT**: Make sure these checkboxes are selected:
   - ✅ **"Copy items if needed"** (so the file is copied into your project)
   - ✅ **Your app target** (Capybara_Rescue_App) is checked under "Add to targets"
6. Click **"Add"**

## Step 3: Verify the File is Added

1. You should see `Capybara.usdz` or `Capybara.glb` in your Project Navigator
2. Click on it and check the "Target Membership" in the right panel - your app should be checked

## Step 4: Test It!

The code is already set up to load the model. Just:

1. Make sure you're using `Capybara3DView` in your `ContentView.swift`
2. Build and run the app
3. The 3D capybara should appear!

## Troubleshooting

**Model not showing?**

- Check the file is in your project (visible in Project Navigator)
- Verify the filename is exactly `Capybara.usdz` or `Capybara.glb` (case-sensitive)
- Check the file is added to your target (Target Membership)
- Try converting GLB to USDZ for better compatibility

**File already in project folder but not in Xcode?**

- The file is already copied to your project directory
- You just need to add it to the Xcode project using Step 2 above

**Want to use GLB directly?**

- The code will try to load GLB files, but USDZ is more reliable
- If GLB doesn't work, convert to USDZ using Reality Converter
