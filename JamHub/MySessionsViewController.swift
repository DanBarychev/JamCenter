//
//  MySessionsViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
// Record icon from https://icons8.com/icon/9403/Music-Record-Filled

import UIKit
import Firebase

class MySessionsViewController: UITableViewController {
    
    var sessions = [Session]()
    typealias MusicianArrayClosure = ([Musician]?) -> Void
    typealias MusicianClosure = (Musician?) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        getData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "loadMySessions"), object: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionTableViewCell", for: indexPath) as! SessionTableViewCell
        
        let session = sessions.reversed()[indexPath.row]
        
        cell.nameLabel?.text = session.name
        cell.genreLabel?.text = session.genre
        
        if !(session.isActive ?? false) {
            cell.activeLabel.isHidden = true
            cell.activeImageView.isHidden = true
        }
        if session.hostUID != Auth.auth().currentUser?.uid {
            cell.roleLabel.text = "Participant"
            cell.roleImageView.image = UIImage(named: "CircleIconBlue")
        }

        return cell
    }
    

    func getData() {
        sessions.removeAll()  //Start clean
        
        let uid = Auth.auth().currentUser?.uid
        let allSessionsRef = Database.database().reference().child("all sessions")
        
        allSessionsRef.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let newSession = Session()
                
                newSession.hostUID = dictionary["hostUID"] as? String
                
                if newSession.hostUID == uid {
                    newSession.name = dictionary["name"] as? String
                    newSession.genre = dictionary["genre"] as? String
                    newSession.location = dictionary["location"] as? String
                    newSession.host = dictionary["host"] as? String
                    newSession.hostImageURL = dictionary["hostImageURL"] as? String
                    newSession.audioRecordingURL = dictionary["audioRecordingURL"] as? String
                    newSession.code = dictionary["code"] as? String
                    newSession.ID = dictionary["ID"] as? String
                    
                    newSession.isActive = Bool((dictionary["isActive"] as? String) ?? "true")

                    self.sessions.append(newSession)
                    
                    DispatchQueue.main.async(execute: {
                        self.tableView.reloadData()
                    })
                }
            }
        }, withCancel: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCurrentJamFromMySessions" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! CurrentJamViewController
            
            if let selectedJamCell = sender as? SessionTableViewCell
            {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                let selectedJam = sessions.reversed()[indexPath.row]
                newViewController.currentSession = selectedJam
            }
        }
    }
    
    @IBAction func unwindToMySessions(sender: UIStoryboardSegue) {
        getData()
    }

}
