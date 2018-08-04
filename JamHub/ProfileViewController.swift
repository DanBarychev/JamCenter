//
//  ProfileViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
//  User icon from https://icons8.com/icon/23265/User-Filled

import UIKit
import Firebase

class ProfileViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var instrumentsLabel: UILabel!
    @IBOutlet weak var genresLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var numSessionsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
        
        getData()
    }
    
    // MARK: Firebase Download
    
    func getData() {
        let uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: {
            (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.nameLabel.text = (dictionary["name"] as? String)
                let city = dictionary["city"] as? String
                let country = dictionary["country"] as? String
                let genres = dictionary["genres"] as? String
                let instruments = dictionary["instruments"] as? String
                let numSessions = dictionary["numSessions"] as? String
                if let profileImageURL = dictionary["profileImageURL"] as? String {
                    self.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
                }
                
                self.instrumentsLabel.text = instruments
                self.genresLabel.text = genres
                self.cityLabel.text = city
                self.countryLabel.text = country
                self.numSessionsLabel.text = numSessions
            }
        })
    }
    
    // MARK: Logout
    
    func handleLogout () {
        do {
            try Auth.auth().signOut()
            print("User logged out")
        } catch let logoutError {
            print(logoutError)
        }
    }

    
    // MARK: Navigation
    
    @IBAction func unwindToProfileView(sender: UIStoryboardSegue) {
        getData()
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
 
    
    // MARK: Actions
    
    @IBAction func logout(_ sender: Any) {
        handleLogout()
    }
    

}
