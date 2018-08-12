//
//  NewSessionViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/21/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class NewSessionViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    
    @IBOutlet weak var beginSessionButton: UIBarButtonItem!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var genreTextField: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var musicianTableView: UITableView!
    
    var overallSession = Session()
    var invitedMusicians: [Musician]?
    var invitedMusicianUIDs: [String]?
    var currentUserMusician = Musician()
    
    var genreOptions = ["Rock", "Rap/Hip-Hop", "Jazz/Blues", "Pop", "Country", "Classical"]
    
    typealias MusicianClosure = (Musician?) -> Void
    typealias CreateSessionClosure = (Session?) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()
        
        beginSessionButton.isEnabled = false
        
        musicianTableView.delegate = self
        musicianTableView.dataSource = self

        titleTextField.delegate = self
        locationTextField.delegate = self
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        genreTextField.inputView = pickerView
        
        getUser { (musician) in
            self.currentUserMusician = musician ?? Musician()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Remove observer
        Database.database().reference().removeAllObservers()
    }
    
    // MARK: Table View
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let invitedMusicians = invitedMusicians {
            return invitedMusicians.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewSessionMusicianCell", for: indexPath) as! NewSessionMusicianTableViewCell
        
        var musician = Musician()
        if let invitedMusicians = invitedMusicians {
            musician = invitedMusicians[indexPath.row]
        }
        
        cell.nameLabel.text = musician.name
        cell.instrumentsLabel.text = musician.instruments
        if let profileImageURL = musician.profileImageURL {
            cell.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
        }
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2
        cell.profileImageView.clipsToBounds = true
        
        return cell
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == titleTextField {
          titleLabel.text = "Title: " + (titleTextField.text ?? "")
        }
        else if textField == locationTextField {
            locationLabel.text = "Location: " + (locationTextField.text ?? "")
        }
        
        checkFieldCompletion()
    }
    
    // MARK: PickerView
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent compenent: Int) -> Int {
        return genreOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genreOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        genreTextField.text = genreOptions[row]
        genreLabel.text = "Genre: " + genreOptions[row]
        
        checkFieldCompletion()
    }
    
    func checkFieldCompletion() -> Void {
        if titleTextField.text != "" && locationTextField.text != ""
                                        && genreTextField.text != "" {
            beginSessionButton.isEnabled = true
        }
    }
    
    // MARK: Firebase User Download
    
    func getUser(completionHandler: @escaping MusicianClosure) {
        let uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: {
            (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let userMusician = Musician()
                
                userMusician.uid = uid
                userMusician.name = dictionary["name"] as? String
                userMusician.city = dictionary["city"] as? String
                userMusician.country = dictionary["country"] as? String
                userMusician.genres = dictionary["genres"] as? String
                userMusician.instruments = dictionary["instruments"] as? String
                userMusician.numSessions = Int((dictionary["numSessions"] as? String) ?? "0")
                userMusician.profileImageURL = dictionary["profileImageURL"] as? String
                
                completionHandler(userMusician)
            }
        })
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
    
    // MARK: Actions
    
    private func createSession(completionHandler: @escaping CreateSessionClosure) {
        let mySession = Session()
        
        let sessionCode = createSessionCode()
        
        guard let name = titleTextField.text, let genre = genreTextField.text,
                let userName = Auth.auth().currentUser?.displayName, let location = locationTextField.text,
                let userCity = currentUserMusician.city, let userCountry = currentUserMusician.country
            else {
                return
        }
        
        let userLocation = "\(userCity), \(userCountry)"
        
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let allSessionsRef = ref.child("all sessions")
        let allSessionsKey = allSessionsRef.childByAutoId()
        let values = ["name": name, "genre": genre, "location": location, "host": userName,
                      "code": sessionCode, "ID": allSessionsKey.key, "hostUID": uid ?? "",
                      "hostLocation": userLocation, "isActive": "true"]
        
        mySession.name = name
        mySession.genre = genre
        mySession.location = location
        mySession.host = userName
        mySession.code = sessionCode
        mySession.ID = allSessionsKey.key
        mySession.hostUID = uid ?? ""
        mySession.hostLocation = userLocation
        mySession.isActive = true
        
        allSessionsKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if let error = error {
                print (error)
                return
            }
            else {
                print("Session made public")
            }
        })
        
        //Add the current user to musicians list
        addCurrentUserToSession(allSessionsKey: allSessionsKey, session: mySession)
        overallSession.musicians?.append(currentUserMusician)
        
        //Send invites and add invitees to the invitees list
        if let invitedMusicians = invitedMusicians {
            sendInvites(musicians: invitedMusicians, session: mySession)
            
            for musician in invitedMusicians {
                let allSessionsMusiciansKey = allSessionsKey.child("invitees").childByAutoId()
                
                guard let musicianID = musician.uid
                    else {
                        return
                }
                
                let musicianValues = ["musicianID": musicianID]
                
                allSessionsMusiciansKey.updateChildValues(musicianValues, withCompletionBlock: { (error, ref) in
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
        
        completionHandler(mySession)
    }
    
    func addCurrentUserToSession(allSessionsKey: DatabaseReference, session: Session) {
        let allSessionsMusiciansKey = allSessionsKey.child("musicians").childByAutoId()
        
        let musician = currentUserMusician
        
        guard let musicianID = musician.uid
            else {
                return
        }
        
        let musicianValues = ["musicianID": musicianID]
        
        allSessionsMusiciansKey.updateChildValues(musicianValues, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                return
            } else {
                if let musicianName = musician.name {
                    print("\(musicianName) added to session")
                }
                
                self.updateCurrentUserSessionInformation(session: session)
            }
        })
    }
    
    func updateCurrentUserSessionInformation(session: Session) {
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let userKey = ref.child("users").child(uid!)
        
        let values = ["lastSession": session.name as Any, "numSessions": String(currentUserMusician.numSessions! + 1)]
        
        userKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                return
            } else {
                print("User session info updated")
            }
        })
    }
    
    func sendInvites(musicians: [Musician], session: Session) {
        let ref = Database.database().reference()
        for musician in musicians {
            let uid = musician.uid
            let musicianInvitationsRef = ref.child("users").child(uid!).child("invitations")
            let musicianInvitationsKey = musicianInvitationsRef.childByAutoId()
            
            let values = ["sessionID": session.ID as Any]
            
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
    
    @IBAction func beginSession(_ sender: UIBarButtonItem) {
        print("Beginning Session !!!!!")
        createSession { (resultSession) in
            self.overallSession = resultSession ?? Session()
            
            self.performSegue(withIdentifier: "GoToCurrentJamFromNewSession", sender: nil)
        }
    }
    
    @IBAction func inviteMusiciansTapped(_ sender: UIButton) {
        self.performSegue(withIdentifier: "GoToInviteMusiciansFromNewSession", sender: nil)
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCurrentJamFromNewSession" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! CurrentJamViewController
            
            newViewController.currentSession = overallSession
            newViewController.origin = "NewSession"
        } else if segue.identifier == "GoToInviteMusiciansFromNewSession" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! InviteMusiciansTableViewController
            
            newViewController.origin = "NewSession"
            newViewController.alreadySelectedMusicians = invitedMusicians
            newViewController.alreadySelectedMusicianUIDs = invitedMusicianUIDs
        }
    }
    
    @IBAction func unwindToNewSession(sender: UIStoryboardSegue) {
        DispatchQueue.main.async(execute: {
            self.musicianTableView.reloadData()
        })
    }
}
