//
//  SetTimeViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 8/12/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class SetTimeViewController: UIViewController {
    
    // MARK: Properties
    var newSession: Session?
    var invitedMusicians: [Musician]?
    var currentUserMusician: Musician?
    
    typealias MusicianClosure = (Musician?) -> Void
    typealias SessionCreatedClosure = (Bool?) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Session Code
    
    func createSessionCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" as NSString
        var sessionCode = ""
        
        //Session code is 6 characters long
        for _ in 0 ..< 6 {
            let rand = arc4random_uniform(UInt32(characters.length))
            var nextChar = characters.character(at: Int(rand))
            sessionCode += NSString(characters: &nextChar, length: 1) as String
        }
        
        return sessionCode
    }
    
    // MARK: Session Creation Functions
    
    private func createSession(completionHandler: @escaping SessionCreatedClosure) {
        let sessionCode = createSessionCode()
        
        guard let newSessionUnwrapped = newSession, let name = newSessionUnwrapped.name, let genre = newSessionUnwrapped.genre,
            let currentUserMusicianUnwrapped = currentUserMusician, let userName = Auth.auth().currentUser?.displayName,
            let location = newSessionUnwrapped.location, let userCity = currentUserMusicianUnwrapped.city,
            let userCountry = currentUserMusicianUnwrapped.country, let uid = Auth.auth().currentUser?.uid
            else {
                return
        }
        
        let userLocation = "\(userCity), \(userCountry)"
        
        let ref = Database.database().reference()
        let allSessionsRef = ref.child("all sessions")
        let sessionKey = allSessionsRef.childByAutoId()
        let values = ["name": name, "genre": genre, "location": location, "host": userName,
                      "code": sessionCode, "ID": sessionKey.key, "hostUID": uid,
                      "hostLocation": userLocation, "isActive": "true"]
        
        newSession?.host = userName
        newSession?.code = sessionCode
        newSession?.ID = sessionKey.key
        newSession?.hostUID = uid
        newSession?.hostLocation = userLocation
        newSession?.isActive = true
        
        sessionKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if let error = error {
                print (error)
                return
            }
            else {
                print("Session made public")
            }
        })
        
        //Add the current user to Firebase musicians list
        addCurrentUserToSession(sessionKey: sessionKey)
        
        //Send invites and add invitees to the invitees list
        if let invitedMusicians = invitedMusicians {
            sendInvites(musicians: invitedMusicians, sessionID: sessionKey.key)
            
            for musician in invitedMusicians {
                let sessionInviteesKey = sessionKey.child("invitees").childByAutoId()
                
                guard let musicianID = musician.uid
                    else {
                        return
                }
                
                let musicianValues = ["musicianID": musicianID]
                
                sessionInviteesKey.updateChildValues(musicianValues, withCompletionBlock: { (error, ref) in
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
        
        completionHandler(true)
    }
    
    func addCurrentUserToSession(sessionKey: DatabaseReference) {
        let allSessionsMusiciansKey = sessionKey.child("musicians").childByAutoId()
        
        guard let currentUserMusician = currentUserMusician, let musicianID = currentUserMusician.uid
            else {
                return
        }
        
        let musicianValues = ["musicianID": musicianID]
        
        allSessionsMusiciansKey.updateChildValues(musicianValues, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                return
            } else {
                self.updateCurrentUserSessionInformation()
            }
        })
    }
    
    func updateCurrentUserSessionInformation() {
        let ref = Database.database().reference()
        
        guard let uid = Auth.auth().currentUser?.uid, let currentUserMusician = currentUserMusician else {
            return
        }
        let userKey = ref.child("users").child(uid)
        
        let values = ["numSessions": String(currentUserMusician.numSessions! + 1)]
        
        userKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                return
            } else {
                print("User session info updated")
            }
        })
    }
    
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
    
    @IBAction func beginSession(_ sender: UIBarButtonItem) {
        print("Beginning Session !!!!!")
        createSession { (sessionCreated) in
            self.performSegue(withIdentifier: "GoToCurrentJamFromSetTime", sender: nil)
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCurrentJamFromSetTime" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! CurrentJamViewController
            
            newViewController.currentSession = newSession
            newViewController.origin = "SetTime"
        }
    }
}
