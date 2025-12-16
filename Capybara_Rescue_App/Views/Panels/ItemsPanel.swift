import SwiftUI
import RealityKit
import ARKit

// MARK: - Items Panel
struct ItemsPanel: View {
    @EnvironmentObject var gameManager: GameManager
    let onBack: (() -> Void)?
    let onOpenShop: (() -> Void)?
    
    @State private var previewingItemId: String? = nil
    @State private var showInsufficientCoinsMessage: Bool = false
    @State private var showLooksGoodModal: Bool = false
    @State private var showHatEquipError: Bool = false
    
    init(onBack: (() -> Void)? = nil, onOpenShop: (() -> Void)? = nil) {
        self.onBack = onBack
        self.onOpenShop = onOpenShop
    }
    
    var body: some View {
        mainContent
            .overlay(insufficientCoinsOverlay)
            .overlay(looksGoodModalOverlay)
            .overlay(hatEquipErrorOverlay)
    }
    
    private var mainContent: some View {
        VStack(spacing: 16) {
            // Header with back button
            HStack {
                if let onBack = onBack {
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        // Clear preview if unpurchased item is being previewed
                        if let previewId = previewingItemId,
                           !gameManager.gameState.ownedAccessories.contains(previewId) {
                            previewingItemId = nil
                            gameManager.clearPreview()
                        }
                        onBack()
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                PanelHeader(
                    title: "Accessorise Your Capybara",
                    subtitle: "Make them stylish! ✨",
                    color: .purple
                )
                
                Spacer()
                
                // Spacer for symmetry
                if onBack != nil {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.clear)
                }
            }
            .padding(.horizontal, 16)
            
            // Items - horizontal scrolling row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(filteredItems) { item in
                        AccessoryItemButton(
                            item: item,
                            isOwned: gameManager.gameState.ownedAccessories.contains(item.id),
                            isEquipped: gameManager.gameState.equippedAccessories.contains(item.id),
                            canAfford: gameManager.canAfford(item.cost),
                            isPreviewing: previewingItemId == item.id
                        ) {
                            handleItemAction(item)
                        }
                        .frame(width: 100) // Fixed width for horizontal scroll
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8) // Add vertical padding to prevent cutoff
            }
            .frame(maxHeight: .infinity) // Allow scroll view to take available space
        }
        .padding(.top, 20)
        .padding(.bottom, 8) // Add bottom padding
        .onChange(of: gameManager.gameState.capycoins) { oldValue, newValue in
            // Update preview state when coins change (e.g., after buying coins)
            guard let previewId = previewingItemId, !previewId.isEmpty else { return }
            guard let item = AccessoryItem.allItems.first(where: { $0.id == previewId }) else {
                print("⚠️ Preview item not found: \(previewId)")
                return
            }
            if gameManager.canAfford(item.cost) {
                showInsufficientCoinsMessage = false
            }
        }
    }
    
    @ViewBuilder
    private var insufficientCoinsOverlay: some View {
        if showInsufficientCoinsMessage, 
           let previewingId = previewingItemId,
           !previewingId.isEmpty,
           let item = AccessoryItem.allItems.first(where: { $0.id == previewingId }) {
            InsufficientCoinsOverlay(
                itemName: item.name,
                itemCost: item.cost,
                currentCoins: gameManager.gameState.capycoins,
                onBuyCoins: {
                    showInsufficientCoinsMessage = false
                    previewingItemId = nil
                    gameManager.clearPreview()
                    onOpenShop?()
                },
                onDismiss: {
                    showInsufficientCoinsMessage = false
                    // Keep preview active so user can still see it on capybara
                }
            )
        }
    }
    
    @ViewBuilder
    private var looksGoodModalOverlay: some View {
        if showLooksGoodModal,
           let previewingId = previewingItemId,
           !previewingId.isEmpty,
           let item = AccessoryItem.allItems.first(where: { $0.id == previewingId }) {
            LooksGoodModal(
                itemName: item.name,
                itemCost: item.cost,
                currentCoins: gameManager.gameState.capycoins,
                onBuyNow: {
                    if gameManager.purchaseAccessory(item) {
                        HapticManager.shared.purchaseSuccess()
                        showLooksGoodModal = false
                        previewingItemId = nil
                        gameManager.clearPreview()
                    } else {
                        HapticManager.shared.purchaseFailed()
                    }
                },
                onDismiss: {
                    showLooksGoodModal = false
                    // Keep preview active so user can still see it on capybara
                }
            )
        }
    }
    
    @ViewBuilder
    private var hatEquipErrorOverlay: some View {
        if showHatEquipError {
            HatEquipErrorOverlay(
                onDismiss: {
                    showHatEquipError = false
                }
            )
        }
    }
    
    private var filteredItems: [AccessoryItem] {
        // Safety check: ensure allItems is accessible
        guard !AccessoryItem.allItems.isEmpty else {
            print("⚠️ No accessory items available")
            return []
        }
        // Sort items by price (cost) in ascending order
        return AccessoryItem.allItems.sorted { $0.cost < $1.cost }
    }
    
    private func handleItemAction(_ item: AccessoryItem) {
        // Safety check: ensure item is valid
        guard !item.id.isEmpty else {
            print("⚠️ Invalid item ID")
            return
        }
        
        if gameManager.gameState.ownedAccessories.contains(item.id) {
            // Check if this is a hat and if another hat is already equipped
            if item.isHat {
                // Check if another hat is equipped - safely access allItems
                let otherEquippedHats = gameManager.gameState.equippedAccessories.compactMap { equippedId -> String? in
                    guard !equippedId.isEmpty,
                          let equippedItem = AccessoryItem.allItems.first(where: { $0.id == equippedId }),
                          equippedItem.isHat else { return nil }
                    return equippedId
                }
                
                if !otherEquippedHats.isEmpty && !gameManager.gameState.equippedAccessories.contains(item.id) {
                    // Another hat is equipped, show error message
                    showHatEquipError = true
                    HapticManager.shared.purchaseFailed()
                    return
                }
            }
            
            // Toggle equip/unequip
            HapticManager.shared.selection()
            gameManager.equipAccessory(item.id)
            // Clear any preview when equipping
            if previewingItemId != nil {
                previewingItemId = nil
                gameManager.clearPreview()
                showInsufficientCoinsMessage = false
                showLooksGoodModal = false
            }
        } else {
            // Preview and purchase flow
            if previewingItemId == item.id {
                // Second click on previewed item - show "Looks Good?" modal if can afford
                if gameManager.canAfford(item.cost) {
                    showLooksGoodModal = true
                    HapticManager.shared.selection()
                } else {
                    // Can't afford - show insufficient coins message
                    showInsufficientCoinsMessage = true
                    HapticManager.shared.purchaseFailed()
                }
            } else {
                // First click on this item OR switching to different item - preview it
                HapticManager.shared.selection()
                
                // Clear previous modals
                showInsufficientCoinsMessage = false
                showLooksGoodModal = false
                
                previewingItemId = item.id
                gameManager.previewAccessory(item.id)
            }
        }
    }
}

// MARK: - Category Tab Bar
struct CategoryTabBar: View {
    @Binding var selectedCategory: AccessoryItem.AccessoryCategory
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(AccessoryItem.AccessoryCategory.allCases, id: \.self) { category in
                CategoryTab(
                    title: category.rawValue,
                    isSelected: selectedCategory == category
                ) {
                    HapticManager.shared.menuTabChanged()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = category
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple.opacity(0.4) : .white.opacity(0.05))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.purple.opacity(0.6) : .clear, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Accessory Item Button
struct AccessoryItemButton: View {
    let item: AccessoryItem
    let isOwned: Bool
    let isEquipped: Bool
    let canAfford: Bool
    let isPreviewing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // 3D Model Preview
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 70, height: 70)
                    
                    if let modelFileName = item.modelFileName, !modelFileName.isEmpty, item.isHat {
                        // Always show 3D model preview for hats
                        if #available(iOS 17.0, *) {
                            HatPreview3DView(fileName: modelFileName)
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        } else {
                            // Fallback for older iOS versions
                            Text(item.emoji)
                                .font(.system(size: 36))
                        }
                    } else if let modelFileName = item.modelFileName, !modelFileName.isEmpty {
                        // Show 3D model for other items with models
                        if #available(iOS 17.0, *) {
                            HatPreview3DView(fileName: modelFileName)
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        } else {
                            // Fallback for older iOS versions
                            Text(item.emoji)
                                .font(.system(size: 36))
                        }
                    } else {
                        // Fallback to emoji only for items without 3D models
                        Text(item.emoji)
                            .font(.system(size: 36))
                    }
                    
                    // Equipped indicator
                    if isEquipped {
                        Circle()
                            .stroke(Color.green, lineWidth: 3)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.green)
                            .background(Circle().fill(.black))
                            .offset(x: 25, y: -25)
                    }
                }
                
                // Name
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // Status / Price
                if isOwned {
                    Text(isEquipped ? "Equipped" : "Tap to Equip")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(isEquipped ? .green : .white.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                } else {
                    if isPreviewing {
                        Text("Tap to buy")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.blue)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    } else {
                    VStack(spacing: 4) {
                        HStack(spacing: 3) {
                            Text("₵")
                                .font(.system(size: 12, weight: .bold))
                            Text("\(item.cost)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(canAfford ? AppColors.accent : .white.opacity(0.5))
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        
                        Text("Tap to Preview")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.green)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                }
                }
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white.opacity(isOwned ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .opacity(1) // Always visible now for preview
        }
        .buttonStyle(ScaleButtonStyle())
        .overlay(
            // Preview indicator
            Group {
                if isPreviewing {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.blue, lineWidth: 2)
                }
            }
        )
    }
    
    private var backgroundColor: Color {
        if isEquipped {
            return .green.opacity(0.3)
        } else if isOwned {
            return .purple.opacity(0.3)
        } else {
            return .white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isEquipped {
            return .green.opacity(0.5)
        } else if isOwned {
            return .purple.opacity(0.3)
        } else {
            return .white.opacity(0.1)
        }
    }
}

// MARK: - 3D Hat Preview
@available(iOS 17.0, *)
struct HatPreview3DView: View {
    let fileName: String
    
    var body: some View {
        HatPreviewARView(fileName: fileName)
    }
}

@available(iOS 17.0, *)
struct HatPreviewARView: UIViewRepresentable {
    let fileName: String
    
    // Preview-specific scale adjustments for items panel
    private func previewScale(for fileName: String) -> Float {
        if fileName.contains("Santa") {
            return 1.0
        } else if fileName.contains("Cowboy") {
            return 0.3 // Slightly smaller
        } else if fileName.contains("Wizard") {
            return 0.15 // Smaller
        } else if fileName.contains("Pirate") {
            return 0.15 // Smaller
        } else if fileName.contains("Propeller") {
            return 0.15 // Smaller
        } else if fileName.contains("Fox") {
            return 0.35 // Bigger
        } else if fileName.contains("Frog") {
            return 0.35 // Bigger
        } else {
            return 0.2 // Default
        }
    }
    
    // Preview-specific position adjustments for items panel
    private func previewPosition(for fileName: String) -> SIMD3<Float> {
        if fileName.contains("Baseball") {
            return [0.1, 0.0, 0.0] // More to the right
        } else if fileName.contains("Santa") {
            return [0, 0.1, 0]
        } else if fileName.contains("Pirate") {
            return [0, 0.1, 0] // Move up
        } else if fileName.contains("Wizard") {
            return [0, -0.1, 0] // Move down
        } else {
            return [0, 0.0, 0.0] // Default centered
        }
    }
    
    // Preview-specific rotation adjustments for items panel
    private func previewRotation(for fileName: String) -> simd_quatf {
        if fileName.contains("Frog") {
            // Rotate 90 degrees around Y axis so frog face faces the user
            return simd_quatf(angle: Float.pi / 2, axis: [0, 1, 0])
        } else {
            return simd_quatf(ix: 0, iy: 0, iz: 0, r: 1) // No rotation
        }
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.backgroundColor = .clear
        
        // Disable rendering features for better performance
        arView.environment.background = .color(.clear)
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur, .disableAREnvironmentLighting]
        
        // Create anchor
        let anchor = AnchorEntity(world: [0, 0, 0])
        arView.scene.addAnchor(anchor)
        
        // Set up camera - adjust based on hat type
        let camera = PerspectiveCamera()
        if fileName.contains("Propeller") {
            // Zoom out more for propeller hat
            camera.position = [0, 0.1, 1.0]
        } else if fileName.contains("Pirate") {
            // Much more zoomed out for pirate hat
            camera.position = [0, 0.1, 1.5]
        } else if fileName.contains("Cowboy") {
            // More zoomed out for cowboy hat
            camera.position = [0, 0.1, 0.8]
        } else if fileName.contains("Santa") || fileName.contains("Fox") || fileName.contains("Frog") {
            // Closer camera for larger hats
            camera.position = [0, 0.1, 0.3]
        } else {
            camera.position = [0, 0.1, 0.6]
        }
        camera.camera.near = 0.01
        camera.camera.far = 10.0
        let cameraAnchor = AnchorEntity(world: [0, 0, 0])
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)
        
        // Add lighting
        let light = DirectionalLight()
        light.light.intensity = 1500
        light.position = [0.5, 1, 1]
        light.light.isRealWorldProxy = false
        let lightAnchor = AnchorEntity(world: [0, 0, 0])
        lightAnchor.addChild(light)
        arView.scene.addAnchor(lightAnchor)
        
        // Add ambient light
        let ambientLight = DirectionalLight()
        ambientLight.light.intensity = 500
        ambientLight.position = [-0.5, -0.5, -1]
        ambientLight.light.isRealWorldProxy = false
        let ambientLightAnchor = AnchorEntity(world: [0, 0, 0])
        ambientLightAnchor.addChild(ambientLight)
        arView.scene.addAnchor(ambientLightAnchor)
        
        // Load hat model - with safety checks
        guard !fileName.isEmpty else {
            print("⚠️ Empty file name for hat preview")
            return arView
        }
        
        guard let usdzURL = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            print("⚠️ Hat file not found in bundle: \(fileName).usdz")
            return arView
        }
        
        // Helper function to find first model entity (captured for use in Task)
        func findModel(in entity: Entity) -> ModelEntity? {
            if let model = entity as? ModelEntity {
                return model
            }
            for child in entity.children {
                if let model = findModel(in: child) {
                    return model
                }
            }
            return nil
        }
        
        Task { @MainActor in
            do {
                // Load entity using async API (Swift 6 compatible)
                let loadedEntity = try await Entity.load(contentsOf: usdzURL)
                
                // Create a container to hold the model and apply transformations
                let container = ModelEntity()
                
                // Handle different entity types
                if let directModel = loadedEntity as? ModelEntity {
                    container.addChild(directModel)
                } else {
                    // Clone all children from the loaded entity
                    for child in loadedEntity.children {
                        container.addChild(child.clone(recursive: true))
                    }
                    
                    // If no children, try to find model in hierarchy
                    if container.children.isEmpty {
                        if let model = findModel(in: loadedEntity) {
                            container.addChild(model)
                        }
                    }
                }
                
                // Apply transformations if we have a valid model
                if !container.children.isEmpty || container.components[ModelComponent.self] != nil {
                    // Scale based on hat type - adjust for preview size
                    let scale = previewScale(for: fileName)
                    container.scale = [scale, scale, scale]
                    // Position based on hat type
                    let position = previewPosition(for: fileName)
                    container.position = position
                    // Rotation based on hat type
                    container.orientation = previewRotation(for: fileName)
                    
                    // Add to anchor safely
                    anchor.addChild(container)
                } else {
                    print("⚠️ No valid model found in hat file: \(fileName)")
                }
            } catch {
                print("❌ Failed to load hat preview: \(error.localizedDescription)")
                print("   File: \(fileName).usdz")
            }
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // No updates needed
    }
    
    private func findFirstModelEntity(in entity: Entity) -> ModelEntity? {
        if let model = entity as? ModelEntity {
            return model
        }
        for child in entity.children {
            if let model = findFirstModelEntity(in: child) {
                return model
            }
        }
        return nil
    }
}

// MARK: - Looks Good Modal
struct LooksGoodModal: View {
    let itemName: String
    let itemCost: Int
    let currentCoins: Int
    let onBuyNow: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Message card
            VStack(spacing: 20) {
                Text("Looks Good?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Cost:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("₵\(itemCost)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.accent)
                        Text("•")
                            .foregroundStyle(.white.opacity(0.5))
                        Text("You have:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("₵\(currentCoins)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                
                Button(action: {
                    HapticManager.shared.buttonPress()
                    onBuyNow()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Buy Now")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 8, x: 0, y: 4)
                }
                
                Button(action: {
                    HapticManager.shared.buttonPress()
                    onDismiss()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e").opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Insufficient Coins Overlay
struct InsufficientCoinsOverlay: View {
    let itemName: String
    let itemCost: Int
    let currentCoins: Int
    let onBuyCoins: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Message card
            VStack(spacing: 20) {
                Text("Looks Good?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                VStack(spacing: 8) {
                    Text("You need more coins")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    HStack(spacing: 6) {
                        Text("Cost:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("₵\(itemCost)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.accent)
                        Text("•")
                            .foregroundStyle(.white.opacity(0.5))
                        Text("You have:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("₵\(currentCoins)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                
                Button(action: {
                    HapticManager.shared.buttonPress()
                    onBuyCoins()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Buy More Coins")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 8, x: 0, y: 4)
                }
                
                Button(action: {
                    HapticManager.shared.buttonPress()
                    onDismiss()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e").opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Hat Equip Error Overlay
struct HatEquipErrorOverlay: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Message card
            VStack(spacing: 20) {
                Text("Only one hat can be equipped at a time")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("Please deselect current hat")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    HapticManager.shared.buttonPress()
                    onDismiss()
                }) {
                    Text("OK")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.6))
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e").opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        ItemsPanel()
            .environmentObject(GameManager())
    }
}

