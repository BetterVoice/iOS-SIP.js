import Foundation

class WebSocket {
    // Cordova Stuff
    var plugin: PhoneRTCPlugin
    var callbackId: String
    // State Stuff
    var sessionKey: String
    // Web Socket Stuff.
    var socket: SRWebSocket?
    var socketDelegate: WebSocketDelegate
    var url: NSURL
    var protocols: [String]?
    
    init(url: String,
         protocols: [String]?,
         plugin: PhoneRTCPlugin,
         callbackId: String,
         sessionKey: String
        ) {
        self.url = NSURL(string: url)!
        self.protocols = protocols
        self.plugin = plugin
        self.callbackId = callbackId
        self.sessionKey = sessionKey
        let request = NSMutableURLRequest(URL: self.url)
        request.networkServiceType = NSURLRequestNetworkServiceType.NetworkServiceTypeVoIP
        if(self.protocols == nil) {
            self.socket = SRWebSocket(URLRequest: request)
        } else {
            self.socket = SRWebSocket(URLRequest: request, protocols: protocols)
        }
        self.socketDelegate = WebSocketDelegate(plugin: plugin, callbackId: callbackId)
        self.socket!.delegate = self.socketDelegate
        self.socket!.open()
    }
    
    func close(code: Int?, reason: String?) {
        if code != nil {
            self.socket!.closeWithCode(code!, reason: reason)
        } else {
            self.socket!.close()
        }
        self.plugin.destroyWebSocket(self.sessionKey)
    }
    
    func send(data: AnyObject) {
        self.socket!.send(data)
    }
}