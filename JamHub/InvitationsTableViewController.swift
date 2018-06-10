//
//  InvitationsTableViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/29/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
//  Mail Icon from https://icons8.com/icon/2848/Message-Filled

import UIKit
import Firebase

class InvitationsTableViewController: UITableViewController {
    
    var sessions = [Session]()
    typealias SessionClosure = (Session?) -> Void
    typealias MusicianArrayClosure = ([Musician]?) -> Void
    typealias HasInvitationsClosure = (Bool?) -> Void

    override func viewDidAppear(_ animated: Bool) {
        print("Invitations View Appeared")
        
        super.viewDidLoad()

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
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        getData()
        refreshControl.endRefreshing()
    }

    // MARK: Table View Properties
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InvitationCell", for: indexPath) as! InvitationTableViewCell
        
        let session = sessions.reversed()[indexPath.row]

        cell.sessionLabel.text = session.name
        
        if let sessionHost = session.host {
            cell.messageLabel.text = "\(sessionHost) has invited you"
        }
        if let hostImageURL = session.hostImageURL {
            cell.hostImageView.loadImageUsingCacheWithURLString(urlString: hostImageURL)
        }

        cell.hostImageView.layer.cornerRadius = cell.hostImageView.frame.size.width / 2
        cell.hostImageView.clipsToBounds = true

        return cell
    }
    
    // MARK: Firebase Functions
    
    func getData() {
        sessions.removeAll()
        
        let ref = Database.database().reference()
        
        if let uid = Auth.auth().currentUser?.uid {
            let userRef = ref.child("users").child(uid)
            
            checkIfUserHasInvitations(userRef: userRef) { (hasInvitations) in
                guard let userHasInvitations = hasInvitations
                    else {
                    return
                }
                if userHasInvitations {
                    let invitationsRef = userRef.child("invitations")
                    invitationsRef.observe(.childAdded, with: { (snapshot) in
                        print("Observing....")
                        if let dictionary = snapshot.value as? [String: AnyObject] {
                            let sessionID = dictionary["sessionID"] as? String
                            
                            if let sessionID = sessionID {
                                self.getSession(sessionID: sessionID) { (session) in
                                    if let session = session {
                                        self.sessions.append(session)
                                        
                                        print("Just appended a session")
                                        
                                        DispatchQueue.main.async {
                                            self.tableView.reloadData()
                                        }
                                    } else {
                                        print("Session is nil!")
                                    }
                                }
                            }
                        }
                    })
                } else {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    func getSession(sessionID: String, completionHandler: @escaping SessionClosure) {
        print("Getting session")
        let session = Session()
        
        let ref = Database.database().reference()
        let sessionRef = ref.child("all sessions").child(sessionID)
        
        sessionRef.observe(.value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                session.name = dictionary["name"] as? String
                session.genre = dictionary["genre"] as? String
                session.location = dictionary["location"] as? String
                session.host = dictionary["host"] as? String
                session.hostImageURL = dictionary["hostImageURL"] as? String
                session.audioRecordingURL = dictionary["audioRecordingURL"] as? String
                session.code = dictionary["code"] as? String
                session.ID = sessionID
                session.hostUID = dictionary["hostUID"] as? String
                session.isActive = Bool((dictionary["isActive"] as? String) ?? "false")
                
                completionHandler(session)
            }
        })
    }
    
    //Needed if we just accepted the last one and no longer have the invitations key
    func checkIfUserHasInvitations(userRef: DatabaseReference, completionHandler: @escaping HasInvitationsClosure) {
        userRef.observe(.value, with: {(snapshot) in
            if snapshot.hasChild("invitations") {
                print("Has invitations")
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        })
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCurrentJamFromInvitation" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! CurrentJamViewController
            
            if let selectedJamCell = sender as? InvitationTableViewCell
            {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                let selectedJam = sessions.reversed()[indexPath.row]
                newViewController.currentSession = selectedJam
            }
        }
    }

}
