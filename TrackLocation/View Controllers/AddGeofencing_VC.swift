//
//  AddGeofencing_VC.swift
//  TrackLocation
//
//  Created by Krescent Global on 29/05/18.
//  Copyright © 2018 Krescent Global. All rights reserved.
//

import UIKit
import GoogleMaps
import FTIndicator

protocol addGeofencingDelegate {
    func passGeofencingData(coordinate: CLLocationCoordinate2D , lat: Double , long: Double , radius: Double , note: String , identifier:String , createdFor:String)
}

class AddGeofencing_VC: UIViewController , GMSMapViewDelegate {
    
    
    //MARK:- Outlets
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var txtField_radius: UITextField!
    @IBOutlet weak var txtField_note: UITextField!
    
    //MARK:- Variables
    private let locationManager = CLLocationManager()
    var delegate: addGeofencingDelegate?
    var userName:String = ""
    var friendName:String = ""
    
    //MARK:- UIView life-cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let u_name = UserDefaults.standard.value(forKey: "userName") {
            self.userName = u_name as! String
        }
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        self.mapView.delegate = self

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK:- UIButton Actions
    
    @IBAction func btnAdd_action(_ sender: UIButton) {
        
        let coordinate = mapView.projection.coordinate(for: mapView.center)
        
        if (txtField_radius.text!.count < 1) {
            FTIndicator.showToastMessage("Enter radius")
        }
        else {
            let radius = Double(txtField_radius.text!) ?? 0
            var note:String = ""
            note = txtField_note.text!
            
            delegate?.passGeofencingData(coordinate: coordinate, lat: coordinate.latitude , long: coordinate.longitude , radius: radius , note: note , identifier: self.userName ,createdFor: self.friendName)
            self.navigationController?.popViewController(animated: true)
        }
    
    }
    
    @IBAction func barBtn_CurrentLocation_action(_ sender: UIBarButtonItem) {
        
        if let myLoc = mapView?.myLocation{
            let camera = GMSCameraPosition.camera(withLatitude: (myLoc.coordinate.latitude),
                                                  longitude:(myLoc.coordinate.longitude), zoom: 15)
            mapView?.animate(to: camera)
        }
    }
    
}

// MARK: - CLLocationManagerDelegate
extension AddGeofencing_VC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse || status == .authorizedAlways  else {
            return
        }
        locationManager.startUpdatingLocation()
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else {
            return
        }
        
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        let newLocation = locations.last as! CLLocation
        print("current position: \(newLocation.coordinate.longitude) , \(newLocation.coordinate.latitude)")
        
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error.localizedDescription)")
        let errorAlert = UIAlertView(title: "Error", message: "Failed to Get Your Location", delegate: nil, cancelButtonTitle: "Ok")
        errorAlert.show()
    }
    
    
    
}
