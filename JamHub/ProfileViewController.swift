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

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    let cellReuseIdentifier = "ProfileTableViewCell"
    
    var properties = ["Genres: ", "Instruments: ", "Last Session: ", "Number of Sessions: "]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
    }

    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.properties.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell?)!
        print(properties)
        // set the text from the data model
        cell.textLabel?.text = self.properties[indexPath.row]
        
        return cell
    }
    
    // Download data from Firebase
    func getData() {
        let uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: {
            (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.nameLabel.text = (dictionary["name"] as! String)
                let genres = dictionary["genres"] as! String
                let instruments = dictionary["instruments"] as! String
                let lastSession = dictionary["lastSession"] as! String
                let numSessions = dictionary["numSessions"] as! String
                if let profileImageURL = dictionary["profileImageURL"] as? String {
                    self.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
                }
                
                self.properties[0] = "Genres: " + genres
                self.properties[1] = "Instruments: " + instruments
                self.properties[2] = "Last Session: " + lastSession
                self.properties[3] = "Number of Sessions: " + numSessions
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
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
