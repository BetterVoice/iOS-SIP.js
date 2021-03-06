import Foundation

class WebSocketDelegate : NSObject, SRWebSocketDelegate {
    // Cordova Stuff
    var plugin: PhoneRTCPlugin
    var callbackId: String
    
    init(plugin: PhoneRTCPlugin, callbackId: String) {
        self.plugin = plugin
        self.callbackId = callbackId
    }
    
    func dispatch(json: AnyObject) {
        var error: NSError?
        let data: NSData?
        do {
            data = try NSJSONSerialization.dataWithJSONObject(json,
                        options: NSJSONWritingOptions())
        } catch let error1 as NSError {
            error = error1
            data = nil
        }
        if let message = data {
            self.plugin.dispatch(self.callbackId, message: message)
        } else {
            if let jsonError = error {
                print("ERROR: \(jsonError.localizedDescription)")
            }
        }
    }
    
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        print("INFO: A Web Socket has been opened.")
        let json: AnyObject = ["name": "onopen"]
        dispatch(json)
    }
    
    func webSocket(websocket: SRWebSocket!, didFailWithError error: NSError!) {
        print("INFO: A Web Socket has failed with an error.")
        let json: AnyObject = [
            "name": "onerror",
            "parameters": [error.localizedDescription]
        ]
        dispatch(json)
    }
    
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: NSInteger!,
                   reason: NSString!, wasClean: DarwinBoolean!) {
        print("INFO: A Web Socket has been closed with code \"\(code)\" and reason \"\(reason)\".")
        var object: AnyObject
        if(wasClean != nil) {
            object = ["code": code, "reason": reason, "wasClean": true]
        } else {
            object = ["code": code, "reason": reason, "wasClean": false]
        }
        let json: AnyObject = [
            "name": "onclose",
            "parameters": [object]
        ]
        dispatch(json)
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        print("INFO: Received a message: \(message)")
        let object: AnyObject = ["data": message]
        let json: AnyObject = [
            "name": "onmessage",
            "parameters": [object]
        ]
        dispatch(json)
    }
}
