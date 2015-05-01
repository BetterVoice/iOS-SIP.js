import Foundation
import AVFoundation

@objc(PhoneRTCPlugin)
class PhoneRTCPlugin : CDVPlugin {
    var application: UIApplication
    var peerConnectionFactory: RTCPeerConnectionFactory
    var sessions: [String: Session]
    var sockets: [String: WebSocket]
    
    override init(webView: UIWebView) {
        application = UIApplication.sharedApplication()
        peerConnectionFactory = RTCPeerConnectionFactory()
        RTCPeerConnectionFactory.initializeSSL()
        sessions = [:]
        sockets = [:]
        super.init(webView: webView)
    }
    
    func createSession(command: CDVInvokedUrlCommand) {
        if let sessionKey = command.argumentAtIndex(0) as? String {
            if let args: AnyObject = command.argumentAtIndex(1) {
                let config = SessionConfig(data: args)
                let session = Session(config: config, peerConnectionFactory: peerConnectionFactory,
                    plugin: self, callbackId: command.callbackId, sessionKey: sessionKey)
                sessions[sessionKey] = session
            }
        }
    }

    func destroySession(sessionKey: String) {
        self.sessions.removeValueForKey(sessionKey)
    }

    func createWebSocket(command: CDVInvokedUrlCommand) {
        let url = command.argumentAtIndex(0) as? String
        let protocols = command.argumentAtIndex(1) as? [String]
        let key = command.argumentAtIndex(2) as? String
        if url != nil && key != nil {
            let socket = WebSocket(url: url!, protocols: protocols,
                plugin: self, callbackId: command.callbackId,
                sessionKey: key!)
            sockets[key!] = socket
        }
    }

    func destroyWebSocket(sessionKey: String) {
        self.sockets.removeValueForKey(sessionKey)
    }
    
    func close(command: CDVInvokedUrlCommand) {
        let code = command.argumentAtIndex(0) as? Int
        let reason = command.argumentAtIndex(1) as? String
        let key = command.argumentAtIndex(2) as? String
        if key != nil {
            self.sockets[key!]!.close(code, reason: reason)
        }
    }

    func disconnect(command: CDVInvokedUrlCommand) {
        let args: AnyObject = command.argumentAtIndex(0)
        if let sessionKey = args.objectForKey("sessionKey") as? String {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if (self.sessions[sessionKey] != nil) {
                    self.sessions[sessionKey]!.disconnect()
                }
            }
        }
    }
    
    func dispatch(callbackId: String, message: NSData) {
        let json = NSJSONSerialization.JSONObjectWithData(message,
            options: NSJSONReadingOptions.MutableLeaves,
            error: nil) as NSDictionary
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: json)
        pluginResult.setKeepCallbackAsBool(true);
        self.commandDelegate.sendPluginResult(pluginResult, callbackId: callbackId)
    }
    
    func initialize(command: CDVInvokedUrlCommand) {
        let args: AnyObject = command.argumentAtIndex(0)
        if let sessionKey = args.objectForKey("sessionKey") as? String {
            dispatch_async(dispatch_get_main_queue()) {
                if let session = self.sessions[sessionKey] {
                    session.initialize()
                }
            }
        }
    }
    
    func receive(command: CDVInvokedUrlCommand) {
        let args: AnyObject = command.argumentAtIndex(0)
        if let sessionKey = args.objectForKey("sessionKey") as? String {
            if let message = args.objectForKey("message") as? String {
                if let session = self.sessions[sessionKey] {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                        session.receive(message)
                    }
                }
            }
        }
    }
    
    func registerHandler(command: CDVInvokedUrlCommand) {
        let timeout = command.argumentAtIndex(0) as? Double
        if timeout != nil {
            self.application.setKeepAliveTimeout(timeout!, handler: {() -> Void in
                self.dispatch(command.callbackId, message: "{\"name\": \"ontimeout\"}".dataUsingEncoding(NSUTF8StringEncoding)!)
            })
        }
    }
    
    func send(command: CDVInvokedUrlCommand) {
        let data: AnyObject? = command.argumentAtIndex(0)
        let key = command.argumentAtIndex(1) as? String
        if data != nil && key != nil {
            self.sockets[key!]!.send(data!)
        }
    }

    func toggleMute(command: CDVInvokedUrlCommand) {
        let args: AnyObject = command.argumentAtIndex(0);
        if let sessionKey = args.objectForKey("sessionKey") as? String {
            if let mute: Bool = args.objectForKey("mute") as? Bool {
                dispatch_async(dispatch_get_main_queue()) {
                    if let session = self.sessions[sessionKey] {
                        session.toggleMute(mute)
                    }
                }
            }
        }
    }
    
    func unregisterHandler(command: CDVInvokedUrlCommand) {
        self.application.clearKeepAliveTimeout()
    }
}