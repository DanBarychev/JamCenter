//
//  CurrentJamsViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
//  Globe icon from https://icons8.com/icon/2963/Globe-Filled

import UIKit
import Firebase

class CurrentJamsViewController: UITableViewController {
    
    var sessions = [Session]()
    var userLocation = String()
    typealias UserLocationClosure = (String?) -> Void
    typealias HostImageURLClosure = (String?) -> Void
    typealias HostLocationClosure = (String?) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        /*self.getUserLocation { (userLocationResult) in
            if let userLocationResult = userLocationResult {
                self.userLocation = userLocationResult
            }
        }*/
        
        userLocation = "Philadelphia, United States"
        
        getData()
        
        self.tableView.addSubview(self.myRefreshControl)
    }
    
    // MARK: Refresh Control
    
    lazy var myRefreshControl: UIRefreshControl = {
        let myRefreshControl = UIRefreshControl()
        myRefreshControl.addTarget(self, action:
            #selector(MySessionsViewController.handleRefresh(_:)),
                                   for: UIControlEvents.valueChanged)
        
        return myRefreshControl
    }()
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        getData()
        refreshControl.endRefreshing()
    }

    // MARK: Table View Properties

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JamTableViewCell", for: indexPath) as! JamTableViewCell

        let session = sessions.reversed()[indexPath.row]
        
        cell.nameLabel?.text = session.name
        cell.genreLabel?.text = session.genre
        if let hostUID = session.hostUID {
            self.getHostImageURL(hostUID: hostUID) { (hostImageURL) in
                if let hostImageURL = hostImageURL {
                    cell.hostImageView.loadImageUsingCacheWithURLString(urlString: hostImageURL)
                }
            }
        }
        cell.hostImageView.layer.cornerRadius = cell.hostImageView.frame.size.width / 2
        cell.hostImageView.clipsToBounds = true
        
        return cell
    }
    
    func getData() {
        sessions.removeAll()
        
        Database.database().reference().child("all sessions").observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let newSession = Session()
                
                newSession.name = dictionary["name"] as? String
                newSession.genre = dictionary["genre"] as? String
                newSession.location = dictionary["location"] as? String
                newSession.host = dictionary["host"] as? String
                newSession.audioRecordingURL = dictionary["audioRecordingURL"] as? String
                newSession.code = dictionary["code"] as? String
                newSession.ID = dictionary["ID"] as? String
                newSession.hostUID = dictionary["hostUID"] as? String
                newSession.hostLocation = dictionary["hostLocation"] as? String
                newSession.isActive = Bool((dictionary["isActive"] as? String) ?? "false")
                
                guard let hostLocation = newSession.hostLocation else {
                    return
                }
                
                if self.userLocation == hostLocation && (newSession.isActive ?? false) {
                    self.sessions.append(newSession)
                    
                    DispatchQueue.main.async(execute: {
                        self.tableView.reloadData()
                    })
                }
            }
        }, withCancel: nil)
    }
    
    func getUserLocation(completionHandler: @escaping UserLocationClosure) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: {
            (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                if let userCity = dictionary["city"] as? String, let userCountry = dictionary["country"] as? String {
                    let userLocation = "\(userCity), \(userCountry)"
                    completionHandler(userLocation)
                    Database.database().reference().removeAllObservers()
                }
            }
        })
    }
    
    func getHostImageURL(hostUID: String, completionHandler: @escaping HostImageURLClosure) {
        Database.database().reference().child("users").child(hostUID).observeSingleEvent(of: .value, with: {
            (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {

                if let profileImageURL = dictionary["profileImageURL"] as? String {
                    completionHandler(profileImageURL)
                    Database.database().reference().removeAllObservers()
                }
            }
        })
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCurrentJam" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! CurrentJamViewController
            
            if let selectedJamCell = sender as? JamTableViewCell
            {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                let selectedJam = sessions.reversed()[indexPath.row]
                newViewController.currentSession = selectedJam
                newViewController.origin = "CurrentJams"
            }
        }
    }
    
    @IBAction func unwindToCurrentJams(sender: UIStoryboardSegue) {
    }

}
