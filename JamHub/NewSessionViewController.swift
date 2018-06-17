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
    var musicians = [Musician]()
    var selectedMusicians = [Musician]()
    var selectedMusicianNames = [String]()
    
    var genreOptions = ["Rock", "Rap/Hip-Hop", "Jazz/Blues", "Pop", "Country", "Classical"]
    
    typealias CurrentSessionClosure = (Session?) -> Void
    typealias MusicianClosure = (Musician?) -> Void
    var currentUserMusician = Musician()

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
        
        // Find the current user's musician profile
        getData { (musician) in
            self.currentUserMusician = musician ?? Musician()
        }
    }
    
    // MARK: Table View
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicians.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewSessionMusicianCell", for: indexPath) as! NewSessionMusicianTableViewCell
        
        // set the text from the data model
        let musician = musicians[indexPath.row]
        
        cell.nameLabel.text = musician.name
        cell.instrumentsLabel.text = musician.instruments
        if let profileImageURL = musician.profileImageURL {
            cell.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
        }
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2
        cell.profileImageView.clipsToBounds = true
        
        return cell
    }
    
    // When we select a musician
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! NewSessionMusicianTableViewCell
        
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
    
    // MARK: Download Musicians From Firebase
    func getData(completionHandler: @escaping MusicianClosure) {
        let usersRef = Database.database().reference().child("users")
        
        usersRef.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let sessionMusician = Musician()
                
                sessionMusician.uid = snapshot.key
                sessionMusician.name = dictionary["name"] as? String
                sessionMusician.genres = dictionary["genres"] as? String
                sessionMusician.instruments = dictionary["instruments"] as? String
                sessionMusician.profileImageURL = dictionary["profileImageURL"] as? String
                sessionMusician.numSessions = Int((dictionary["numSessions"] as? String) ?? "0")
                sessionMusician.lastSession = dictionary["lastSession"] as? String
                
                //We don't want to add the current user
                if sessionMusician.uid != Auth.auth().currentUser?.uid {
                    self.musicians.append(sessionMusician)
                } else {
                    completionHandler(sessionMusician)
                }
                
                DispatchQueue.main.async {
                    self.musicianTableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    
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
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToMyActiveSession" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! MyActiveSessionViewController
            
            newViewController.mySession = overallSession
        }
    }
    
    // MARK: Actions
    private func createSession(completionHandler: @escaping CurrentSessionClosure) {
        let mySession = Session()
        
        let sessionCode = createSessionCode()
        
        guard let name = titleTextField.text, let genre = genreTextField.text,
                let userName = Auth.auth().currentUser?.displayName, let location = locationTextField.text,
                    let userImageURL = Auth.auth().currentUser?.photoURL
            else {
                return
        }
        
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let allSessionsRef = ref.child("all sessions")
        let allSessionsKey = allSessionsRef.childByAutoId()
        let values = ["name": name, "genre": genre, "location": location, "host": userName,
                      "code": sessionCode, "ID": allSessionsKey.key, "hostUID": uid ?? "",
                      "isActive": "true"]
        
        mySession.name = name
        mySession.genre = genre
        mySession.location = location
        mySession.host = userName
        mySession.code = sessionCode
        mySession.ID = allSessionsKey.key
        mySession.hostUID = uid ?? ""
        mySession.isActive = true
        
        allSessionsKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print (error!)
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
        sendInvites(musicians: selectedMusicians, session: mySession)
        
        for musician in selectedMusicians {
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
        }
        performSegue(withIdentifier: "GoToMyActiveSession", sender: nil)
    }
}
