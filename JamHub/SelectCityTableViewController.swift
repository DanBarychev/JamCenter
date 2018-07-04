//
//  SelectCityTableViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/4/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class SelectCityTableViewController: UITableViewController {

    var cities = [String]()
    var countryCityDict = NSDictionary()
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.isEnabled = false
        countryCityDict = getCityOptions()
    }

    // MARK: Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: "CountryCell") as UITableViewCell?)!
        cell.textLabel?.text = cities[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCity = cities[indexPath.row]
        
        uploadSelection(selectedCity: selectedCity)
    }

    // MARK: Location Data Retrieval
    
    func getCityOptions() -> NSDictionary {
        var countries = [String]()
        
        if let path = Bundle.main.path(forResource: "countriesToCities", ofType: "json") {
            do {
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
                    
                    countryCityDict = jsonResult as! NSDictionary
                } catch {}
            } catch {}
        }
        
        return countryCityDict
    }
    
    // MARK: Upload Data
    
    func uploadSelection(selectedCity: String) {
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let userRef = ref.child("users").child(uid!)
        let values = ["location": selectedCity]
        
        userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print (error!)
                return
            }
            else {
                self.nextButton.isEnabled = true
            }
        })
    }
    
    // MARK: Navigation
    
    @IBAction func unwindToSelectCity(sender: UIStoryboardSegue) {
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}
