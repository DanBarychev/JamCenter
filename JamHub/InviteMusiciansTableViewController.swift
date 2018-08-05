//
//  InviteMusiciansTableViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 8/4/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class InviteMusiciansTableViewController: UITableViewController {

    // MARK: Properties
    
    var musicians = [Musician]()
    var selectedMusicians = [Musician]()
    var selectedMusicianUIDs = [String]()
    var alreadySelectedMusicianUIDs: [String]?
    var alreadySelectedMusicians: [Musician]?
    var currentSession: Session?
    var origin: String?
    
    @IBOutlet weak var topRightReturnButton: UIBarButtonItem!
    
    typealias CurrentSessionClosure = (Session?) -> Void
    typealias MusicianClosure = (Musician?) -> Void
    typealias IsInvitedClosure = (Bool?) -> Void
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if origin == "NewSession" {
            topRightReturnButton.title = "Done"
        } else if origin == "CurrentJam" {
            topRightReturnButton.title = "Invite"
        }
        
        if let alreadySelectedMusicians = alreadySelectedMusicians,
            let alreadySelectedMusicianUIDs = alreadySelectedMusicianUIDs {
            for musician in alreadySelectedMusicians {
                selectedMusicians.append(musician)
            }
            
            for musicianUID in alreadySelectedMusicianUIDs {
                selectedMusicianUIDs.append(musicianUID)
            }
        }
        
        getData()
    }

    // MARK: - Table view data source

    // number of rows in table view
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicians.count
    }
    
    // create a cell for each table view row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InviteMusiciansCell", for: indexPath) as! InviteMusiciansTableViewCell
        
        // set the text from the data model
        let musician = musicians[indexPath.row]
        
        guard let musicianUID = musician.uid else {
            return cell
        }
        
        self.checkIfAlreadyInvited(musicianUID: musicianUID) { (isAlreadyInvited) in
            if let isAlreadyInvited = isAlreadyInvited {
                if isAlreadyInvited {
                    cell.invitationSentCover.isHidden = false
                    cell.isUserInteractionEnabled = false
                }
                
                cell.nameLabel.text = musician.name
                cell.instrumentsLabel.text = musician.instruments
                if let profileImageURL = musician.profileImageURL {
                    cell.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
                }
                cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2
                cell.profileImageView.clipsToBounds = true
                
                if self.selectedMusicianUIDs.contains(musicianUID) {
                    cell.okIcon.isHidden = false
                }
            }
        }
        
        return cell
    }
    
    // When we select a musician
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! InviteMusiciansTableViewCell
        
        let musician = musicians[indexPath.row]
        
        if let musicianUID = musician.uid {
            if cell.invitationSentCover.isHidden {
                if cell.okIcon.isHidden {
                    cell.okIcon.isHidden = false
                    
                    selectedMusicianUIDs.append(musicianUID)
                    selectedMusicians.append(musician)
                } else {
                    cell.okIcon.isHidden = true
                    
                    if let index = selectedMusicianUIDs.index(of: musicianUID) {
                        selectedMusicianUIDs.remove(at: index)
                        selectedMusicians.remove(at: index)
                    }
                }
            }
        }
    }
    
    // MARK: Firebase Download
    
    func getData() {
        let usersRef = Database.database().reference().child("users")
        
        usersRef.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let sessionMusician = Musician()
                
                sessionMusician.uid = snapshot.key
                sessionMusician.name = dictionary["name"] as? String
                sessionMusician.genres = dictionary["genres"] as? String
                sessionMusician.instruments = dictionary["instruments"] as? String
                sessionMusician.profileImageURL = dictionary["profileImageURL"] as? String
                sessionMusician.city = dictionary["city"] as? String
                sessionMusician.country = dictionary["country"] as? String
                sessionMusician.numSessions = Int((dictionary["numSessions"] as? String) ?? "0")
                
                //We don't want to add the current user
                if sessionMusician.uid != Auth.auth().currentUser?.uid {
                    self.musicians.append(sessionMusician)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    
    func checkIfAlreadyInvited(musicianUID: String, completionHandler: @escaping IsInvitedClosure) {
        guard let currentSession = currentSession, let sessionID = currentSession.ID else {
            completionHandler(false)
            return
        }
        
        let sessionsRef = Database.database().reference().child("all sessions")
        let inviteesRef = sessionsRef.child(sessionID).child("invitees")
        
        inviteesRef.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                if let inviteeMusicianID = dictionary["musicianID"] as? String {
                    if musicianUID == inviteeMusicianID {
                        completionHandler(true)
                    }
                }
            }
        })
        
        completionHandler(false)
    }
    // MARK: Invite Sending
    
    func sendInvites(musicians: [Musician]) {
        guard let sessionID = currentSession?.ID else {
            return
        }
        
        let ref = Database.database().reference()
        for musician in musicians {
            guard let uid = musician.uid else {
                return
            }
            let musicianInvitationsRef = ref.child("users").child(uid).child("invitations")
            let musicianInvitationsKey = musicianInvitationsRef.childByAutoId()
            
            let values = ["sessionID": sessionID]
            
            musicianInvitationsKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
                if let error = error {
                    print(error)
                    return
                }
            })
        }
    }
    
    func addToSessionInvitees(musicians: [Musician]) {
        guard let sessionID = currentSession?.ID else {
            return
        }
        
        let allSessionsRef = Database.database().reference().child("all sessions")
        let inviteesRef = allSessionsRef.child(sessionID).child("invitees")
        
        for musician in musicians {
            let inviteeKey = inviteesRef.childByAutoId()
            
            guard let musicianID = musician.uid
                else {
                    return
            }
            
            let musicianValues = ["musicianID": musicianID]
            
            inviteeKey.updateChildValues(musicianValues, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    if let musicianName = musician.name {
                        print("\(musicianName) added to invitees list")
                    }
                }
            })
        }
    }
    
    // MARK: Actions
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func topRightReturnTapped(_ sender: UIBarButtonItem) {
        if origin == "NewSession" {
            self.performSegue(withIdentifier: "UnwindToNewSessionFromInviteMusicians", sender: nil)
        } else if origin == "CurrentJam" {
            sendInvites(musicians: selectedMusicians)
            addToSessionInvitees(musicians: selectedMusicians)
            self.performSegue(withIdentifier: "UnwindToCurrentJamFromInviteMusicians", sender: nil)
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UnwindToNewSessionFromInviteMusicians" {
            let newViewController = segue.destination as! NewSessionViewController
            
            newViewController.invitedMusicians = selectedMusicians
            newViewController.invitedMusicianUIDs = selectedMusicianUIDs
        }
    }
    
}
