import Foundation

class SessionConfig {
    var isInitiator: Bool
    
    init(data: AnyObject) {
        self.isInitiator = data.objectForKey("isInitiator") as Bool
    }
}