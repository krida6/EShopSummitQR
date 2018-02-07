//
//  ViewController2.swift
//  EShopSummitQR
//
//  Created by Petr Křišťan on 28.01.18.
//  Copyright © 2018 Petr Křišťan. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import RealmSwift

let loginID = UserDefaults.standard.string(forKey: "myID")!
let webUrl:String = "https://app.eshopsummit.cz";

class Contact: Object {
    @objc dynamic var myID = loginID
    @objc dynamic var pairID = "0"
    @objc dynamic var toSync = 1
}

class ViewController2: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var loadStatus: Bool = false
    var timer = Timer()
    
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var switchBtn: UIButton!
    
    
    @IBAction func switchBtnClick(_ sender: Any) {
        loadStatus = !loadStatus
        
        print(loadStatus)
        
        if (loadStatus) {
            switchBtn.setImage(UIImage(named: "Switch1.png"), for: .normal)
        } else {
            switchBtn.setImage(UIImage(named: "Switch2.png"), for: .normal)
        }
        
    }
    
    
    override func viewDidLoad() {
        print("startujem")
        super.viewDidLoad()
        
        print(loginID)
        
        if (loadStatus) {
            switchBtn.setImage(UIImage(named: "Switch1.png"), for: .normal)
        } else {
            switchBtn.setImage(UIImage(named: "Switch2.png"), for: .normal)
        }
        
        // Do any additional setup after loading the view.
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraView.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
        
        self.timer = Timer.scheduledTimer(
            timeInterval: 5.0, //in seconds
            target: self, //where you'll find the selector (next argument)
            selector: #selector(ViewController2.syncContacts), //MyClass is the current class
            userInfo: nil, //no idea what this is, Apple, help?
            repeats: true) //keep going!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutBtn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func syncContacts() {
        print("Syncing contacts...")
        do {
            let realm = try Realm()
            let contacts = realm.objects(Contact.self).filter("toSync == 1")
            
            for contact in contacts {
                print(contact.pairID)
                print(contact.myID)
                
                makePairRequest(myID: contact.myID, pairID: contact.pairID)
            }
            
        } catch let error as NSError {
            print(error)
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Message", message: "Komunikace s databázi se nezdařila. Odhlašte se a opakujte akci později.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func makePairRequest(myID:String, pairID:String) {
        //create the url with NSURL
        let url = URL(string: webUrl+"/eshop/index.php?myID="+myID+"&newID="+pairID)!
        
        print(myID)
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        let request = URLRequest(url: url)
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            print("tvorim request")
            
            //TODO: change status of pairID in Realm manager
            var dataString = String(data: data, encoding: String.Encoding.utf8) as String!
            dataString = dataString?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print(dataString ?? "")
            
            if  dataString == "1" {
                print("podarilo se synchronizovat " + myID + " a " + pairID)
                DispatchQueue(label: "background").async {
                    autoreleasepool {
                        do {
                            let realm = try Realm()
                            let contacts = realm.objects(Contact.self).filter("pairID == '" + pairID + "' AND myID == '" + myID + "'")
                            
                            for contact in contacts {
                                try realm.write {
                                    contact.toSync = 0;
                                }
                            }
                            
                            print("zmeneno i v DB")
                        } catch let error as NSError {
                            print(error)
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Message", message: "Komunikace s databázi se nezdařila. Odhlašte se a opakujte akci později.", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            
        })
        
        task.resume()
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }        
    }
    
    func found(code: String) {
        print(code)
        let result:[String] = code.components(separatedBy: "|")
        
        if (result.count == 3) {
            
            do {
                let realm = try Realm()
                let contact = Contact()
                contact.pairID = result[0]
                
                try realm.write {
                    realm.add(contact)
                }
                
            } catch let error as NSError {
                print(error)
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Message", message: "Komunikace s databázi se nezdařila. Odhlašte se a opakujte akci později.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
            nameLabel.text = result[1]
            companyLabel.text = result[2]
            
            print(result)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}
