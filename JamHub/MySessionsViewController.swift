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
    
    // MARK: Properties
    
    var hostSessions = [Session]()
    var participantSessions = [Session]()
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    typealias isParticipantClosure = (Bool?) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.segmentedControl.layer.cornerRadius = 0
        self.segmentedControl.layer.borderColor = UIColor.black.cgColor
        self.segmentedControl.layer.borderWidth = 1.5
        
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
        if segmentedControl.selectedSegmentIndex == 0 {
            return hostSessions.count
        } else {
            return participantSessions.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionTableViewCell", for: indexPath) as! SessionTableViewCell
        
        var session = Session()
        
        if segmentedControl.selectedSegmentIndex == 0 {
            session = hostSessions.reversed()[indexPath.row]
        } else {
            session = participantSessions.reversed()[indexPath.row]
        }
        
        cell.nameLabel?.text = session.name
        cell.genreLabel?.text = session.genre
        
        guard let sessionIsActive = session.isActive else {
            return cell
        }
        
        if sessionIsActive {
            cell.activeLabel.text = "Active"
            cell.activeImageView.image = UIImage(named: "CircleIconGreen")
        } else {
            cell.activeLabel.text = "Inactive"
            cell.activeImageView.image = UIImage(named: "CircleIconGrey")
        }
        
        if session.hostUID == Auth.auth().currentUser?.uid {
            cell.roleLabel.text = "Host"
            cell.roleImageView.image = UIImage(named: "CircleIconRed")
        } else {
            cell.roleLabel.text = "Participant"
            cell.roleImageView.image = UIImage(named: "CircleIconBlue")
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var session = Session()
            
            if segmentedControl.selectedSegmentIndex == 0 {
                session = hostSessions.reversed()[indexPath.row]
            } else {
                session = participantSessions.reversed()[indexPath.row]
            }
            
            guard let sessionID = session.ID , let sessionHostUID = session.hostUID,
                let uid = Auth.auth().currentUser?.uid else {
                return
            }
            
            // The reverse index accounts for us using a reversed sessions array
            if segmentedControl.selectedSegmentIndex == 0 {
                let reverseIndex = hostSessions.count - indexPath.row - 1
                
                hostSessions.remove(at: reverseIndex)
            } else {
                let reverseIndex = participantSessions.count - indexPath.row - 1
                
                participantSessions.remove(at: reverseIndex)
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if sessionHostUID == uid {
                deleteSession(sessionID: sessionID)
            } else {
                deleteUserFromSession(uid: uid, sessionID: sessionID)
            }
        }
    }
    
    // MARK: Firebase Functions

    func getData() {
        hostSessions.removeAll()
        participantSessions.removeAll()
        
        let uid = Auth.auth().currentUser?.uid
        let allSessionsRef = Database.database().reference().child("all sessions")
        
        allSessionsRef.observeSingleEvent(of: .value, with: {(snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let dictionary = child.value as? [String: AnyObject] {
                    let newSession = Session()
                    
                    guard let sessionID = dictionary["ID"] as? String, let hostUID = dictionary["hostUID"] as? String,
                        let uid = uid else {
                        return
                    }
                    
                    let isHost = (hostUID == uid)
                    let isParticipant = self.musicianIsParticipant(uid: uid, dictionary: dictionary)
                    
                    if isHost || isParticipant {
                        newSession.name = dictionary["name"] as? String
                        newSession.genre = dictionary["genre"] as? String
                        newSession.location = dictionary["location"] as? String
                        newSession.host = dictionary["host"] as? String
                        newSession.audioRecordingURL = dictionary["audioRecordingURL"] as? String
                        newSession.code = dictionary["code"] as? String
                        newSession.hostLocation = dictionary["hostLocation"] as? String
                        newSession.hostUID = hostUID
                        newSession.startTime = dictionary["startTime"] as? String
                        newSession.startDate = dictionary["startDate"] as? String
                        newSession.ID = sessionID
                        
                        newSession.isActive = Bool((dictionary["isActive"] as? String) ?? "true")
                        
                        if isHost {
                            self.hostSessions.append(newSession)
                        } else {
                            self.participantSessions.append(newSession)
                        }
                        
                        DispatchQueue.main.async(execute: {
                            self.tableView.reloadData()
                        })
                    }
                }
            }
        }, withCancel: nil)
    }
    
    func musicianIsParticipant(uid: String, dictionary: [String: AnyObject]) -> Bool {
        if let musicianSnapshot = dictionary["musicians"] as? [String: AnyObject] {
            for (_, value) in musicianSnapshot {
                if let valueDict = value as? [String: AnyObject], let musicianID = valueDict["musicianID"] as? String {
                    if musicianID == uid {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func deleteSession(sessionID: String) {
        let ref = Database.database().reference()
        let sessionRef = ref.child("all sessions").child(sessionID)
        
        sessionRef.removeValue()
    }
    
    func deleteUserFromSession(uid: String, sessionID: String) {
        let ref = Database.database().reference()
        let sessionRef = ref.child("all sessions").child(sessionID).child("musicians")
        
        sessionRef.observeSingleEvent(of: .value, with: {(snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let dictionary = child.value as? [String: AnyObject] {
                    let musicianID = dictionary["musicianID"] as? String
                    
                    if uid == musicianID {
                        sessionRef.child(child.key).removeValue()
                    }
                }
            }
        }, withCancel: nil)
    }
    
    // MARK: Actions
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        self.tableView.reloadData()
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCurrentJamFromMySessions" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! CurrentJamViewController
            
            if let selectedJamCell = sender as? SessionTableViewCell
            {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                
                if segmentedControl.selectedSegmentIndex == 0 {
                    newViewController.currentSession = hostSessions.reversed()[indexPath.row]
                } else {
                    newViewController.currentSession = participantSessions.reversed()[indexPath.row]
                }
                
                newViewController.origin = "MySessions"
            }
        }
    }
    
    @IBAction func unwindToMySessions(sender: UIStoryboardSegue) {
        getData()
    }

}
