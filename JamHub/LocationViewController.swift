//
//  LocationViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 6/23/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//
//  getValues() adapted from https://github.com/salvonos/CityPicker/blob/master/Pod/Classes/CityPickerClass.swift

import UIKit

class LocationViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var countries = [String]()
    var countryCityDict = NSDictionary()
    
    // Default values alphabetically
    var selectedCountry = "Afghanistan"
    var selectedCity = "Kabul"
    
    @IBOutlet weak var countryPicker: UIPickerView!
    @IBOutlet weak var cityPicker: UIPickerView!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var selectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        
        countryPicker.delegate = self
        cityPicker.delegate = self
        
        selectButton.layer.cornerRadius = 20
        selectButton.layer.borderWidth = 2.0
        selectButton.layer.borderColor = UIColor.black.cgColor
        
        nextButton.isEnabled = false
        
        (countries, countryCityDict) = getValues()
        
    }
    
    // MARK: PickerView
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent compenent: Int) -> Int {
        if pickerView == countryPicker {
            return countries.count
        } else {
            return (countryCityDict[selectedCountry] as! [String]).count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == countryPicker {
            return countries[row]
        } else {
            return (countryCityDict[selectedCountry] as! [String])[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == countryPicker {
            selectedCountry = countries[row]
            cityPicker.reloadAllComponents()
        } else {
            selectedCity = (countryCityDict[selectedCountry] as! [String])[row]
        }
    }
    
    // MARK: Get Data from JSON
    
    func getValues() -> (countries:[String], countryCityDict:NSDictionary){
        var countries = [String]()
        var countryCityDict = NSDictionary()
        
        if let path = Bundle.main.path(forResource: "countriesToCities", ofType: "json") {
            do {
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
                    
                    let countriesArray = (jsonResult as AnyObject).allKeys as! [String]
                    countries = countriesArray.sorted()
                    
                    countryCityDict = jsonResult as! NSDictionary
                } catch {}
            } catch {}
        }
    
        return (countries, countryCityDict)
    }

    // MARK: Navigation
    
    @IBAction func unwindToLocationViewController(sender: UIStoryboardSegue) {
    }

    // MARK: Actions
    
    @IBAction func selectButtonPressed(_ sender: UIButton) {
        nextButton.isEnabled = true
    }
    
}
