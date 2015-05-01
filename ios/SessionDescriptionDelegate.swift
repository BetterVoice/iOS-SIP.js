import Foundation

class SessionDescriptionDelegate : UIResponder, RTCSessionDescriptionDelegate {
    var session: Session
    
    init(session: Session) {
        self.session = session
    }
    
    func getInterfaces() -> [(name: String, address: String)] {
        var addresses: [(name: String, address: String)] = []
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {
            // For each interface ...
            for var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next {
                let flags = Int32(ptr.memory.ifa_flags)
                var addr = ptr.memory.ifa_addr.memory
                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        if getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            if let address = String.fromCString(hostname) {
                                let name = NSString(UTF8String: ptr.memory.ifa_name)! as String
                                addresses.append(name: name, address: address)
                            }
                        }
                        
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return addresses
    }
    
    func patchSessionDescription(sdp: String) -> String {
        var patched = ""
        // Select an active network interface device to use.
        var interface: (name: String, address: String)? = nil
        let interfaces = self.getInterfaces()
        // Always try to use the wifi adapter when available and if not fallback to
        // the first active interface.
        if interfaces.count > 0 {
            for item in interfaces {
                if(item.name == "en0") {
                    interface = item
                }
            }
            if interface == nil {
                interface = interfaces[0]
            }
        }
        // Patch the session description.
        let lines = sdp.componentsSeparatedByString("\r\n")
        for line in lines {
            if line.hasPrefix("c=IN IP4") || line.hasPrefix("a=rtcp:") {
                if interface != nil {
                    patched += line.stringByReplacingOccurrencesOfString("0.0.0.0", withString: interface!.address) + "\r\n"
                }
            } else if line.hasPrefix("m=audio") {
                patched += line.stringByReplacingOccurrencesOfString("RTP/SAVPF", withString: "UDP/TLS/RTP/SAVPF") + "\r\n"
            } else {
                patched += line + "\r\n"
            }
        }
        return patched
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!,
        didCreateSessionDescription sdp: RTCSessionDescription!, error: NSError!) {
            // Set the local session description and dispatch a copy to the js engine.
            if error == nil {
                self.session.peerConnection.setLocalDescriptionWithDelegate(self, sessionDescription: sdp)
                dispatch_async(dispatch_get_main_queue()) {
                    let json: AnyObject = [
                        "type": sdp.type,
                        "sdp": self.patchSessionDescription(sdp.description)
                    ]
                    var jsonError: NSError?
                    let data = NSJSONSerialization.dataWithJSONObject(json,
                        options: NSJSONWritingOptions.allZeros,
                        error: &jsonError)
                    if let message = data {
                        self.session.send(data!)
                    } else {
                        if let serializationError = jsonError {
                            println("ERROR: \(serializationError.localizedDescription)")
                        }
                    }
                }
            } else {
                println("ERROR: \(error.localizedDescription)")
            }
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!,
        didSetSessionDescriptionWithError error: NSError!) {
            // If we are acting as the callee then generate an answer to the offer.
            if error == nil {
                dispatch_async(dispatch_get_main_queue()) {
                    if !self.session.config.isInitiator &&
                        self.session.peerConnection.localDescription == nil {
                            self.session.peerConnection.createAnswerWithDelegate(self, constraints: self.session.peerConnectionConstraints)
                    }
                }
            } else {
                println("ERROR: \(error.localizedDescription)")
            }
    }
}