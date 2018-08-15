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
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: {
            (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.nameLabel.text = dictionary["name"] as? String
                self.cityLabel.text = dictionary["city"] as? String
                self.countryLabel.text = dictionary["country"] as? String
                self.genresLabel.text = dictionary["genres"] as? String
                self.instrumentsLabel.text = dictionary["instruments"] as? String
                self.numSessionsLabel.text = dictionary["numSessions"] as? String
                if let profileImageURL = dictionary["profileImageURL"] as? String {
                    self.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
                }
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
