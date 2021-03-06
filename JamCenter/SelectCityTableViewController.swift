//
//  SelectCityTableViewController.swift
//  JamCenter
//
//  Created by Daniel Barychev on 7/4/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//
//  getCityOptions() adapted from https://github.com/salvonos/CityPicker/blob/master/Pod/Classes/CityPickerClass.swift

import UIKit
import Firebase

class SelectCityTableViewController: UITableViewController, UISearchBarDelegate {

    // MARK: Properties
    
    var cities = [String]()
    var citiesFiltered = [String]()
    var selectedCountry: String?
    var searchActive = false
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchBar.returnKeyType = UIReturnKeyType.done

        nextButton.isEnabled = false
        cities = getCityOptions()
    }
    
    // MARK: Search Bar Data Source
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        citiesFiltered = cities.filter({ (city) -> Bool in
            let isMatch = city.lowercased().contains(searchText.lowercased())
            
            return isMatch
        })
        if(citiesFiltered.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: Table View Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return citiesFiltered.count
        } else {
            return cities.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: "CityCell") as UITableViewCell?)!
        
        if searchActive {
            cell.textLabel?.text = citiesFiltered[indexPath.row]
        } else {
            cell.textLabel?.text = cities[indexPath.row]
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedCity = String()
        
        if searchActive {
            selectedCity = citiesFiltered[indexPath.row]
        } else {
            selectedCity = cities[indexPath.row]
        }
        
        uploadSelection(selectedCity: selectedCity)
    }

    // MARK: Location Data Retrieval
    
    func getCityOptions() -> [String] {
        var allCities = [String]()
        
        if let path = Bundle.main.path(forResource: "countriesToCities", ofType: "json") {
            do {
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
                    
                    let countryCityDict = jsonResult as! NSDictionary
                    
                    allCities = countryCityDict[selectedCountry as Any] as! [String]
                    
                    // Filter out any duplicates and sort
                    allCities = Array(Set(allCities))
                    allCities = allCities.sorted()
                } catch {}
            } catch {}
        }
        
        return allCities
    }
    
    // MARK: Upload Data
    
    func uploadSelection(selectedCity: String) {
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let userRef = ref.child("users").child(uid!)
        
        guard let selectedCountry = selectedCountry else {
            return
        }
        
        let values = ["country": selectedCountry, "city": selectedCity]
        
        userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if let error = error {
                print (error)
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
}
