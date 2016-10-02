//
//  SimpleMQTTClientDelegate.swift
//  Test
//
//  Created by Gianluca Venturini & Anthony Perritano

import Foundation

/**
    This delegate protocol allows to control the status change of the MQTT client.
*/
@objc public protocol SimpleMQTTClientDelegate {
    
    /**
        Called when a new message is received
    
        - parameter channel: The name of the channel
        - parameter message: The message
    */
    @objc optional func messageReceived(_ channel: String, message: String)
    
    /**
        Called when the client will be disconnected.
    */
    @objc optional func disconnected()
    
    /**
        Called when the client will be connected.
    */
    @objc optional func connected()
}
