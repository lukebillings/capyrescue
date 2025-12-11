# How to Add a 3D Capybara to Your App

## Overview

I've created a new `Capybara3DView` component that uses RealityKit to display a 3D capybara model. This guide explains how to use it and where to get 3D models.

## Quick Start

### Option 1: Use the Procedural Model (Works Immediately)

The `Capybara3DView` includes a simple procedural 3D capybara made from basic shapes. You can use it right away:

1. In `ContentView.swift`, replace `CapybaraView` with `Capybara3DView`:

```swift
Capybara3DView(
    emotion: gameManager.gameState.capybaraEmotion,
    equippedAccessories: gameManager.gameState.equippedAccessories,
    onPet: {
        gameManager.petCapybara()
    }
)
```

### Option 2: Use a Custom 3D Model (Better Quality)

#### Step 1: Get a 3D Capybara Model

You have several options:

1. **Free Models:**

   - [Sketchfab](https://sketchfab.com) - Search for "capybara" (many free models available)
   - [TurboSquid](https://www.turbosquid.com) - Some free capybara models
   - [CGTrader](https://www.cgtrader.com) - Free and paid models
   - [Poly Haven](https://polyhaven.com) - Free 3D assets

2. **Create Your Own:**

   - Use Blender (free) to model a capybara
   - Export as USDZ format for iOS

3. **AI-Generated Models:**
   - Use tools like Luma AI or other 3D generation tools

#### Step 2: Convert to USDZ Format

If your model is in another format (OBJ, FBX, etc.), convert it to USDZ:

1. **Using Reality Converter (Apple's Free Tool):**

   - Download from Mac App Store: "Reality Converter"
   - Drag your model file into Reality Converter
   - Export as USDZ

2. **Using Blender:**

   - Install the USD export addon
   - Export as USD, then convert to USDZ using command line tools

3. **Online Converters:**
   - Search for "OBJ to USDZ converter" online

#### Step 3: Add Model to Your Project

1. Open your Xcode project
2. Drag the `capybara.usdz` file into your project navigator
3. Make sure "Copy items if needed" is checked
4. Add it to your target

#### Step 4: Update the Code

Modify `Capybara3DView.swift` to load your model. Update the `createProceduralCapybara()` function or add a new loading function:

```swift
private func loadCapybaraModel() async -> ModelEntity? {
    // Load from app bundle
    guard let modelURL = Bundle.main.url(forResource: "capybara", withExtension: "usdz") else {
        return createProceduralCapybara()
    }

    do {
        let modelEntity = try await Entity.load(contentsOf: modelURL)
        if let model = modelEntity as? ModelEntity {
            // Scale and position
            model.scale = [0.15, 0.15, 0.15]
            model.position.y = -0.2
            return model
        }
    } catch {
        print("Failed to load capybara model: \(error)")
        return createProceduralCapybara()
    }

    return nil
}
```

Then update the `RealityView` to use async loading:

```swift
RealityView { content in
    Task {
        if let model = await loadCapybaraModel() {
            await MainActor.run {
                content.add(model)
            }
        }
    }
}
```

## Features Included

✅ **3D Model Display** - Shows a 3D capybara using RealityKit  
✅ **Rotation Animation** - Gentle continuous rotation  
✅ **Emotion Support** - Glow effects based on capybara emotion  
✅ **Accessories** - Overlay support for hats, glasses, shoes  
✅ **Pet Interaction** - Tap to pet with heart animation  
✅ **Procedural Fallback** - Works even without a 3D model file

## Customization

### Adjust Scale

Change the model size by modifying:

```swift
model.scale = [0.15, 0.15, 0.15] // Make larger: [0.2, 0.2, 0.2]
```

### Adjust Position

Change vertical position:

```swift
model.position.y = -0.2 // Move up: -0.1, Move down: -0.3
```

### Rotation Speed

Change rotation duration:

```swift
.linear(duration: 10) // Faster: 5, Slower: 20
```

### Disable Rotation

Remove the rotation animation if desired.

## Troubleshooting

**Model not showing?**

- Check that the file is added to your target
- Verify the filename matches exactly (case-sensitive)
- Try the procedural model first to test the view

**Performance issues?**

- Reduce model complexity
- Lower the scale
- Disable rotation animation

**Model too large/small?**

- Adjust the `scale` property
- Modify the frame size

## Next Steps

1. **Attach Accessories to 3D Model**: Instead of overlaying emojis, attach 3D accessory models to specific bones/joints
2. **Animation Support**: Add animations (idle, happy, sad) to the 3D model
3. **Lighting**: Add custom lighting for better appearance
4. **Materials**: Enhance textures and materials for more realism

## Resources

- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
- [USDZ File Format](https://developer.apple.com/augmented-reality/quick-look/)
- [Reality Converter App](https://developer.apple.com/augmented-reality/tools/)
