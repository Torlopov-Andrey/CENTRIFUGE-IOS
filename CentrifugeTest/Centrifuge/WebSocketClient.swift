import Foundation

class CentrifugeWebSocket: WebSocket {
    
    func send(centrifugeMessage message: CentrifugeClientMessage) throws {
        let dict: [String:Any] = ["uid" : message.uid,
                                  "method" : message.method.rawValue,
                                  "params" : message.params]
        let data = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())
        
        send(data: data)
    }
}
