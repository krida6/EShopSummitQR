//
//  ViewController.swift
//  EShopSummitQR
//
//  Created by Petr Křišťan on 26.01.18.
//  Copyright © 2018 Petr Křišťan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var loginName: UITextField!
    @IBOutlet weak var loginPass: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    
    let webUrl:String = "https://app.eshopsummit.cz";
    
    func showMSG( text:String){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Message", message: text, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func confirmBtn(_ sender: UITextField) {
        self.sendBtn(loginBtn)
    }
    
    @IBAction func nextBtn(_ sender: UITextField) {
        loginPass.becomeFirstResponder()
    }
    
    
    @IBAction func sendBtn(_ sender: Any) {
        //create the url with NSURL
        let url = URL(string: self.webUrl+"/eshop/login.php?login="+loginName.text!+"&pass="+loginPass.text!)!
        
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
            
            var prejdi:Int=0;
            var myID:String="0";
            
            
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                    
                    if let uspech = json["success"] as? String {
                        if (uspech == "1") {
                            if let ID:String = json["myID"] as? String {
                                prejdi = 1;
                                myID = ID;
                            }
                        }
                    }
                }
            } catch let error {
                print(error.localizedDescription)
            }
            
            if (prejdi==1) {
                //self.showMSG(text: "Ok.")
                
                UserDefaults.standard.set(myID, forKey: "myID")
                
                DispatchQueue.main.async {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "scanQR") as! ViewController2
                    self.present(vc, animated: true, completion: nil)
                }
                
            } else {
                self.showMSG(text: "Nepodařilo se přihlásit.")
            }
            
        })
        
        task.resume()
        
    }
    
}

