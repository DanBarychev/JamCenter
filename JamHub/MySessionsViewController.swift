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
    typealias isParticipantClosure = (Bool?) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        getData()
        
        self.tableView.addSubview(self.myRefreshControl)
    }
    
    // MARK: Refresh Control
    
    lazy var myRefreshControl: UIRefreshControl = {
        let myRefreshControl = UIRefreshControl()
        myRefreshControl.addTarget(self, action:
            #selector(MySessionsViewController.handleRefresh(_:)),
                                   for: UIControlEvents.valueChanged)
        
        return myRefreshControl
    }()
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        getData()
        refreshControl.endRefreshing()
    }
    
    // MARK: Table View Properites

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionTableViewCell", for: indexPath) as! SessionTableViewCell
        
        let session = sessions.reversed()[indexPath.row]
        
        cell.nameLabel?.text = session.name
        cell.genreLabel?.text = session.genre
        
        if !(session.isActive ?? false) {
            cell.activeLabel.text = "Inactive"
            cell.activeImageView.image = UIImage(named: "CircleIconGrey")
        }
        
        if session.hostUID != Auth.auth().currentUser?.uid {
            cell.roleLabel.text = "Participant"
            cell.roleImageView.image = UIImage(named: "CircleIconBlue")
        }

        return cell
    }
    
    // MARK: Firebase Functions

    @objc func getData() {
        print("GET DATA")
        sessions.removeAll()  //Start clean
        
        let uid = Auth.auth().currentUser?.uid
        let allSessionsRef = Database.database().reference().child("all sessions")
        
        allSessionsRef.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let newSession = Session()
                
                guard let userUID = uid, let sessionID = dictionary["ID"] as? String else {
                    return
                }
                
                newSession.hostUID = dictionary["hostUID"] as? String
                
                self.musicianIsParticipant(sessionID: sessionID, musicianID: userUID) { (isParticipant) in
                    if let isParticipant = isParticipant {
                        if newSession.hostUID == uid || isParticipant {
                            newSession.name = dictionary["name"] as? String
                            newSession.genre = dictionary["genre"] as? String
                            newSession.location = dictionary["location"] as? String
                            newSession.host = dictionary["host"] as? String
                            newSession.audioRecordingURL = dictionary["audioRecordingURL"] as? String
                            newSession.code = dictionary["code"] as? String
                            newSession.ID = sessionID
                            
                            newSession.isActive = Bool((dictionary["isActive"] as? String) ?? "true")
                            
                            self.sessions.append(newSession)
                            
                            DispatchQueue.main.async(execute: {
                                self.tableView.reloadData()
                            })
                        }
                    }
                }
            }
        }, withCancel: nil)
    }
    
    func musicianIsParticipant(sessionID: String, musicianID: String, completionHandler: @escaping isParticipantClosure) {
        let ref = Database.database().reference()
        let sessionKey = ref.child("all sessions").child(sessionID)
        let sessionMusiciansKey = sessionKey.child("musicians")
        
        sessionMusiciansKey.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let sessionMusicianID = dictionary["musicianID"] as? String
                
                if musicianID == sessionMusicianID {
                    completionHandler(true)
                }
            }
        })
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCurrentJamFromMySessions" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! CurrentJamViewController
            
            if let selectedJamCell = sender as? SessionTableViewCell
            {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                let selectedJam = sessions.reversed()[indexPath.row]
                newViewController.currentSession = selectedJam
                newViewController.origin = "MySessions"
            }
        }
    }
    
    @IBAction func unwindToMySessions(sender: UIStoryboardSegue) {
    }

}
