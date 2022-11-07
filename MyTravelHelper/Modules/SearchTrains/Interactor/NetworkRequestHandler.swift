//
//  NetworkRequestHandler.swift
//  MyTravelHelper
//
//  Created by Apple on 06/11/22.
//  Copyright © 2022 Sample. All rights reserved.
//

import Foundation
import XMLParsing
class NetworkRequestHandler {
    
    func getEntity<T:Codable>(entityType: T.Type, urlString : String, success:@escaping (T) ->Void, failure:@escaping (Error?) ->Void){
        
        guard let url = URL(string: urlString) else {
            failure(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url){ (data,response,error) in
            if let error = error{
                failure(error)
            }
            guard let data = data, let _ = response else { return }
            
            do{
                let entity = try XMLDecoder().decode(entityType, from: data)
                success(entity)
            }catch{
                failure(error)
            }
            
            
        }
        task.resume()
    }
}
