//
//  SearchTrainInteractor.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import Foundation
import XMLParsing
import Alamofire

class SearchTrainInteractor: PresenterToInteractorProtocol {
    var _sourceStationCode = String()
    var _destinationStationCode = String()
    var presenter: InteractorToPresenterProtocol?
    
    let networkRequestHandler = NetworkRequestHandler()
    
    var stationsCount : Int = 0
    var fetchedTrainsCount : Int = 0
    var availableTrainsCount: Int = 0


    func fetchallStations() {
        if Reach().isNetworkReachable() == true {
            
            networkRequestHandler.getEntity(entityType: Stations.self, urlString: "http://api.irishrail.ie/realtime/realtime.asmx/getAllStationsXML", success: { station in
                
                self.stationsCount = station.stationsList.count
                self.presenter!.stationListFetched(list: station.stationsList)

            }, failure: { error in
                
                print("Request failed:\(String(describing: error?.localizedDescription))")
                
            })
            
        } else {
            self.presenter!.showNoInterNetAvailabilityMessage()
        }
    }

    func fetchTrainsFromSource(sourceCode: String, destinationCode: String) {
        _sourceStationCode = sourceCode
        _destinationStationCode = destinationCode
        let urlString = "http://api.irishrail.ie/realtime/realtime.asmx/getStationDataByCodeXML?StationCode=\(sourceCode)"
        if Reach().isNetworkReachable() {
            
            networkRequestHandler.getEntity(entityType: StationData.self, urlString: urlString, success: { stationData in
                self.availableTrainsCount = stationData.trainsList.count
                    self.proceesTrainListforDestinationCheck(trainsList: stationData.trainsList)
                
            }, failure: { error in
                
                print("Request failed:\(String(describing: error?.localizedDescription))")
                
                self.presenter!.showNoTrainAvailbilityFromSource()
            })
        
        } else {
            self.presenter!.showNoInterNetAvailabilityMessage()
        }
    }
    
    private func proceesTrainListforDestinationCheck(trainsList: [StationTrain]) {
        var _trainsList = trainsList
        let today = Date()
        let group = DispatchGroup()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: today)
        
        for index  in 0...trainsList.count-1 {
            group.enter()
            let _urlString = "http://api.irishrail.ie/realtime/realtime.asmx/getTrainMovementsXML?TrainId=\(trainsList[index].trainCode)&TrainDate=\(dateString)"
            if Reach().isNetworkReachable() {
                
                networkRequestHandler.getEntity(entityType: TrainMovementsData.self, urlString: _urlString, success: { trainMovements in
                    
                    let _movements = trainMovements.trainMovements
                        let sourceIndex = _movements.firstIndex(where: {$0.locationCode.caseInsensitiveCompare(self._sourceStationCode) == .orderedSame})
                        let destinationIndex = _movements.firstIndex(where: {$0.locationCode.caseInsensitiveCompare(self._destinationStationCode) == .orderedSame})
                        let desiredStationMoment = _movements.filter{$0.locationCode.caseInsensitiveCompare(self._destinationStationCode) == .orderedSame}
                        let isDestinationAvailable = desiredStationMoment.count == 1

                        if isDestinationAvailable  && sourceIndex! < destinationIndex! {
                            _trainsList[index].destinationDetails = desiredStationMoment.first
                        }
                    
                    group.leave()

                }, failure: { error in
                    
                    print("Request failed:\(String(describing: error))")
                    
                    group.leave()

                })

            } else {
                self.presenter!.showNoInterNetAvailabilityMessage()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            let sourceToDestinationTrains = _trainsList.filter{$0.destinationDetails != nil}
            self.fetchedTrainsCount = sourceToDestinationTrains.count
            self.presenter!.fetchedTrainsList(trainsList: _trainsList)
        }
    }
}
