//
//  MyActiveSessionViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/11/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
//  Key Icon from https://icons8.com/icon/555/Key
//  Circle Icon from https://icons8.com/icon/24608/Unchecked-Circle
//  Settings Icon from https://icons8.com/icon/364/Settings

import UIKit
import Firebase
import FacebookShare

class MyActiveSessionViewController: UIViewController {
    
    // MARK: Properties
    
    var mySession: Session?
    var sessionID = String()
    var sessionHostUID = String()
    var sessionCode = String()
    var sessionLocation = String()
    var sessionMusicians = [Musician]()
    
    @IBOutlet weak var endSessionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let session = mySession {
            navigationItem.title = session.name
            sessionID = session.ID ?? ""
            sessionHostUID = session.hostUID ?? ""
            sessionCode = session.code ?? "Code Unavailable"
            sessionLocation = session.location ?? "Unknown"
            sessionMusicians = session.musicians ?? []
            if !(session.isActive ?? false) {
                endSessionButton.isHidden = true
            }
            
            endSessionButton.layer.cornerRadius = 25
            endSessionButton.layer.borderWidth = 2
            endSessionButton.layer.borderColor = UIColor.white.cgColor
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func endSession() {
        let values = ["isActive": "false"]
        
        print("ending session")
        
        let ref = Database.database().reference()
        let allSessionsKey = ref.child("all sessions").child(sessionID)
        
        allSessionsKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print (error!)
                return
            }
            else {
                print("Session ended on public side")
            }
        })
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToMyAudio" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! MyAudioViewController
            
            newViewController.mySession = mySession
        } else if segue.identifier == "GoToMySongs" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! MySongsTableViewController
            
            newViewController.mySession = mySession
        }
    }
    
    @IBAction func unwindToMyActiveSession(sender: UIStoryboardSegue) {
    }
    
    // MARK: Actions
    
    @IBAction func shareTapped(_ sender: UIButton) {
        let content = LinkShareContent(url: URL(string: "https://developers.facebook.com")!)
        do {
            try ShareDialog.show(from: self, content: content)
        } catch {
        }
    }
    
    @IBAction func getCodeTapped(_ sender: UIButton) {
        let codeAlert = UIAlertController(title: sessionCode, message: "", preferredStyle: UIAlertControllerStyle.alert)
        codeAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(codeAlert, animated: true, completion: nil)
    }
    
    @IBAction func endSessionTapped(_ sender: UIButton) {
        endSession()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "loadMySessions"), object: nil)
    }
    
    
}
