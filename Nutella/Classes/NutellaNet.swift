//
//  NutellaNet.swift
//  NutellaLib

import Foundation

/**
 This class is the Nutella module that takes care of the network connections and message delivery.
 */
open class NutellaNet: SimpleMQTTClientDelegate {
    
    class Subscription {
        var subscribe: Bool
        var request: Bool
        var response: Bool
        
        init(subscribe: Bool, request: Bool, response: Bool) {
            self.subscribe = subscribe
            self.request = request
            self.response = response
        }
        
        var subscribed: Bool {
            return subscribe || request || response
        }
    }
    
    
    weak var delegate: NutellaNetDelegate?
    weak var configDelegate: NutellaConfigDelegate?
    
    var mqtt: SimpleMQTTClient
    var host: String
    
    // Requests informations
    var requests = [Int:NutellaNetRequest]()
    
    // Subscribed channels
    var subscribed : [String: Subscription] = [String: Subscription]()
    
    // Application run ID
    var urlInit: String {
        get {
            if let runId = self.configDelegate?.runId {
                if let appId = self.configDelegate?.appId {
                    return "/nutella/apps/" + appId + "/runs/" + runId + "/"
                }
                else {
                    return "/"
                }
            }
            else {
                return "/"
            }
        }
    }
    
    /**
     Initialize the module connecting it to the Nutella server.
     
     - parameter host: Hostname of the Nutella server.
     - parameter clientId: The client id. Leave it nil.
     */
    public init(host: String, clientId optionalClientId: String?) {
        self.mqtt = SimpleMQTTClient(host: host, synchronous: true, clientId: optionalClientId)
        self.host = host
        self.mqtt.delegate = self
        
        if(DEBUG) {
            print("[\(self)] init host: \(host) optionalClientId: \(optionalClientId)")
        }
    }
    
    /**
     Subscribe to a Nutella channel. Every time it will receive a message the delegate function messageReceived will be called.
     
     - parameter channel: The Nutella channel that you want to subscribe.
     */
    open func subscribe(_ channel: String) {
        if let subscription = self.subscribed[channel] {
            if subscription.subscribe != true {
                mqtt.subscribe(urlInit+channel)
                subscription.subscribe = true
            }
            else {
                print("WARNING: you're already subscribed to the channel " + channel)
            }
        }
        else {
            mqtt.subscribe(urlInit+channel)
            self.subscribed[channel] = Subscription(subscribe: true, request: false, response: false)
        }
    }
    
    /**
     Unsubscribe from a Nutella channel.
     
     - parameter channel: The Nutella channel that you want to unsubscribe.
     */
    open func unsubscribe(_ channel: String) {
        if(DEBUG) {
            print("[\(self)] unsubscribe channel: \(channel)")
        }
        
        if let subscription = self.subscribed[channel] {
            if subscription.subscribe == true {
                subscription.subscribe = false
                if subscription.subscribed == false {
                    mqtt.unsubscribe(urlInit+channel)
                }
            }
        }
        else {
            print("WARNING: you're not subscribed to the channel "+channel)
        }
    }
    
    /**
     Upload file and return the URL which it can be found
     
     upload
     POST http://localhost:57882/upload
     
    - parameter file: The file to upload to nutella
    */
    /*
    open func upload(withFile file: Data, andFilename filename: String) -> URL?  {
                        
        // Add Headers
        let headers = ["Content-Type":"multipart/form-data; charset=utf-8; boundary=__X_PAW_BOUNDARY__"]
        
        let uploadUrl = "http://\(host):57882/upload"
        
        // Fetch Request
        
        //"d41d8cd98f00b204e9800998ecf8427e.jpg".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let md5filename = "\(filename.fileName().md5()).\(filename.fileExtension())"
        let filenameData = md5filename.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(filenameData, withName: "filename")
                multipartFormData.append(file, withName: "file")
            },
            to: uploadUrl,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
            }
        )
        
  
        return nil
    }
 */
    
    
    /**
     Publish a message on a Nutella channel.
     
     - parameter channel: The Nutella channel where you want to publish.
     */
    open func publish(_ channel: String, message: AnyObject) {
        if(DEBUG) {
            print("[\(self)] publish channel: \(channel)")
        }
        
        let componentId: String = self.configDelegate!.componentId;
        let applicationId: String = self.configDelegate!.appId;
        let runId: String = self.configDelegate!.runId;
        
        let from: [String:AnyObject] = ["type":"run" as AnyObject,
                                        "run_id": runId as AnyObject,
                                        "app_id": applicationId as AnyObject,
                                        "component_id": componentId as AnyObject
        ];
        
        var finalMessage: [String:AnyObject] = [String:AnyObject]()
        
        finalMessage = [
            "from": from as AnyObject,
            "type": "publish" as AnyObject,
            "payload": message
        ]
        
        let json = JSON(finalMessage)
        
        mqtt.publish(urlInit+channel, message: json.rawString()!)
    }
    
    /**
     Execute an asychronous request of information on the specified Nutella channel.
     
     - parameter channel: The name of the channel on which executing the request.
     - parameter message: A message that can be bot Dictionary or a String
     - parameter requestName: An optional name assigned to the request in order to recognize it later.
     */
    open func asyncRequest(_ channel: String, message: AnyObject, requestName: String?) {
        if(DEBUG) {
            print("[\(self)] asyncRequest channel: \(channel) requestName: \(requestName)")
        }
        
        let componentId: String = self.configDelegate!.componentId;
        let applicationId: String = self.configDelegate!.appId;
        let runId: String = self.configDelegate!.runId;
        
        let id = Int(arc4random_uniform(1000000000))
        
        let from: [String:AnyObject] = ["type":"run" as AnyObject,
                                        "run_id": runId as AnyObject,
                                        "app_id": applicationId as AnyObject,
                                        "component_id": componentId as AnyObject
        ];
        
        requests[id] = NutellaNetRequest(channel: channel,
                                         id: id,
                                         name: requestName,
                                         message: message)
        
        if let subscription = self.subscribed[channel] {
            if subscription.subscribed == false {
                mqtt.subscribe(urlInit+channel)
            }
            
            if subscription.response == false {
                subscription.response = true
            }
            else {
                print("WARNING: you're already requesting on the channel "+channel)
            }
        }
        else {
            self.subscribed[channel] = Subscription(subscribe: false, request: false, response: true)
            mqtt.subscribe(urlInit+channel)
        }
        
        let finalMessage: [String:AnyObject] = [
            "id": id as AnyObject,
            "from": from as AnyObject,
            "type": "request" as AnyObject,
            "payload": message
        ]
        
        let json = JSON(finalMessage)
        mqtt.publish(urlInit+channel, message: json.rawString()!)
    }
    
    /**
     Not yet implemented, sorry, use asyncRequest that is almost the same
     */
    open func syncRequest(_ channel: String, message: String, requestName: String?) {
        print("WARNING: syncRequest method is not yet implemented, use asyncRequest")
    }
    
    /**
     Handle a request coming from a client. The delegate function requestReceived will be invoked every time a new request is received.
     
     - parameter channel: The name of the Nutella channel on which listening.
     */
    open func handleRequest(_ channel: String) {
        
        if(DEBUG) {
            print("[\(self)] handleRequest channel: \(channel)")
        }
        
        if let subscription = self.subscribed[channel] {
            if subscription.subscribed == false {
                mqtt.subscribe(urlInit+channel)
            }
            
            if subscription.request == false {
                subscription.request = true
            }
            else {
                print("WARNING: you're already handling requests on the channel "+channel)
            }
        }
        else {
            self.subscribed[channel] = Subscription(subscribe: false, request: true, response: false)
            mqtt.subscribe(urlInit+channel)
        }
    }
    
    /**
     Stop handing requests on the specified channel.
     
     - parameter channel: The Nutella channel on wich stopping to receiving requests.
     */
    open func unhandleRequest(_ channel: String) {
        
        if(DEBUG) {
            print("[\(self)] unhandleRequest channel: \(channel)")
        }
        
        _ = urlInit + channel
        
        if let subscription = self.subscribed[channel] {
            if subscription.request == true {
                subscription.request = false
            }
            else {
                print("WARNING: You're not handling the requests on channel "+channel)
            }
            
            if subscription.subscribed == false {
                mqtt.unsubscribe(urlInit+channel)
            }
        }
        else {
            print("WARNING: You're not handling the requests on channel "+channel)
        }
        
    }
    
    // MARK: SimpleMQTTClientDelegate
    @objc open func messageReceived(_ channel: String, message: String) {
        
        if(DEBUG) {
            //print("[\(self)] messageReceived channel: \(channel) message: message")
        }
        
        if(channel == "") {
            return  // Discard messages arriving from nowhere
        }
        
        // Extract the eventual wildcard
        let wildcard = mqtt.wildcardSubscribed(channel)
        
        // Remove the runId from the channel
        var path:[String] = channel.components(separatedBy: "/")
        
        if path.count < 6 {
            return
        }
        
        path.remove(at: 0)
        path.remove(at: 0)
        path.remove(at: 0)
        path.remove(at: 0)
        path.remove(at: 0)
        path.remove(at: 0)
        let newChannel = path.joined(separator: "/")
        
        var subscriptionKey = newChannel
        
        if var w = wildcard {
            // Remove the runId from the wildcard
            path = w.components(separatedBy: "/")
            path.remove(at: 0)
            path.remove(at: 0)
            path.remove(at: 0)
            path.remove(at: 0)
            path.remove(at: 0)
            path.remove(at: 0)
            w = path.joined(separator: "/")
            
            subscriptionKey = w
        }
        
        let data:Data! = message.data(using: String.Encoding.utf8,
                                      allowLossyConversion: true)
        
        let json = JSON(data:data)
        if json != nil {
            //condition 1 either request or response
            if let id = json["id"].int {
                if let type = json["type"].string, let _ = json["from"].dictionary {
                    let fromDict = parseFromComponents(withJson: json["from"])
                    switch type {
                    case "request":
                        
                        if self.subscribed[subscriptionKey]?.request == true {
                            var payload: Any? = nil
                            if json["payload"] != nil {
                                payload = json["payload"].object
                            }
                            
                            
                            // Reply if the delegate implements the requestReceived function
                            if let reply: Any = self.delegate?.requestReceived(newChannel, request: payload, from: fromDict) {
                                
                                let componentId: String = self.configDelegate!.componentId;
                                let applicationId: String = self.configDelegate!.appId;
                                let runId: String = self.configDelegate!.runId;
                                
                                //Publish the response
                                let from: [String:Any] = ["type":"run" as Any,
                                                          "run_id": runId as Any,
                                                          "app_id": applicationId as Any,
                                                          "component_id": componentId as Any
                                ];
                                
                                var finalMessage: [String:Any] = [
                                    "id": id as Any,
                                    "from": from as Any,
                                    "type": "response" as Any]
                                
                                finalMessage["payload"] = reply
                                
                                let json = JSON(finalMessage)
                                mqtt.publish(channel, message: json.rawString()!)
                                
                                //requestResponse = true
                            }
                        }
                        
                        
                        break
                    case "response":
                        var payload: Any?
                        
                        if json["payload"] != nil {
                            payload = json["payload"].object
                        }
                        
                        let fromDict = parseFromComponents(withJson: json["from"])
                        
                        if let request = requests[id] {
                            if self.subscribed[subscriptionKey]?.response == true {
                                self.delegate?.responseReceived(newChannel, requestName: request.name, response: payload, from: fromDict)
                                self.subscribed[subscriptionKey]!.response = false
                                
                                if self.subscribed[subscriptionKey]!.subscribed == false {
                                    mqtt.unsubscribe(channel)
                                }
                            }
                        }
                        break
                    default:
                        //send empty message
                        break
                    }
                }
                
            } else {
                //condition 2 from subscription
                if let type = json["type"].string, let _ = json["from"].dictionary {
                    //print("channel: \(channel), type: \(type), from: \(from), message: \(message)")
                    
                    switch type {
                    case "publish":
                        
                        let fromDict = parseFromComponents(withJson: json["from"])
                        
                        if json["payload"] != nil {
                            let payload = json["payload"].object
                            if self.subscribed[subscriptionKey]?.subscribe == true {
                                self.delegate?.messageReceived(newChannel, message: payload, from: fromDict)
                            }
                        }
                        break
                    default:
                        //send empty message
                        break
                    }
                    
                }
            }
        } else {
            print("error parsing json messageReceived on channel: \(channel) with message: \(message)")
        }
    }
    
    /**
     * { "run_id" : "default", "type" : "run", "app_id" : "wallcology", "component_id" : "species-notes"}
     **/
    func parseFromComponents(withJson fromJson: JSON) -> [String:String] {
        
        var from = [String:String]()
        
        if fromJson == nil {
            return from
        }
        
        if let componentId = fromJson["component_id"].string {
            from["component_id"] = componentId
        }
        
        if let type = fromJson["type"].string {
            from["type"] = type
            
        }
        
        if let appId = fromJson["app_id"].string {
            from["app_id"] = appId
        }
        
        if let runId = fromJson["run_id"].string {
            from["run_id"] = runId
        }
        
        return from
    }
    
    open func disconnected() {
        // Do nothing and wait for the reconnection
    }
    
    open func sessionConnected() -> Bool {
        return mqtt.isConnect()
    }
}
