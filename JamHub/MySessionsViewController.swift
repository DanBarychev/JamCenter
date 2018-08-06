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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Remove observer
        Database.database().reference().removeAllObservers()
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let session = sessions.reversed()[indexPath.row]
            
            guard let sessionID = session.ID , let sessionHostUID = session.hostUID else {
                return
            }
            
            print("SessionID: \(sessionID)")
            
            // The reverse index accounts for us using a reversed sessions array
            let reverseIndex = sessions.count - indexPath.row - 1
            
            sessions.remove(at: reverseIndex)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if sessionHostUID == Auth.auth().currentUser?.uid {
                deleteSession(sessionID: sessionID)
            } else {
                // TODO: Remove user from session musicians list
            }
        }
    }
    
    // MARK: Firebase Functions

    func getData() {
        sessions.removeAll()  //Start clean
        
        let uid = Auth.auth().currentUser?.uid
        let allSessionsRef = Database.database().reference().child("all sessions")
        
        allSessionsRef.observeSingleEvent(of: .value, with: {(snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let dictionary = child.value as? [String: AnyObject] {
                    let newSession = Session()
                    
                    guard let sessionID = dictionary["ID"] as? String, let userUID = uid else {
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

                                if newSession.hostUID == uid {
                                    self.sessions.append(newSession)
                                } else {
                                    self.sessions.insert(newSession, at: 0)
                                }
                                
                                DispatchQueue.main.async(execute: {
                                    self.tableView.reloadData()
                                })
                             }
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
        
        sessionMusiciansKey.observeSingleEvent(of: .value, with: {(snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let dictionary = child.value as? [String: AnyObject] {
                    
                    let sessionMusicianID = dictionary["musicianID"] as? String
                    
                    if musicianID == sessionMusicianID {
                        completionHandler(true)
                    }
                }
            }
        })
        
        completionHandler(false)
    }
    
    func deleteSession(sessionID: String) {
        let ref = Database.database().reference()
        let sessionRef = ref.child("all sessions").child(sessionID)
        
        sessionRef.removeValue()
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
        /*if let sourceViewController = sender.source as? CurrentJamViewController,
            let currentSession = sourceViewController.currentSession {
            
            sessions.append(currentSession)
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
        }*/
    }

}
