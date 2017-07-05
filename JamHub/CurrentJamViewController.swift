//
//  CurrentJamViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/3/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit

class CurrentJamViewController: UIViewController {
    
    var currentSession: Session?
    
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var genreNameLabel: UILabel!
    @IBOutlet weak var hostImageView: UIImageView!
    @IBOutlet weak var genreImageView: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hostImageView.layer.cornerRadius = self.hostImageView.frame.size.width / 2
        self.hostImageView.clipsToBounds = true
        
        self.genreImageView.layer.cornerRadius = self.genreImageView.frame.size.width / 2
        self.genreImageView.clipsToBounds = true
        
        if let currentJamSession = currentSession {
            navigationItem.title = currentJamSession.name
            hostNameLabel.text = currentJamSession.host
            genreNameLabel.text = currentJamSession.genre
            setCurrentProfilePicture(profileImageURL: currentJamSession.hostImageURL!)
            
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
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
