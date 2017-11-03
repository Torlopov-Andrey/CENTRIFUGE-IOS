import UIKit

typealias MessagesCallback = (CentrifugeServerMessage) -> Void

class ViewController: UIViewController {
    @IBOutlet weak var nickTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tokenTextField: UITextField!
    @IBOutlet weak var signToken: UITextField!
    @IBOutlet weak var timeStamp: UITextField!
    @IBOutlet weak var clientId: UITextField!
    
    let datasource = TableViewDataSource()
    
    var nickName: String {
        get {
            guard let nick = self.nickTextField.text, nick.characters.count > 0 else { return "anonymous" }
            return nick
        }
    }
    
    //MARK:- Interactions with server
    
    var client: CentrifugeClient!
    
    let channel = "$user:private#065a0d37-c57a-48f6-8ead-f0f33ea97c34"
    let user = "065a0d37-c57a-48f6-8ead-f0f33ea97c34"
    var token: String = "4e8c3282460dc9e447fafaf5495c2435cf462e351bec25a6ec96f8fd228e3431"
    var timestamp: String = "1509700515"
        
    var sign: String {
        get {
            guard let sign = self.signToken.text else { return "" }
            return sign
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = datasource
        
        let creds = CentrifugeCredentials(token: self.token, user: user, timestamp: self.timestamp)
        
        let url = "wss://test.cubux.net:8085/connection/websocket"
//        let conf = CentrifugeConfig(url: url, secret: "")
        let conf = CentrifugeConfig(url: url, secret: "secred", authEndpoint: "/centrifugo/auth", authHeaders:[:])
        self.client = Centrifuge.client(conf: conf, creds: creds, delegate: self)
    }

    func publish(_ text: String) {
        client.publish(toChannel: channel, data:  ["nick" : nickName, "input" : text]) { message, error in
            print("publish message: \(String(describing: message))")
        }
    }
    
    //MARK: Presentation
    func addItem(_ title: String, subtitle: String) {
        self.datasource.addItem(TableViewItem(title: title, subtitle: subtitle))
        self.tableView.reloadData()
    }
    
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
                self.clientId.text = c
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
    
    //MARK:- Interactions with user
    
    @IBAction func sendButtonDidPress(_ sender: AnyObject) {
        if let text = messageTextField.text, text.characters.count > 0 {
            messageTextField.text = ""
            publish(text)
        }
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
//            self.client.subscribe(toChannel: <#T##String#>, delegate: <#T##CentrifugeChannelDelegate#>, lastMessageUID: <#T##String#>, completion: <#T##CentrifugeMessageHandler##CentrifugeMessageHandler##(CentrifugeServerMessage?, NSError?) -> Void#>)
            
//            subscribe(toChannel: self.channel, delegate: self, additionalParams:["client":self.clientId.text!,"info":"","sign":self.sign], completion: self.showResponse)
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

extension ViewController {
    
    func getSign(authToken: String, clientId: String, completion: (String)->()) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        guard let url = URL(string: "https://test.cubux.net/centrifugo/auth") else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let bodyObject: [String : Any] = [
            "channels": [
                "$user:private#065a0d37-c57a-48f6-8ead-f0f33ea97c34"
            ],
            "client": clientId
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
}

//MARK: CentrifugeClientDelegate

extension ViewController: CentrifugeClientDelegate {
    
    func client(_ client: CentrifugeClient, didReceiveError error: NSError) {
        showError(error)
    }
    
    func client(_ client: CentrifugeClient, didDisconnect message: CentrifugeServerMessage) {
        print("didDisconnect message: \(message)")
        datasource.removeAll()
        tableView.reloadData()
    }
    
    func client(_ client: CentrifugeClient, didReceiveRefresh message: CentrifugeServerMessage) {
        print("didReceiveRefresh message: \(message)")
    }
}

//MARK: CentrifugeChannelDelegate

extension ViewController: CentrifugeChannelDelegate {
    
    func client(_ client: CentrifugeClient, didReceiveMessageInChannel channel: String, message: CentrifugeServerMessage) {
        if let data = message.body?["data"] as? [String : AnyObject], let input = data["input"] as? String, let nick = data["nick"] as? String {
            addItem(nick, subtitle: input)
        }
    }
    
    func client(_ client: CentrifugeClient, didReceiveJoinInChannel channel: String, message: CentrifugeServerMessage) {
        if let data = message.body?["data"] as? [String : AnyObject], let user = data["user"] as? String {
            addItem(message.method.rawValue, subtitle: user)
        }
    }
    
    func client(_ client: CentrifugeClient, didReceiveLeaveInChannel channel: String, message: CentrifugeServerMessage) {
        if let data = message.body?["data"] as? [String : AnyObject], let user = data["user"] as? String {
            addItem(message.method.rawValue, subtitle: user)
        }
    }
    
    func client(_ client: CentrifugeClient, didReceiveUnsubscribeInChannel channel: String, message: CentrifugeServerMessage) {
        print("didReceiveUnsubscribeInChannel \(message)"   )
    }
}
