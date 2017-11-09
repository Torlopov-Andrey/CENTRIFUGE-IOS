import Foundation

public struct CentrifugeClientMessage {
    public let uid: String
    public let method: CentrifugeMethod
    public let params: [String : Any]
}

extension CentrifugeClientMessage: Equatable {}

public func ==(lhs: CentrifugeClientMessage, rhs: CentrifugeClientMessage) -> Bool {
    return lhs.uid == rhs.uid
}

public struct CentrifugeServerMessage {
    public let uid: String?
    public let method: CentrifugeMethod
    public let error: String?
    public let body: [String : AnyObject]?
}

extension CentrifugeServerMessage: Equatable {}

public func ==(lhs: CentrifugeServerMessage, rhs: CentrifugeServerMessage) -> Bool {
    if let luid = lhs.uid, let ruid = rhs.uid {
        return luid == ruid
    }
    return false
}

public struct CentrifugeCredentials {
    let token : String
    let user : String
    let timestamp : String
    let info: String?
    
    public init(token: String, user: String, timestamp:String, info: String? = nil) {
        self.token = token
        self.user = user
        self.timestamp = timestamp
        self.info = info
    }
}

public struct CentrifugeConfig {
    let url: String
    var authRequest: URLRequest?
    
    public init(url: String, authRequest: URLRequest?) {
        self.url = url
        self.authRequest = authRequest        
    }
    
    public init(url: String) {
        self.url = url
        self.authRequest = nil
    }
    
    mutating func setRequest(request: URLRequest) {
        self.authRequest = request
    }
}

public enum CentrifugeMethod : String {
    case Connect = "connect"
    case Disconnect = "disconnect"
    case Subscribe = "subscribe"
    case Unsubscribe = "unsubscribe"
    case Publish = "publish"
    case Presence = "presence"
    case History = "history"
    case Join = "join"
    case Leave = "leave"
    case Message = "message"
    case Refresh = "refresh"
    case Ping = "ping"
}

class CentrifugeWrapper<T> {
    var value: T
    init(theValue: T) {
        value = theValue
    }
}

extension NSError {
    static func errorWithMessage(message: CentrifugeServerMessage) -> NSError {
        let error = NSError(domain: CentrifugeErrorDomain,
                            code: CentrifugeErrorCode.CentrifugeMessageWithError.rawValue,
                            userInfo: [NSLocalizedDescriptionKey : message.error!, CentrifugeErrorMessageKey : CentrifugeWrapper(theValue: message)])
        return error
    }
}
