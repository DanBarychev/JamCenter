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
    @IBOutlet weak var propertiesCollectionView: UICollectionView!
    
    typealias PropertiesClosure = ([String: String]) -> Void
    
    var instruments = String()
    var genres = String()
    var city = String()
    var country = String()
    var numSessions = String()
    let propertyTitles = ["Instruments","Genres","Location","Sessions"]
    let propertyCellSizes = Array(repeatElement(CGSize(width:165, height:138), count: 4))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        propertiesCollectionView.delegate = self
        propertiesCollectionView.dataSource = self

        self.profileImageView.clipsToBounds = true
        
        getData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2.0
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
                
                if let userCity = dictionary["city"] as? String, let userCountry = dictionary["country"] as? String, let userGenres = dictionary["genres"] as? String, let userInstruments = dictionary["instruments"] as? String, let userNumSessions = dictionary["numSessions"] as? String {
                    self.city = userCity
                    self.country = userCountry
                    self.genres = userGenres
                    self.instruments = userInstruments
                    self.numSessions = userNumSessions
                }

                if let profileImageURL = dictionary["profileImageURL"] as? String {
                    self.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
                }
                
                self.propertiesCollectionView.reloadData()
            }
        })
    }
    
    // MARK: Logout
    
    func handleLogout () {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
    }

    // MARK: Actions
    
    @IBAction func logout(_ sender: Any) {
        handleLogout()
    }
    
    // MARK: Navigation
    
    @IBAction func unwindToProfileView(sender: UIStoryboardSegue) {
        getData()
    }
}

// MARK: Collection View

extension ProfileViewController: UICollectionViewDataSource {
    func collectionView( _ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return propertyTitles.count
    }
    
    func collectionView( _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = propertiesCollectionView.dequeueReusableCell( withReuseIdentifier: "ProfileCell", for: indexPath) as! ProfileCollectionViewCell
        
        let propertyTitle = propertyTitles[indexPath.row]
        cell.nameLabel.text = propertyTitle
        
        if propertyTitle == "Instruments" {
            cell.valueLabel.text = instruments
        } else if propertyTitle == "Genres" {
            cell.valueLabel.text = genres
        } else if propertyTitle == "Location" {
            cell.valueLabel.text = "\(city),\n\(country)"
        } else if propertyTitle == "Sessions" {
            cell.valueLabel.text = numSessions
        }
        
        return cell
    }
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return propertyCellSizes[indexPath.item]
    }
    
    // Center the cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellWidth : CGFloat = 165.0
        
        let numberOfCells = 4 as CGFloat
        let edgeInsets = (self.propertiesCollectionView.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIEdgeInsetsMake(15, edgeInsets, 0, edgeInsets)
        } else {
            return UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }
}

