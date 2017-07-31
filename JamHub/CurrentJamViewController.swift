//
//  CurrentJamViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/3/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class CurrentJamViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var currentSession: Session?
    var musicians = [Musician]()
    var sessionCode = String()
    var sessionID = String()
    var sessionHostUID = String()
    
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var genreNameLabel: UILabel!
    @IBOutlet weak var hostImageView: UIImageView!
    @IBOutlet weak var genreImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var manageButton: UIBarButtonItem!
    @IBOutlet weak var joinSessionButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    typealias CurrentUserMusicianClosure = (Musician?) -> Void
    var currentUserMusician = Musician()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manageButton.isEnabled = false
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.hostImageView.layer.cornerRadius = self.hostImageView.frame.size.width / 2
        self.hostImageView.clipsToBounds = true
        
        self.genreImageView.layer.cornerRadius = self.genreImageView.frame.size.width / 2
        self.genreImageView.clipsToBounds = true
        
        joinSessionButton.layer.cornerRadius = 15
        joinSessionButton.layer.borderWidth = 2
        joinSessionButton.layer.borderColor = UIColor.black.cgColor
        
        if let currentJamSession = currentSession {
            navigationItem.title = currentJamSession.name
            hostNameLabel.text = currentJamSession.host
            genreNameLabel.text = currentJamSession.genre
            setCurrentProfilePicture(profileImageURL: currentJamSession.hostImageURL ?? "gs://jamhub-54eec.appspot.com/profile_images/9B93A0B2-5A36-4607-BC48-BA3F2E6D31FF.jpg")
            locationLabel.text = currentJamSession.location
            sessionCode = currentJamSession.code ?? "unavailable"
            sessionID = currentJamSession.ID ?? "unavailable"
            sessionHostUID = currentJamSession.hostUID ?? "unavailable"
            musicians = currentJamSession.musicians ?? []
            
            if genreNameLabel.text == "Rock" {
                genreImageView.image = UIImage(named: "RockIcon")
            }
            if genreNameLabel.text == "Jazz/Blues" {
                genreImageView.image = UIImage(named: "JazzIcon")
            }
            if genreNameLabel.text == "Rap/Hip-Hop" {
                genreImageView.image = UIImage(named: "RapIcon")
            }
            if genreNameLabel.text == "Pop" {
                genreImageView.image = UIImage(named: "PopIcon")
            }
            if genreNameLabel.text == "Country" {
                genreImageView.image = UIImage(named: "CountryIcon")
            }
            if genreNameLabel.text == "Classical" {
                genreImageView.image = UIImage(named: "ClassicalIcon")
            }
            
            getUserInfo() { (musician) in
                self.currentUserMusician = musician ?? Musician()
            }
            
            checkIfMusicianIsInSession()
            
            if currentJamSession.hostUID == Auth.auth().currentUser?.uid {
                manageButton.isEnabled = true
            }
        }
    }

    // MARK: Table View
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicians.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrentJamMusicianCell", for: indexPath) as! CurrentJamMusicianTableViewCell
        
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
    
    func setCurrentProfilePicture(profileImageURL: String) {
        let url = NSURL(string: profileImageURL)
        URLSession.shared.dataTask(with: url! as URL, completionHandler: {(data, response, error) in
            
            if error != nil {
                print(error!)
                return
            }
            else {
                print("Successful Image Download")
                DispatchQueue.main.async {
                    self.hostImageView.image = UIImage(data: data!)
                }
            }
        }).resume()
    }
    
    func requestSessionCode() {
        let alertController = UIAlertController(title: "Session Code", message: "Please input the session code", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Join", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store your data
                if field.text == self.sessionCode {
                    self.addMusicianToSession()
                    self.updateUserInfo()
                    self.performSegue(withIdentifier: "JoinSession", sender: nil)
                } else {
                    self.presentIncorrectCodeAlert()
                }
            } else {
                // user did not fill field
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Session Code"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentIncorrectCodeAlert() {
        let alertController = UIAlertController(title: "Incorrect Code", message: "An invalid code was entered", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "OK", style: .default)
        
        alertController.addAction(confirmAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func getUserInfo(completionHandler: @escaping CurrentUserMusicianClosure) {
        Database.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let musician = Musician()
                
                musician.name = dictionary["name"] as? String
                musician.instruments = dictionary["instruments"] as? String
                musician.genres = dictionary["genres"] as? String
                musician.profileImageURL = dictionary["profileImageURL"] as? String
                musician.lastSession = dictionary["lastSession"] as? String
                musician.numSessions = Int((dictionary["numSessions"] as? String) ?? "0")
                
                //We want to get only the current user
                if musician.name == Auth.auth().currentUser?.displayName &&
                    musician.profileImageURL == Auth.auth().currentUser?.photoURL?.absoluteString{
                    print("Found the user")
                    
                    completionHandler(musician)
                }
            }
        }, withCancel: nil)
    }
    
    func checkIfMusicianIsInSession() {
        let ref = Database.database().reference()
        let sessionKey = ref.child("all sessions").child(sessionID)
        
        let sessionMusiciansKey = sessionKey.child("musicians")
        
        sessionMusiciansKey.observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let musician = Musician()
                
                musician.name = dictionary["name"] as? String
                musician.instruments = dictionary["instruments"] as? String
                musician.genres = dictionary["genres"] as? String
                musician.profileImageURL = dictionary["profileImageURL"] as? String
                musician.lastSession = dictionary["lastSession"] as? String
                musician.numSessions = Int((dictionary["numSessions"] as? String) ?? "0")
                
                //We want to get only the current user
                if musician.name == Auth.auth().currentUser?.displayName &&
                    musician.profileImageURL == Auth.auth().currentUser?.photoURL?.absoluteString{
                    
                    self.joinSessionButton.setTitle("View Media", for: UIControlState.normal)
                }
            }
        }, withCancel: nil)
    }
    
    func addMusicianToSession() {
        print("Correct Code")
        
        musicians.append(currentUserMusician)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        let ref = Database.database().reference()
        let allSessionsKey = ref.child("all sessions").child(sessionID)
        
        let allSessionsMusiciansKey = allSessionsKey.child("musicians").childByAutoId()
        
        guard let musicianName = currentUserMusician.name, let musicianGenres = currentUserMusician.genres,
            let musicianInstruments = currentUserMusician.instruments, let musicianProfileImageURL = currentUserMusician.profileImageURL,
                let musicianNumSessions = currentUserMusician.numSessions, let musicianLastSession = currentUserMusician.lastSession
            else {
                return
        }
        
        let musicianValues = ["name": musicianName, "genres": musicianGenres,
                              "instruments": musicianInstruments, "profileImageURL": musicianProfileImageURL,
                              "numSessions": String(musicianNumSessions), "lastSession": musicianLastSession]
        
        allSessionsMusiciansKey.updateChildValues(musicianValues, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                
                return
            } else {
                print("\(musicianName) added to public version of session")
            }
        })
    }
    
    func updateUserInfo() {
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let userKey = ref.child("users").child(uid!)
        
        let numSessions = String((currentUserMusician.numSessions ?? 0) + 1)
        guard let lastSession = navigationItem.title
            else {
                return
        }
        
        let values = ["numSessions": numSessions, "lastSession": lastSession]
        
        userKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                
                return
            } else {
                print("\(self.currentUserMusician.name ?? "The User's") information updated")
            }
        })
    }

    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "JoinSession" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! ActiveCurrentSessionViewController
            
            newViewController.currentSession = currentSession
        }
        else if segue.identifier == "ViewMusician" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! OtherMusicianProfileViewController
            
            if let selectedJamCell = sender as? CurrentJamMusicianTableViewCell
            {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                let selectedMusician = musicians[indexPath.row]
                newViewController.selectedMusician = selectedMusician
            }
        }
        else if segue.identifier == "GoToMyActiveSessionFromCurrentJam" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! MyActiveSessionViewController
            
            newViewController.mySession = currentSession
        }
    }
    
    @IBAction func unwindToCurrentJam(sender: UIStoryboardSegue) {
    }
    
    // MARK: Actions
    
    @IBAction func joinSession(_ sender: Any) {
        if joinSessionButton.currentTitle == "Join Session" {
            requestSessionCode()
        } else {
            performSegue(withIdentifier: "JoinSession", sender: nil)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func manageJamSession(_ sender: Any) {
        performSegue(withIdentifier: "GoToMyActiveSessionFromCurrentJam", sender: nil)
    }
}
