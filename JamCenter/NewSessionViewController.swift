//
//  NewSessionViewController.swift
//  JamCenter
//
//  Created by Daniel Barychev on 5/21/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class NewSessionViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties

    @IBOutlet weak var nextButton: UIBarButtonItem!
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
        
        nextButton.isEnabled = false
        
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
        print("View Disappeared")
        
        // Remove observer
        Database.database().reference().removeAllObservers()
    }
    
    // MARK: Table View Data Source
    
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
            nextButton.isEnabled = true
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
    
    @IBAction func nextButtonTapped(_ sender: UIBarButtonItem) {
        overallSession.name = titleTextField.text
        overallSession.genre = genreTextField.text
        overallSession.location = locationTextField.text
        overallSession.musicians?.append(currentUserMusician)
        
        self.performSegue(withIdentifier: "GoToSetTimeFromNewSession", sender: nil)
    }
    
    @IBAction func inviteMusiciansTapped(_ sender: UIButton) {
        self.performSegue(withIdentifier: "GoToInviteMusiciansFromNewSession", sender: nil)
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToSetTimeFromNewSession" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! SetTimeViewController
            
            newViewController.newSession = overallSession
            newViewController.invitedMusicians = invitedMusicians
            newViewController.currentUserMusician = currentUserMusician
        } else if segue.identifier == "GoToInviteMusiciansFromNewSession" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! InviteMusiciansTableViewController
            
            newViewController.origin = "NewSession"
            newViewController.alreadySelectedMusicians = invitedMusicians
            newViewController.alreadySelectedMusicianUIDs = invitedMusicianUIDs
        } else if segue.identifier == "ViewMusicianFromNewSession" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! OtherMusicianProfileViewController
            
            if let selectedMusicianCell = sender as? NewSessionMusicianTableViewCell
            {
                let indexPath = musicianTableView.indexPath(for: selectedMusicianCell)!
                
                newViewController.selectedMusician = invitedMusicians?[indexPath.row]
                newViewController.origin = "NewSession"
            }
        }
    }
    
    @IBAction func unwindToNewSession(sender: UIStoryboardSegue) {
        DispatchQueue.main.async(execute: {
            self.musicianTableView.reloadData()
        })
    }
}
