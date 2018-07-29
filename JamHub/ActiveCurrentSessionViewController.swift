//
//  ActiveCurrentSessionViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/8/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
// Video icon from https://icons8.com/icon/11402/Video-Call-Filled
// Audio icon from https://icons8.com/icon/9403/Music-Record-Filled
// Songs icon from https://icons8.com/icon/41815/Sheet-Music-Filled

import UIKit

class ActiveCurrentSessionViewController: UIViewController {
    
    var currentSession: Session?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentJamSession = currentSession {
            navigationItem.title = currentJamSession.name
        }
    }
    
    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToAudio" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! AudioViewController
            
            newViewController.currentSession = currentSession
        } else if segue.identifier == "GoToSongs" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! SongsTableViewController
            
            newViewController.mySession = currentSession
        }
    }
    
    @IBAction func unwindToActiveSession(sender: UIStoryboardSegue) {
    }
    
}
