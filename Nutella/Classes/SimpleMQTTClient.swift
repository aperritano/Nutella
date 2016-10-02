//
//  SimpleMQTTClient.swift
//  Test
//
//  Created by Gianluca Venturini & Anthony Perritano

import Foundation
import MQTTClient
/**
 This class provide a simple interface that let you use the MQTT protocol
 */
public class SimpleMQTTClient: NSObject, MQTTSessionDelegate {
    
    // Options
    public var synchronous = false
    
    var session: MQTTSession
    
    // Subscribed channels
    var subscribedChannels: [String: Bool]
    var subscribedChannelMessageIds: [Int: String]
    var unsubscribedChannelMessageIds: [Int: String]
    
    // Session variables
    var sessionConnected = false
    var sessionError = false
    
    // Server hostname
    var host: String? = nil
    
    // Delegate
    public weak var delegate: SimpleMQTTClientDelegate?
    
    /**
     Delegate initializer.
     
     - parameter synchronous: If true the client is synchronous, otherwise all the functions will return immediately without waiting for acks.
     - parameter clientId: The client id used internally by the protocol. You need to have a good reason for set this, otherwise it is better to let the function generate it for you.
     */
    public init(synchronous: Bool, clientId optionalClientId: String? = nil) {
        
        self.synchronous = synchronous
        
        if let clientId = optionalClientId {
            session = MQTTSession(
                clientId: clientId,
                userName: nil,
                password: nil,
                keepAlive: 60,
                cleanSession: true,
                will: false,
                willTopic: nil,
                willMsg: nil,
                willQoS: .atMostOnce,
                willRetainFlag: false,
                protocolLevel: 4,
                runLoop: nil,
                forMode: nil
            )
        }
        else {
            // Random generate clientId
            let chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
            let length = 22;    // Imposed by MQTT protocol
            var clientId = String();
            
            for _ in (0...length).reversed() {
                clientId += chars[Int(arc4random_uniform(UInt32(length)))];
            }
            
            
            
            session = MQTTSession(
                clientId: clientId,
                userName: nil,
                password: nil,
                keepAlive: 60,
                cleanSession: true,
                will: false,
                willTopic: nil,
                willMsg: nil,
                willQoS: .atMostOnce,
                willRetainFlag: false,
                protocolLevel: 4,
                runLoop: nil,
                forMode: nil
            )
        }
        
        self.subscribedChannels = [:]
        self.subscribedChannelMessageIds = [:]
        self.unsubscribedChannelMessageIds = [:]
        
        super.init()
        session.delegate = self;
    }
    
    /**
     Convenience initializers. It inizialize the client and connect to a server
     
     - parameter host: The hostname.
     - parameter synchronous: If synchronous or not
     - parameter clientId: An optional client id, you need to have a good reason for setting this, otherwise let the system generate it for you.
     
     */
    public convenience init(host: String, synchronous: Bool, clientId optionalClientId: String? = nil) {
        self.init(synchronous: synchronous, clientId: optionalClientId)
        connect(host)
    }
    
    /**
     Subscribe to an MQTT channel.
     
     - parameter channel: The name of the channel.
     */
    public func subscribe(_ channel: String) {
        while !sessionConnected && !sessionError {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
        }
        
        _ = 0
        
        if(synchronous) {
            if session.subscribeAndWait(toTopic: channel, at: .atMostOnce) {
                subscribedChannels[channel] = true
            }
        }
        else {
            let messageId = Int(session.subscribe(toTopic: channel, at: .atMostOnce))
            subscribedChannelMessageIds[messageId] = channel
        }
        
    }
    
    /**
     Unsubscribe from an MQTT channel.
     
     - parameter channel: The name of the channel.
     */
    public func unsubscribe(_ channel: String) {
        if(synchronous) {
            if let entry = subscribedChannels[channel] {
                if entry {
                    if(session.unsubscribeAndWaitTopic(channel)) {
                        subscribedChannels[channel] = false
                    }
                }
            }
        }
        else {
            let messageId = Int(session.unsubscribeTopic(channel))
            unsubscribedChannelMessageIds[messageId] = channel
        }
    }
    
    /**
     Return an array of channels, it contains also the wildcards.
     
     - returns: Array of strings, every sstring is a channel subscribed.
     */
    public func getSubscribedChannels() -> [String] {
        var channels:[String] = []
        for (channel, subscribed) in subscribedChannels {
            if subscribed {
                channels.append(channel)
            }
        }
        return channels
    }
    
    /**
     Return true if is subscribeb or no to a channel, takes into account wildcards.
     
     - parameter channel: Channel name.
     - returns: true if is is subscribed to the channel.
     */
    public func isSubscribed(_ channel: String) -> Bool {
        for (c, subscribed) in subscribedChannels {
            if subscribed && c.substring(to: c.characters.index(before: c.endIndex)).isSubinitialStringOf(channel) {
                return true
            }
        }
        
        return false
    }
    
    /**
     Return the wildcard that contains the current channel if there's any
     
     - parameter channel: Channel name.
     - returns: the String of the wildcard
     */
    public func wildcardSubscribed(_ channel: String) -> String? {
        for (c, subscribed) in subscribedChannels {
            if subscribed && c.substring(to: c.characters.index(before: c.endIndex)).isSubinitialStringOf(channel) {
                return c
            }
        }
        
        return nil
    }
    
    /**
     Publish a message on the desired MQTT channel.
     
     - parameter channel: The name of the channel.
     - parameter message: The message.
     */
    public func publish(_ channel: String, message: String) {
        while !sessionConnected && !sessionError {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
        }
        
        if(synchronous) {
            session.publishAndWait(message.data(using: String.Encoding.utf8, allowLossyConversion: false),
                                   onTopic: channel,
                                   retain: false,
                                   qos: .atMostOnce)
        }
        else{
            session.publishData(message.data(using: String.Encoding.utf8, allowLossyConversion: false),
                                onTopic: channel,
                                retain: false,
                                qos: .atMostOnce)
        }
    }
    
    /**
     Disconnect the client immediately.
     */
    open func disconnect() {
        self.host = nil
        
        session.close()
        sessionConnected = false
    }
    
    /**
     Connect the client to an MQTT server.
     
     - parameter host: The hostname of the server.
     */
    @nonobjc open func connect(_ host: String) {
        self.host = host
        
        if( sessionConnected == false) {
            subscribedChannels = [:]
            if(synchronous) {
                session.connectAndWait(toHost: host,
                                       port: 1883,
                                       usingSSL: false)
            }
            else {
                session.connect(toHost: host,
                                port: 1883,
                                usingSSL: false)
            }
            
        }
        
    }
    
    var previouslySubscribedChannels: [String:Bool]?
    
    /**
     * isConnect 
     */
    public func isConnect() -> Bool {
        return sessionConnected
    }
    
    /**
     Reconnect the client to the MQTT server.
     */
    public func reconnect() {
        
        // Only if the session was previously connected
        if(sessionConnected == true) {
            
            // Save the previous subscribed channels
            if self.previouslySubscribedChannels == nil {
                self.previouslySubscribedChannels = self.subscribedChannels
            }
            
            self.subscribedChannels = [:]
            
            if(synchronous) {
                session.connectAndWait(toHost: host,
                                       port: 1883,
                                       usingSSL: false)
                
                if let psc = self.previouslySubscribedChannels {
                    for (channel, status) in psc {
                        if(status == true) {
                            self.subscribe(channel)
                        }
                    }
                }
            }
            else {
                session.connect(toHost: host,
                                port: 1883,
                                usingSSL: false)
                
                // TODO: resubmit to every channel
            }
        }
    }
    
    // Timer callback 1.0 seconds after the disconnection
    open func reconnect(_ timer: Timer) {
        self.reconnect()
    }
    
    // MARK:  MQTTSessionDelegate protocol
    
    open func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        //print("New message received \(NSString(data: data, encoding: String.Encoding.utf8.rawValue))", terminator: "")
        self.delegate?.messageReceived?(
            topic,
            message: String(data: data, encoding: String.Encoding.utf8)! as String
        )
    }
    
    public func handleEvent(_ session: MQTTSession!, event eventCode: MQTTSessionEvent, error: Error!) {
        switch eventCode {
        case .connected:
            sessionConnected = true
            self.previouslySubscribedChannels = nil     // Delete the channels in the previous session
            self.delegate?.connected?()
        case .connectionClosed:
            print("SimpleMQTTClient: Connection closed, retry to re-connect in 1 second", terminator: "")
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(SimpleMQTTClient.reconnect(_:)), userInfo: nil, repeats: false)
            //sessionConnected = false
        //self.delegate?.disconnected?()
        default:
            sessionError = true
        }
    }
    
    
    
    
    @nonobjc public func subAckReceived(_ session: MQTTSession, msgID: UInt16, grantedQoss: [Any]) {
        if let channel = subscribedChannelMessageIds[Int(msgID)] {
            subscribedChannels[channel] = true
        }
    }
    
    @nonobjc public func unsubAckReceived(_ session: MQTTSession, msgID: UInt16, grantedQoss: [Any]) {
        if let channel = unsubscribedChannelMessageIds[Int(msgID)] {
            subscribedChannels[channel] = false
        }
    }
}
