import SwiftUI
import SceneKit

// MARK: - Items Panel
struct ItemsPanel: View {
    @EnvironmentObject var gameManager: GameManager
    let onBack: (() -> Void)?
    let onOpenShop: (() -> Void)?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var previewingItemId: String? = nil
    @State private var showInsufficientCoinsMessage: Bool = false
    @State private var showLooksGoodModal: Bool = false
    @State private var showHatEquipError: Bool = false
    @State private var showPaywall: Bool = false
    @State private var selectedSubscriptionTier: SubscriptionManager.SubscriptionTier? = nil
    
    init(onBack: (() -> Void)? = nil, onOpenShop: (() -> Void)? = nil) {
        self.onBack = onBack
        self.onOpenShop = onOpenShop
    }
    
    var body: some View {
        mainContent
            .overlay(insufficientCoinsOverlay)
            .overlay(looksGoodModalOverlay)
            .overlay(hatEquipErrorOverlay)
            .sheet(isPresented: $showPaywall) {
                PaywallView(selectedTier: $selectedSubscriptionTier, hideFreeOption: true, showDismissButton: true)
                    .onChange(of: selectedSubscriptionTier) { oldValue, newValue in
                        if let tier = newValue {
                            // Use upgradeSubscription to ADD coins, not override
                            gameManager.upgradeSubscription(to: tier)
                            gameManager.showToast("\(tier.startingCoins) coins added! 🎉")
                            showPaywall = false
                            selectedSubscriptionTier = nil
                        }
                    }
            }
    }
    
    private var mainContent: some View {
        Group {
            // Keep iPhone (compact width) submenu layout unchanged.
            if horizontalSizeClass == .compact {
                VStack(spacing: 16) {
                    // Items - horizontal scrolling row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredItems) { item in
                                AccessoryItemButton(
                                    item: item,
                                    isOwned: gameManager.gameState.ownedAccessories.contains(item.id),
                                    isEquipped: gameManager.gameState.equippedAccessories.contains(item.id),
                                    canAfford: gameManager.canAfford(item.cost),
                                    isPreviewing: previewingItemId == item.id,
                                    hasPro: gameManager.hasProSubscription()
                                ) {
                                    handleItemAction(item)
                                }
                                .frame(width: 100) // Fixed width for horizontal scroll
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8) // Add vertical padding to prevent cutoff
                    }
                    .frame(maxHeight: .infinity) // Fill space so header sits lower
                    
                    // Header with back button - moved below items
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
                        
                        Text("Accessorise Your Capybara")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        // Spacer for symmetry
                        if onBack != nil {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.clear)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 80)
                .padding(.bottom, 36)
            } else {
                // iPad / iPad mini: keep adaptive sizing to avoid row/header clipping.
                GeometryReader { geometry in
                    VStack(spacing: 12) {
                        // Items - horizontal scrolling row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(filteredItems) { item in
                                    AccessoryItemButton(
                                        item: item,
                                        isOwned: gameManager.gameState.ownedAccessories.contains(item.id),
                                        isEquipped: gameManager.gameState.equippedAccessories.contains(item.id),
                                        canAfford: gameManager.canAfford(item.cost),
                                        isPreviewing: previewingItemId == item.id,
                                        hasPro: gameManager.hasProSubscription()
                                    ) {
                                        handleItemAction(item)
                                    }
                                    .frame(width: 100) // Fixed width for horizontal scroll
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .frame(height: max(120, min(geometry.size.height * 0.65, 140))) // Adaptive height
                        
                        // Header with back button - moved below items
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
                            
                            Text("Accessorise Your Capybara")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Spacer()
                            
                            // Spacer for symmetry
                            if onBack != nil {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.clear)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 60) // Fixed height for header to prevent cutoff
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
            }
        }
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
        
        // Check if item is Pro-only and user doesn't have Pro
        if item.isProOnly && !gameManager.hasProSubscription() {
            // Allow preview
            if previewingItemId == item.id {
                // Second click - show paywall
                HapticManager.shared.buttonPress()
                showPaywall = true
            } else {
                // First click - preview it (same as regular items)
                HapticManager.shared.selection()
                
                // Clear previous modals
                showInsufficientCoinsMessage = false
                showLooksGoodModal = false
                
                previewingItemId = item.id
                gameManager.previewAccessory(item.id)
            }
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
    let hasPro: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // 3D Model Preview
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 70, height: 70)
                    
                    if let modelFileName = item.modelFileName, !modelFileName.isEmpty {
                        // Show 3D model preview for items with models (hats and others)
                        HatPreview3DView(fileName: modelFileName)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    } else {
                        // Fallback to emoji only for items without 3D models
                        Text(item.emoji)
                            .font(.system(size: 48))
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
                    
                    // Pro badge for Pro-only items
                    if item.isProOnly && !hasPro {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.7))
                                            .frame(width: 24, height: 24)
                                    )
                                    .offset(x: -5, y: -5)
                            }
                        }
                        .frame(width: 70, height: 70)
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
                } else if item.isProOnly && !hasPro {
                    // Pro-only item without subscription
                    if isPreviewing {
                        Text("Unlock on Pro")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    } else {
                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                Text("PRO")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            Text("Tap to Preview")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.green)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                    }
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
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(isOwned ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .opacity(1) // Always visible now for preview
        }
        .buttonStyle(ScaleButtonStyle())
        .overlay(
            // Chinese New Year "NEW!" badge for Red Lantern
            Group {
                if item.id == "redlantern" && Date.isChineseNewYearEvent2026() {
                    VStack {
                        HStack {
                            Spacer()
                            Text("NEW!")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(Color(hex: "8B0000"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .offset(x: -5, y: 5)
                        }
                        Spacer()
                    }
                }
            }
        )
        .overlay(
            // Preview indicator and gold ring for CNY items
            Group {
                if isPreviewing {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 2)
                } else if item.id == "redlantern" && Date.isChineseNewYearEvent2026() {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                }
            }
        )
    }
    
    private var backgroundColor: Color {
        if isEquipped {
            return .green.opacity(0.3)
        } else if isPreviewing {
            return .blue.opacity(0.3)
        } else if isOwned {
            return .purple.opacity(0.3)
        } else {
            return .white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isEquipped {
            return .green.opacity(0.5)
        } else if isPreviewing {
            return .blue.opacity(0.6)
        } else if isOwned {
            return .purple.opacity(0.3)
        } else {
            return .white.opacity(0.1)
        }
    }
}

// MARK: - 3D Hat Preview using SceneKit (more stable for multiple instances)
struct HatPreview3DView: View {
    let fileName: String
    
    var body: some View {
        HatPreviewSceneView(fileName: fileName)
    }
}

// SceneKit-based preview - much more stable than RealityKit for multiple simultaneous views
struct HatPreviewSceneView: UIViewRepresentable {
    let fileName: String
    
    // Preview-specific scale adjustments for items panel (matching original RealityKit values)
    private func previewScale(for fileName: String) -> Float {
        if fileName.contains("Santa") {
            return 1.0
        } else if fileName.contains("Cowboy") {
            return 0.3
        } else if fileName.contains("Wizard") {
            return 0.15
        } else if fileName.contains("Pirate") {
            return 0.15
        } else if fileName.contains("Propeller") {
            return 0.15
        } else if fileName.contains("Fox") {
            return 0.35
        } else if fileName.contains("Frog") {
            return 0.35
        } else if fileName.contains("Baseball") {
            return 0.2
        } else if fileName.contains("Sombrero") {
            return 0.2
        } else if fileName.contains("Cone") {
            return 0.4
        } else if fileName.contains("Pizza") {
            return 0.5
        } else if fileName.contains("red-lantern") {
            return 0.6
        } else {
            return 0.2 // Default
        }
    }
    
    // Preview-specific position adjustments (matching original RealityKit values)
    private func previewPosition(for fileName: String) -> SCNVector3 {
        if fileName.contains("Baseball") {
            return SCNVector3(0.1, 0.0, 0.0) // More to the right
        } else if fileName.contains("Santa") {
            return SCNVector3(0, 0.1, 0)
        } else if fileName.contains("Pirate") {
            return SCNVector3(0, 0.1, 0) // Move up
        } else if fileName.contains("Wizard") {
            return SCNVector3(0, -0.1, 0) // Move down
        } else if fileName.contains("Cone") {
            return SCNVector3(0, 0.0, 0.0) // Centered
        } else if fileName.contains("Pizza") {
            return SCNVector3(0, 0.0, 0.0) // Centered
        } else {
            return SCNVector3(0, 0.0, 0.0) // Default centered
        }
    }
    
    // Preview-specific Y rotation (in radians)
    private func previewYRotation(for fileName: String) -> Float {
        if fileName.contains("Frog") {
            return .pi / 2 // 90 degrees so frog faces user
        } else {
            return 0
        }
    }
    
    // Camera position based on hat type (matching original RealityKit values)
    private func cameraPosition(for fileName: String) -> SCNVector3 {
        if fileName.contains("Propeller") {
            return SCNVector3(0, 0.1, 1.0)
        } else if fileName.contains("Pirate") {
            return SCNVector3(0, 0.1, 1.5)
        } else if fileName.contains("Cowboy") {
            return SCNVector3(0, 0.1, 0.8)
        } else if fileName.contains("Santa") || fileName.contains("Fox") || fileName.contains("Frog") {
            return SCNVector3(0, 0.1, 0.3)
        } else {
            return SCNVector3(0, 0.1, 0.6)
        }
    }
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        
        // Create scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Set up camera with position matching original RealityKit implementation
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.01
        cameraNode.camera?.zFar = 10.0
        cameraNode.position = cameraPosition(for: fileName)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add lighting matching original implementation
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .directional
        light.light?.intensity = 1500
        light.position = SCNVector3(0.5, 1, 1)
        light.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(light)
        
        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .directional
        ambientLight.light?.intensity = 500
        ambientLight.position = SCNVector3(-0.5, -0.5, -1)
        ambientLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(ambientLight)
        
        // Load hat model
        guard !fileName.isEmpty else {
            return sceneView
        }
        
        guard let usdzURL = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            print("⚠️ Hat file not found: \(fileName).usdz")
            return sceneView
        }
        
        do {
            let hatScene = try SCNScene(url: usdzURL, options: [.checkConsistency: true])
            
            // Create container node for transformations
            let containerNode = SCNNode()
            
            // Add all nodes from the loaded scene
            for child in hatScene.rootNode.childNodes {
                containerNode.addChildNode(child.clone())
            }
            
            // Apply scale (matching original values)
            let scale = previewScale(for: fileName)
            containerNode.scale = SCNVector3(scale, scale, scale)
            
            // Apply position offset (matching original values)
            containerNode.position = previewPosition(for: fileName)
            
            // Apply rotation
            containerNode.eulerAngles.y = previewYRotation(for: fileName)
            
            scene.rootNode.addChildNode(containerNode)
            
        } catch {
            print("❌ Failed to load hat: \(error.localizedDescription)")
        }
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // No updates needed for static preview
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

