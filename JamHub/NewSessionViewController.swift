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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var genreTextField: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationTextField: UITextField!
    
    @IBOutlet weak var musicianTableView: UITableView!
    var overallSession = Session()
    var overallAllSessionsKey = DatabaseReference()
    var musicians = [Musician]()
    var selectedMusicians = [Musician]()
    var selectedMusicianNames = [String]()
    
    var genreOptions = ["Rock", "Rap/Hip-Hop", "Jazz/Blues", "Pop", "Country", "Classical"]
    
    typealias CurrentUserMusicianClosure = (Musician?) -> Void
    typealias CurrentSessionClosure = (Session?, DatabaseReference?) -> Void
    var currentUserMusician = Musician()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        musicianTableView.delegate = self
        musicianTableView.dataSource = self

        titleTextField.delegate = self
        locationTextField.delegate = self
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        genreTextField.inputView = pickerView
        
        getData { (musician) in
            self.currentUserMusician = musician!
            
            print("Just assigned")
            print("The current user is \(self.currentUserMusician.name ?? "the user")")
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
        
        if cell.okIcon.isHidden {
            cell.okIcon.isHidden = false
            
            selectedMusicianNames.append(musician.name!)
            selectedMusicians.append(musician)
        } else {
            cell.okIcon.isHidden = true
            
            if let index = selectedMusicianNames.index(of: musician.name!) {
                selectedMusicianNames.remove(at: index)
                selectedMusicians.remove(at: index)
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
          titleLabel.text = "Title: " + titleTextField.text!
        }
        else if textField == locationTextField {
            locationLabel.text = "Location: " + locationTextField.text!
        }
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
    }
    
    // MARK: Download Musicians From Firebase
    func getData(completionHandler: @escaping CurrentUserMusicianClosure) {
        Database.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let musician = Musician()
                
                musician.uid = snapshot.key
                musician.name = dictionary["name"] as? String
                musician.instruments = dictionary["instruments"] as? String
                musician.genres = dictionary["genres"] as? String
                musician.profileImageURL = dictionary["profileImageURL"] as? String
                musician.numSessions = Int((dictionary["numSessions"] as? String) ?? "0")
                musician.lastSession = dictionary["lastSession"] as? String
                
                //We don't want to add the current user
                if musician.name != Auth.auth().currentUser?.displayName ||
                    musician.profileImageURL != Auth.auth().currentUser?.photoURL?.absoluteString{
                    
                    self.musicians.append(musician)
                } else {
                    completionHandler(musician)
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
                      "hostImageURL": userImageURL.absoluteString, "code": sessionCode,
                      "ID": allSessionsKey.key, "hostUID": uid ?? "",
                      "isActive": "true"]
        
        mySession.name = name
        mySession.genre = genre
        mySession.location = location
        mySession.host = userName
        mySession.hostImageURL = userImageURL.absoluteString
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
        
        //Update current user session info
        updateCurrentUserSessionInformation(session: mySession)
        
        //Send invites before we add current user to list
        sendInvites(musicians: selectedMusicians, session: mySession)
        
        //Add the current user to musicians list
        selectedMusicians.insert(currentUserMusician, at: 0)
        mySession.musicians = selectedMusicians
        
        for musician in selectedMusicians {
            let allSessionsMusiciansKey = allSessionsKey.child("musicians").childByAutoId()
            
            guard let musicianName = musician.name, let musicianGenres = musician.genres, let musicianInstruments = musician.instruments,
                let musicianProfileImageURL = musician.profileImageURL
                else {
                    return
            }
            
            let musicianValues = ["name": musicianName, "genres": musicianGenres,
                                  "instruments": musicianInstruments, "profileImageURL": musicianProfileImageURL]
            
            allSessionsMusiciansKey.updateChildValues(musicianValues, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    print("\(musicianName) added to public version of session")
                }
            })
        }
        
        completionHandler(mySession, allSessionsKey)
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
        createSession { (resultSession, resultAllSessionsKey) in
            self.overallSession = resultSession ?? Session()
            self.overallAllSessionsKey = resultAllSessionsKey ?? DatabaseReference()
        }
        performSegue(withIdentifier: "GoToMyActiveSession", sender: nil)
    }
    

}
