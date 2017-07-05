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
    var musicians = [Musician]()
    var selectedMusicians = [Musician]()
    var selectedMusicianNames = [String]()
    
    var genreOptions = ["Rock", "Rap/Hip-Hop", "Jazz/Blues", "Pop", "Country", "Classical"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        musicianTableView.delegate = self
        musicianTableView.dataSource = self

        titleTextField.delegate = self
        locationTextField.delegate = self
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        genreTextField.inputView = pickerView
        
        getData()
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
        cell.genresLabel.text = musician.genres
        cell.instrumentsLabel.text = musician.instruments
        if let profileImageURL = musician.profileImageURL {
            cell.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
        }
        
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
    func getData() {
        Database.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let musician = Musician()
                
                musician.name = dictionary["name"] as? String
                musician.instruments = dictionary["instruments"] as? String
                musician.genres = dictionary["genres"] as? String
                musician.profileImageURL = dictionary["profileImageURL"] as? String
                
                self.musicians.append(musician)
                
                DispatchQueue.main.async {
                    self.musicianTableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    
    // MARK: Actions
    private func createSession() {
        guard let name = titleTextField.text, let genre = genreTextField.text,
                let userName = Auth.auth().currentUser?.displayName, let location = locationTextField.text,
                    let userImageURL = Auth.auth().currentUser?.photoURL
            else {
                return
        }
        
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        print(userName)
        let userSessionsRef = ref.child("users").child(uid!).child("sessions")
        let allSessionsRef = ref.child("all sessions")
        let userSessionKey = userSessionsRef.childByAutoId()
        let allSessionsKey = allSessionsRef.childByAutoId()
        let values = ["name": name, "genre": genre, "location": location, "host": userName, "hostImageURL": userImageURL.absoluteString]
        userSessionKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            
            if error != nil {
                print(error!)
                return
            }
            else {
                print("New Session Created")
            }
        })
        
        allSessionsKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print (error!)
                
                return
            }
            else {
                print("Session made public")
            }
        })
        
        let userSessionMusiciansKey = userSessionKey.child("musicians").childByAutoId()
        let allSessionsMusiciansKey = allSessionsKey.child("musicians").childByAutoId()
        
        for musician in selectedMusicians {
            guard let musicianName = musician.name, let musicianGenres = musician.genres, let musicianInstruments = musician.instruments,
                let musicianProfileImageURL = musician.profileImageURL
                else {
                    return
            }
            
            let musicianValues = ["name": musicianName, "genres": musicianGenres,
                                  "instruments": musicianInstruments, "profileImageURL": musicianProfileImageURL]
            
            userSessionMusiciansKey.updateChildValues(musicianValues, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    
                    return
                } else {
                    print("Musicians added to user copy of session")
                }
            })
            allSessionsMusiciansKey.updateChildValues(musicianValues, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    
                    return
                } else {
                    print("Musicians added to public version of session")
                }
            })
        }
    }
    
    @IBAction func beginSession(_ sender: UIBarButtonItem) {
        print("Beginning Session !!!!!")
        createSession()
        self.dismiss(animated: true, completion: nil)
    }
    

}
