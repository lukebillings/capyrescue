import Foundation
import AppTrackingTransparency

@MainActor
class TrackingManager: ObservableObject {
    @Published var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    static let shared = TrackingManager()
    
    private init() {
        updateTrackingStatus()
    }
    
    func updateTrackingStatus() {
        trackingAuthorizationStatus = ATTrackingManager.trackingAuthorizationStatus
    }
    
    /// Request tracking authorization if needed
    func requestTrackingAuthorizationIfNeeded() async {
        let status = ATTrackingManager.trackingAuthorizationStatus
        
        // Only request if status is not determined
        if status == .notDetermined {
            let newStatus = await ATTrackingManager.requestTrackingAuthorization()
            trackingAuthorizationStatus = newStatus
        } else {
            trackingAuthorizationStatus = status
        }
    }
    
    /// Check if tracking authorization has been determined (not .notDetermined)
    var hasRequestedTracking: Bool {
        return trackingAuthorizationStatus != .notDetermined
    }
}


