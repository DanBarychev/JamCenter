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
    var selectedMusicianNames = [String]()
    var alreadySelectedMusicianNames: [String]?
    var alreadySelectedMusicians: [Musician]?
    var origin: String?
    
    @IBOutlet weak var topRightReturnButton: UIBarButtonItem!
    
    typealias CurrentSessionClosure = (Session?) -> Void
    typealias MusicianClosure = (Musician?) -> Void
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if origin == "NewSession" {
            topRightReturnButton.title = "Done"
        } else if origin == "CurrentJam" {
            topRightReturnButton.title = "Invite"
        }
        
        getData()
        
        if let alreadySelectedMusicians = alreadySelectedMusicians,
            let alreadySelectedMusicianNames = alreadySelectedMusicianNames {
            for musician in alreadySelectedMusicians {
                selectedMusicians.append(musician)
            }
            
            for musicianName in alreadySelectedMusicianNames {
                selectedMusicianNames.append(musicianName)
            }
        }
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
        
        cell.nameLabel.text = musician.name
        cell.instrumentsLabel.text = musician.instruments
        if let profileImageURL = musician.profileImageURL {
            cell.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
        }
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2
        cell.profileImageView.clipsToBounds = true
        
        if let musicianName = musician.name {
            if selectedMusicianNames.contains(musicianName) {
                cell.okIcon.isHidden = false
            }
        }
        
        return cell
    }
    
    // When we select a musician
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! InviteMusiciansTableViewCell
        
        let musician = musicians[indexPath.row]
        
        if let musicianName = musician.name {
            if cell.okIcon.isHidden {
                cell.okIcon.isHidden = false
                
                selectedMusicianNames.append(musicianName)
                selectedMusicians.append(musician)
            } else {
                cell.okIcon.isHidden = true
                
                if let index = selectedMusicianNames.index(of: musicianName) {
                    selectedMusicianNames.remove(at: index)
                    selectedMusicians.remove(at: index)
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
    
    // MARK: Invite Sending
    
    func sendInvites(musicians: [Musician], sessionID: String) {
        let ref = Database.database().reference()
        for musician in musicians {
            let uid = musician.uid
            let musicianInvitationsRef = ref.child("users").child(uid!).child("invitations")
            let musicianInvitationsKey = musicianInvitationsRef.childByAutoId()
            
            let values = ["sessionID": sessionID]
            
            musicianInvitationsKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    if let musicianName = musician.name {
                        print("Invitation sent to \(musicianName)")
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
            self.performSegue(withIdentifier: "UnwindToCurrentJamFromInviteMusicians", sender: nil)
        }
    }
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UnwindToNewSessionFromInviteMusicians" {
            let newViewController = segue.destination as! NewSessionViewController
            
            newViewController.invitedMusicians = selectedMusicians
            newViewController.invitedMusicianNames = selectedMusicianNames
        }
    }
    
}
