//
//  TrackLocation_Services.swift
//  TrackLocation
//
//  Created by Krescent Global on 28/05/18.
//  Copyright © 2018 Krescent Global. All rights reserved.
//

import UIKit
import Alamofire

class TrackLocation_Services: NSObject {
    
    
    let url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&key=API_KEY"

    
    class func getlocationDetails(url: String , success: @escaping ((AnyObject?)) -> Void , failure: @escaping ((NSError)->Void))
    {
        
        Alamofire.request(url , method: .get, encoding: JSONEncoding.default, headers: nil).responseJSON { (response:DataResponse<Any>) in
            
            switch(response.result) {
            case .success(_):
                if let data = response.result.value{
                    print(data)
                    success(data as (AnyObject?))
                    
                }
                break
                
            case .failure(_):
                print(response.result.description)
                failure(response.result.error as! NSError)
                break
            }
        }
    }
}





