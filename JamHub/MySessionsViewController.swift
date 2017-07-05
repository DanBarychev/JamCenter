//
//  MySessionsViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
// Record icon from https://icons8.com/icon/9403/Music-Record-Filled

import UIKit
import Firebase

class MySessionsViewController: UITableViewController {
    
    var sessions = [Session]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        getData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionTableViewCell", for: indexPath) as! SessionTableViewCell
        
        let session = sessions[indexPath.row]
        
        cell.nameLabel?.text = session.name
        cell.genreLabel?.text = session.genre

        return cell
    }
    

    func getData() {
        let uid = Auth.auth().currentUser?.uid
        
        Database.database().reference().child("users").child(uid!).child("sessions").observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let newSession = Session()
                
                newSession.name = dictionary["name"] as? String
                newSession.genre = dictionary["genre"] as? String
                
                self.sessions.append(newSession)
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
            
        }, withCancel: nil)
    }

    
    // MARK: - Navigation
    
    @IBAction func unwindToMySessions(sender: UIStoryboardSegue) {
    }

}
