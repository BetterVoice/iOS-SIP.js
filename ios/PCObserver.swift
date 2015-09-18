import Foundation

class PCObserver : NSObject, RTCPeerConnectionDelegate {
    var session: Session
    
    init(session: Session) {
        self.session = session
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!,
                        addedStream stream: RTCMediaStream!) {
        // Nothing to do.
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!,
                        removedStream stream: RTCMediaStream!) {
        // Nothing to do.
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!,
                        iceGatheringChanged newState: RTCICEGatheringState) {
        // Nothing to do.
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!,
                        iceConnectionChanged newState: RTCICEConnectionState) {
        // Nothing to do.
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!,
                        gotICECandidate candidate: RTCICECandidate!) {
        // Create a new ICE candidate event.
        let json: AnyObject = [
            "type": "candidate",
            "label": candidate.sdpMLineIndex,
            "id": candidate.sdpMid,
            "candidate": candidate.sdp
        ]
        var error: NSError?
        let data: NSData?
        do {
            data = try NSJSONSerialization.dataWithJSONObject(json,
                        options: NSJSONWritingOptions())
        } catch var error1 as NSError {
            error = error1
            data = nil
        }
        // Try to dispatch the serialized event to the js engine.
        if let message = data {
            self.session.send(message)
        } else {
            if let jsonError = error {
                print("ERROR: \(jsonError.localizedDescription)")
            }
        }
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!,
                        signalingStateChanged stateChanged: RTCSignalingState) {
        // Nothing to do.
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!,
                        didOpenDataChannel dataChannel: RTCDataChannel!) {
        // Nothing to do.
    }
    
    func peerConnectionOnError(peerConnection: RTCPeerConnection!) {
        // Nothing to do.
    }
    
    func peerConnectionOnRenegotiationNeeded(peerConnection: RTCPeerConnection!) {
        // Nothing to do.
    }
}
