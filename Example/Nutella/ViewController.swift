//
//  ViewController.swift
//  Nutella
//
//  Created by Anthony on 10/01/2016.
//  Copyright (c) 2016 Anthony. All rights reserved.
//

import UIKit
import Nutella

class ViewController: UIViewController {
    
    var nutella: Nutella?
    
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var reloadButton: UIButton!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nutellaSetup()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func nutellaSetup() {
        
        
        
        
        let block = DispatchWorkItem {
            
            
            
            
            
            // ... do any setup ...
            
            self.nutella = Nutella(brokerHostname: "localhost",
                                   appId: "wallcology",
                                   runId: "default",
                                   componentId: "test_component", netDelegate: self)
            self.nutella?.net.subscribe("echo_out")
        }
        DispatchQueue.main.async(execute: block)
        
        //
        
        
    }
    
    /**
     @IBAction func uploadFile(_ sender: UIButton){
     let fileURL = Bundle.main.url(forResource: "test", withExtension: "jpg")
     let data: Data? = Data(contentsOf: fileURL)
     nutella.net.upload(withFile: data, andFilename: "test.jpg")
     }
     **/
    
    @IBAction func publishMessageToNutella(_ sender: UIButton){
        
            
            if let nutella = self.nutella {
                
                let block = DispatchWorkItem {
                    _ = "Hello Major Tom, are you receiving this? Turn the thrusters on, we're standing by"
                    var dict = [String:String]()
                    dict["speciesIndex"] = "1"
                    
                    nutella.net.asyncRequest("all_notes_with_species", message: dict as AnyObject, requestName: "all_notes_with_species")
                    nutella.net.publish("echo_in", message: dict as AnyObject)
                }
                
                DispatchQueue.main.async(execute: block)
                
            }
            
        
    }
    
    @IBAction func reloadAction(_ sender: UIButton) {
        nutellaSetup()
    }
    
}

extension ViewController: NutellaNetDelegate {
    /**
     A response to a previos request is received.
     
     - parameter channelName: The Nutella channel on which the message is received.
     - parameter requestName: The optional name of request.
     - parameter response: The dictionary/array/string containing the JSON representation.
     */
    public func responseReceived(_ channel: String, requestName: String?, response: Any, from: [String : String]) {
        print("HEY \(response) from \(from)")
    }
    
    
    /**
     Called when a message is received from a publish.
     
     - parameter channel: The name of the Nutella chennal on which the message is received.
     - parameter message: The message.
     - parameter from: The actor name of the client that sent the message.
     */
    func messageReceived(_ channel: String, message: Any, from: [String : String]) {
        print("GOT IT \(message) \(from)")
    }
    
    /**
     A response to a previos request is received.
     
     - parameter channelName: The Nutella channel on which the message is received.
     - parameter requestName: The optional name of request.
     - parameter response: The dictionary/array/string containing the JSON representation.
     */
    
    /**
     A request is received on a Nutella channel that was previously handled (with the handleRequest).
     
     - parameter channelName: The name of the Nutella chennal on which the request is received.
     - parameter request: The dictionary/array/string containing the JSON representation of the request.
     */
    
    func requestReceived(_ channel: String, request: Any?, from: [String : String]) -> AnyObject? {
        print("responseReceived \(channel) request: \(request) from: \(from)")
        return nil
    }
    //    func requestReceived(_ channelName: String, request: Any?, from: [String : String]) -> AnyObject? {
    //        print("responseReceived \(channelName) request: \(request) from: \(from)")
    //        return nil
    //    }
}


