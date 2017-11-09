import UIKit

typealias MessagesCallback = (CentrifugeServerMessage) -> Void

class ViewController: UIViewController {
    var client: CentrifugeClient!
    let channel = "$user:private#065a0d37-c57a-48f6-8ead-f0f33ea97c34"
    let user = "065a0d37-c57a-48f6-8ead-f0f33ea97c34"
    
    let timestamp: String = "1510223303"
    let token: String = "c521698f9f4cdefc6d445d9d304fa305682f2e7474b77f3de0e16208be815233"
    var authUrl: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = "wss://test.cubux.net:8085/connection/websocket"
        self.authUrl = URL(string: "https://test.cubux.net/centrifugo/auth")!
        let creds = CentrifugeCredentials(token: self.token, user: user, timestamp: self.timestamp)

        let conf = CentrifugeConfig(url: url)
        self.client = Centrifuge.client(conf: conf, creds: creds, delegate: self)
    }

    func publish(_ text: String) {
        debugPrint("no realisation: publish message...")
    }
    
    //MARK:- Presentation
    
    func showAlert(_ title: String, message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let close = UIAlertAction(title: "Close", style: .cancel) { _ in
            vc.dismiss(animated: true, completion: nil)
        }
        vc.addAction(close)
        
        show(vc, sender: self)
    }
    
    func showError(_ error: Any) {
        showAlert("Error", message: "\(error)")
    }
    
    func showMessage(_ message: CentrifugeServerMessage) {
        showAlert("Message", message: "\(message)")
    }
    
    func showResponse(_ message: CentrifugeServerMessage?, error: NSError?) {
        
        if let msg = message {
            debugPrint("******************************")
            debugPrint("showResponse, msg: \(msg)")
            if let body = msg.body,
                let c = body["client"] as? String {
                let headers = ["Content-type": "application/json; charset=UTF-8", "User-Agent": "Cubux:ios", "Authorization": "Bearer e109dddb5bc6f976d78cc6d7a947e6b5e83f7b31"]
                
                self.client.setAuthRequest(request: self.getAuthRequest(clientId: c, headers: headers))
            }
            showMessage(msg)
            debugPrint("******************************")
        }
        else if let err = error {
            debugPrint("******************************")
            debugPrint("showResponse, err: \(err)")
            showError(err)
            debugPrint("******************************")
        }
    }
    
    func getAuthRequest(clientId: String, headers: [String: String]) -> URLRequest {
        var authRequest = URLRequest(url: self.authUrl)
        authRequest.httpMethod = "POST"
        
        headers.forEach { (key:String, value: String) in
            authRequest.setValue(value , forHTTPHeaderField: key)
        }
        
        let bodyDictionary: [String : Any] = ["channels":["$user:private#065a0d37-c57a-48f6-8ead-f0f33ea97c34"], "client":clientId]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: bodyDictionary, options: []) {
            authRequest.httpBody = jsonData
        }
        return authRequest
    }
    
    @IBAction func actionButtonDidPress() {
        let alert = UIAlertController(title: "Choose command", message: nil, preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(cancel)
        
        let connect = UIAlertAction(title: "Connect", style: .default) { _ in
            self.client.connect(withCompletion: self.showResponse)
        }
        alert.addAction(connect)
        
        let disconnect = UIAlertAction(title: "Disconnect", style: .default) { _ in
            self.client.disconnect()
        }
        alert.addAction(disconnect)
        
        let ping = UIAlertAction(title: "Ping", style: .default) { _ in
            self.client.ping(withCompletion: self.showResponse)
        }
        alert.addAction(ping)
        
        let subscribe = UIAlertAction(title: "Subscribe to \(channel)", style: .default) { _ in
            self.client.subscribe(toChannel: self.channel, delegate: self, completion: self.showResponse)
        }
        alert.addAction(subscribe)
        
        let unsubscribe = UIAlertAction(title: "Unsubscribe from \(channel)", style: .default) { _ in
            self.client.unsubscribe(fromChannel: self.channel, completion: self.showResponse)
        }
        alert.addAction(unsubscribe)
        
        let history = UIAlertAction(title: "History \(channel)", style: .default) { _ in
            self.client.history(ofChannel: self.channel, completion: self.showResponse)
        }
        alert.addAction(history)
        
        let presence = UIAlertAction(title: "Presence \(channel)", style: .default) { _ in
            self.client.presence(inChannel: self.channel, completion:self.showResponse)
        }
        alert.addAction(presence)
        
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: CentrifugeClientDelegate {

    func client(_ client: CentrifugeClient, didReceiveError error: NSError) {
        showError(error)
    }
    
    func client(_ client: CentrifugeClient, didDisconnect message: CentrifugeServerMessage) {
        print("didDisconnect message: \(message)")
    }
    
    func client(_ client: CentrifugeClient, didReceiveRefresh message: CentrifugeServerMessage) {
        print("didReceiveRefresh message: \(message)")
    }
}

//MARK: CentrifugeChannelDelegate

extension ViewController: CentrifugeChannelDelegate {
    
    func client(_ client: CentrifugeClient, didReceiveMessageInChannel channel: String, message: CentrifugeServerMessage) {
        debugPrint("message in channel: \(message)")
    }
    
    func client(_ client: CentrifugeClient, didReceiveJoinInChannel channel: String, message: CentrifugeServerMessage) {
        debugPrint("Join in channel: \(message)")
    }
    
    func client(_ client: CentrifugeClient, didReceiveLeaveInChannel channel: String, message: CentrifugeServerMessage) {
        debugPrint("leave channel: \(message)")
    }
    
    func client(_ client: CentrifugeClient, didReceiveUnsubscribeInChannel channel: String, message: CentrifugeServerMessage) {
        print("didReceiveUnsubscribeInChannel \(message)"   )
    }
}
