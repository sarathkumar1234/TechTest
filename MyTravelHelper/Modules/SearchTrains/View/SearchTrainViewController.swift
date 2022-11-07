//
//  SearchTrainViewController.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import UIKit
import SwiftSpinner
import DropDown

@objc protocol FavoritesProtocol{
    @objc func addSourceAsFavorite()
    @objc func addDestinationAsFavorite()
    @objc func sourceSelectFromFavorites()
    @objc func destinationSelectFromFavorites()
}

class SearchTrainViewController: UIViewController {
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var sourceTxtField: UITextField!
    @IBOutlet weak var trainsListTable: UITableView!
    
    @IBOutlet weak var sourceFavorite : UIButton!
    @IBOutlet weak var destinationFavorite : UIButton!
    
    @IBOutlet weak var sourceFavoriteSelection : UIButton!
    @IBOutlet weak var destinationFavoriteSelection : UIButton!

    var stationsList:[Station] = [Station]()
    var trains:[StationTrain] = [StationTrain]()
    var presenter:ViewToPresenterProtocol?
    var dropDown = DropDown()
    var transitPoints:(source:String,destination:String) = ("","")
    var favorites : [Station] = [Station]()
    var sourceSelectedIndex : Int?
    var destinationSelectedIndex : Int?


    override func viewDidLoad() {
        super.viewDidLoad()
        trainsListTable.isHidden = true
        
        
        if let data = UserDefaults.standard.value(forKey: "Favorites") as? Data{
            
            if let favorites = try? JSONDecoder().decode([Station].self, from: data){
                
                self.favorites = favorites
                
            }
        }
        
        self.setupFavoriteActions()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        if stationsList.count == 0 {
            SwiftSpinner.useContainerView(view)
            SwiftSpinner.show("Please wait loading station list ....")
            presenter?.fetchallStations()
        }
        if self.favorites.count <= 0{
            self.sourceFavoriteSelection.isHidden = true
            self.destinationFavoriteSelection.isHidden = true
        }
    }
    func setupFavoriteActions(){
        
        self.sourceFavorite.addTarget(self, action: #selector(addSourceAsFavorite), for: .touchUpInside)
        
        self.destinationFavorite.addTarget(self, action: #selector(addDestinationAsFavorite), for: .touchUpInside)
        
        self.sourceFavoriteSelection.addTarget(self, action: #selector(sourceSelectFromFavorites), for: .touchUpInside)
        
        self.destinationFavoriteSelection.addTarget(self, action: #selector(destinationSelectFromFavorites), for: .touchUpInside)
        
        

    }
    
    @IBAction func searchTrainsTapped(_ sender: Any) {
        view.endEditing(true)
        showProgressIndicator(view: self.view)
        if transitPoints.source != "" && transitPoints.destination != "" {
            
            presenter?.searchTapped(source: transitPoints.source, destination: transitPoints.destination)
            
        }
        else{
            
            self.showInvalidSourceOrDestinationAlert()
            
        }
    }
}
extension SearchTrainViewController : FavoritesProtocol{
        
    @objc func addSourceAsFavorite(){
        if sourceTxtField.text != ""{
            if let index = sourceSelectedIndex {
                
                sourceSelectedIndex = 0
                
                let station = stationsList[index]
                
                self.favorites.append(station)
                
                if #available(iOS 13.0, *) {
                    if let  favImage = UIImage(systemName: "star.fill"){
                        sourceFavorite.setImage(favImage, for: .normal)
                    }
                } else {
                    // Fallback on earlier versions
                }
                
                
               if let encodeData = try? JSONEncoder().encode(favorites){
                    UserDefaults.standard.set(encodeData, forKey: "Favorites")
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    @objc func addDestinationAsFavorite(){
        if destinationTextField.text != ""{
            if let index = destinationSelectedIndex {
                
                destinationSelectedIndex = 0
                
                let station = stationsList[index]
                
                self.favorites.append(station)
                
                if #available(iOS 13.0, *) {
                    if let  favImage = UIImage(systemName: "star.fill"){
                        destinationFavorite.setImage(favImage, for: .normal)
                    }
                } else {
                    // Fallback on earlier versions
                }
                
                if let encodeData = try? JSONEncoder().encode(favorites){
                    UserDefaults.standard.set(encodeData, forKey: "Favorites")
                    UserDefaults.standard.synchronize()
                }
                
                
            }
        }
    }
    
    @objc func sourceSelectFromFavorites(){
        
        dropDown = DropDown()
        dropDown.anchorView = self.sourceFavoriteSelection
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        if self.favorites.count > 0 {
            dropDown.dataSource = favorites.map {$0.stationDesc}
            
            dropDown.selectionAction = { (index: Int, item: String) in
                self.transitPoints.source = item
                self.sourceTxtField.text = item
            }
            dropDown.show()
        }else{
            dropDown.hide()
            self.showAlert(title: "Not available", message: "Favorites not available", actionTitle: "Okay")
        }
    }
    
    @objc func destinationSelectFromFavorites(){
        dropDown = DropDown()
        dropDown.anchorView = self.destinationFavoriteSelection
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        if self.favorites.count > 0 {
            dropDown.dataSource = favorites.map {$0.stationDesc}
            
            dropDown.selectionAction = { (index: Int, item: String) in
                self.transitPoints.destination = item
                self.destinationTextField.text = item
            }
            dropDown.show()
        }else{
            dropDown.hide()
            self.showAlert(title: "Not available", message: "Favorites not available", actionTitle: "Okay")
        }
    }
    
}
extension SearchTrainViewController:PresenterToViewProtocol {
    func showNoInterNetAvailabilityMessage() {
        trainsListTable.isHidden = true
        hideProgressIndicator(view: self.view)
        showAlert(title: "No Internet", message: "Please Check you internet connection and try again", actionTitle: "Okay")
    }

    func showNoTrainAvailbilityFromSource() {
        DispatchQueue.main.async {
            
            self.trainsListTable.isHidden = true
            self.hideProgressIndicator(view: self.view)
            self.showAlert(title: "No Trains", message: "Sorry No trains arriving source station in another 90 mins", actionTitle: "Okay")
            
        }
        
    }

    func updateLatestTrainList(trainsList: [StationTrain]) {
        hideProgressIndicator(view: self.view)
        trains = trainsList
        trainsListTable.isHidden = false
        trainsListTable.reloadData()
    }

    func showNoTrainsFoundAlert() {
        trainsListTable.isHidden = true
        hideProgressIndicator(view: self.view)
        trainsListTable.isHidden = true
        showAlert(title: "No Trains", message: "Sorry No trains Found from source to destination in another 90 mins", actionTitle: "Okay")
    }

    func showAlert(title:String,message:String,actionTitle:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func showInvalidSourceOrDestinationAlert() {
        trainsListTable.isHidden = true
        hideProgressIndicator(view: self.view)
        showAlert(title: "Invalid Source/Destination", message: "Invalid Source or Destination Station names Please Check", actionTitle: "Okay")
    }

    func saveFetchedStations(stations: [Station]?) {
        if let _stations = stations {
          self.stationsList = _stations
        }
        SwiftSpinner.hide()
    }
}

extension SearchTrainViewController:UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        dropDown = DropDown()
        dropDown.anchorView = textField
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        dropDown.dataSource = stationsList.map {$0.stationDesc}
        dropDown.selectionAction = { (index: Int, item: String) in
            if textField == self.sourceTxtField {
                self.sourceSelectedIndex = index
                self.transitPoints.source = item
            }else {
                self.destinationSelectedIndex = index
                self.transitPoints.destination = item
            }
            textField.text = item
        }
        dropDown.show()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dropDown.hide()
        return textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let inputedText = textField.text {
            var desiredSearchText = inputedText
            if string != "\n" && !string.isEmpty{
                desiredSearchText = desiredSearchText + string
            }else {
                desiredSearchText = String(desiredSearchText.dropLast())
            }

            dropDown.dataSource = stationsList.map {$0.stationDesc}
            dropDown.show()
            dropDown.reloadAllComponents()
        }
        return true
    }
}

extension SearchTrainViewController:UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trains.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "train", for: indexPath) as! TrainInfoCell
        let train = trains[indexPath.row]
        cell.trainCode.text = train.trainCode
        cell.souceInfoLabel.text = train.stationFullName
        cell.sourceTimeLabel.text = train.expDeparture
        if let _destinationDetails = train.destinationDetails {
            cell.destinationInfoLabel.text = _destinationDetails.locationFullName
            cell.destinationTimeLabel.text = _destinationDetails.expDeparture
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}
