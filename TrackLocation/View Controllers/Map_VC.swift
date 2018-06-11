//
//  Map_VC.swift
//  TrackLocation
//
//  Created by Krescent Global on 28/05/18.
//  Copyright © 2018 Krescent Global. All rights reserved.
//

import UIKit
import GoogleMaps
import PubNub
import FTIndicator
import Firebase
import FirebaseDatabase


class Map_VC: UIViewController  , GMSMapViewDelegate , addGeofencingDelegate , PNObjectEventListener {
   
   
    //MARK:- Outlets
    @IBOutlet weak var mapVw: GMSMapView!
    
    //MARK:- Variables
    private let locationManager = CLLocationManager()
    var client: PubNub!
    var userName:String = ""
    var friendName:String = ""
    var geotifications: [Geotification] = []
    var isFirstTimeViewLoaded:Bool = true
    
    //firebase
    var ref: DatabaseReference!
    
    //https://tracklocation-205504.firebaseio.com/GeofencingData
    
    //MARK:- UIView life-cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let u_name = UserDefaults.standard.value(forKey: "userName") {
            self.userName = u_name as! String
        }
        
        ref = Database.database().reference().child("Geofence");
        fetchData_DB()
        isFirstTimeViewLoaded = true
        
        // Initialize and configure PubNub client instance
        let configuration = PNConfiguration(publishKey: "pub-c-7f6fe50f-7ccd-4947-ac9a-9ce08b787cd3", subscribeKey: "sub-c-3c4ad716-623a-11e8-a1da-326bcdd3c500")
        
        //self.navigationItem.title = self.userName
        
       
        configuration.uuid = self.userName
        self.client = PubNub.clientWithConfiguration(configuration)
        
        self.client.subscribeToChannels(["Geofence"], withPresence: true)
        self.client.addListener(self)
        
        locationManager.delegate = self
        //locationManager.requestAlwaysAuthorization()
        
        self.mapVw.delegate = self
        
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 1. status is not determined
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
            // 2. authorization were denied
        else if CLLocationManager.authorizationStatus() == .denied {
            let alertController = UIAlertController(title: NSLocalizedString("", comment: ""), message: NSLocalizedString("Location services were previously denied. Please enable location services for this app in Settings.", comment: ""), preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .default) { (UIAlertAction) in
                UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString)! as URL)
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(settingsAction)
            self.present(alertController, animated: true, completion: nil)
           // FTIndicator.showInfo(withMessage: "Location services were previously denied. Please enable location services for this app in Settings.")
        }
            // 3. we do have authorization
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK:- Firebase Bussiness Methods
    func addGeofence_DB(geotification: Geotification){
        
        let key = ref.childByAutoId().key
        
        let geofence = ["latitude":geotification.coordinate.latitude as Double,
                        "longitude": geotification.coordinate.longitude as Double,
                        "note": geotification.note as String ,
                        "radius": geotification.radius as Double ,
                        "identifier": geotification.identifier as String,
                        "createdFor": geotification.createdFor as String] as [String : Any]
        
        //adding the artist inside the generated unique key
        ref.child(key).setValue(geofence)
    }
    
    func fetchData_DB(){
        
        ref.observe(DataEventType.value, with: { (snapshot) in
            
            if snapshot.childrenCount > 0 {
                
                self.geotifications.removeAll()
                
                let arrAllSnapShots = snapshot.children.allObjects as! [DataSnapshot]
                
                //getting values
                let Object = arrAllSnapShots[arrAllSnapShots.count - 1].value as? [String: AnyObject]
                
                let latitude  = Object?["latitude"]
                let longitude  = Object?["longitude"]
                let note = Object?["note"]
                let identifier  = Object?["identifier"]
                let createdFor  = Object?["createdFor"]
                let radius  = Object?["radius"]
                
                let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude as! Double , longitude: longitude as! Double)
                let geotification = Geotification(coordinate: coordinate, radius: radius as! Double, identifier: identifier as! String, note: note as! String, createdFor: createdFor as! String)
                
                //appending it to list
                self.geotifications.append(geotification)
                
                if(geotification.createdFor.caseInsensitiveCompare(self.userName) == ComparisonResult.orderedSame){
                    print("voila")
                    self.add(geotification: geotification)
                }
            }
        })
    }
    
    //MARK:- Delegates
    func passGeofencingData(coordinate: CLLocationCoordinate2D, lat: Double, long: Double, radius: Double, note: String, identifier: String , createdFor: String) {
        print("coordinates - \(coordinate) , lat- \(lat), long - \(long) , radius - \(radius) , note - \(note) , identifier - \(identifier)")
        
        self.mapVw.clear()
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let geotification = Geotification(coordinate: coordinate, radius: radius , identifier: identifier, note: note , createdFor: createdFor)
        
        FTIndicator.showSuccess(withMessage: "Geotification Added")
        
      //  geotifications.removeAll()
      //  geotifications.append(geotification)
        //add(geotification: geotification)
       // startMonitoring(geotification: geotification)
        addGeofence_DB(geotification: geotification)
    }
    
    
    func startMonitoring(geotification: Geotification) {
        
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            FTIndicator.showError(withMessage: "Geofencing is not supported on this device!")
            return
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            
            FTIndicator.showInfo(withMessage: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
        }
        
        let region = self.region(withGeotification: geotification)
        locationManager.startMonitoring(for: region)
        locationManager.requestState(for: region)
      //  locationManager.startUpdatingLocation()
    }
    
    
    func stopMonitoring(geotification: Geotification) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geotification.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func add(geotification: Geotification) {
        
        self.mapVw.clear()
        let coordinate:CLLocationCoordinate2D = geotification.coordinate
        
        let url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(coordinate.latitude),\(coordinate.longitude)&key=AIzaSyCK6AanmTeq3wudQhk28dwelF3tjbZ7Ksc"
        
        print(url)
        
        TrackLocation_Services.getlocationDetails(url: url , success: { (response) in
            if let json = response as? NSDictionary {
                
                print(json)
                
                if let results = json.object(forKey: "results") as? NSArray {
                    let dic = results.object(at: 0) as? NSDictionary
                    let address = dic?.object(forKey:"formatted_address") as? String
                    print(address!)
                    
                    geotification.position = geotification.coordinate
                    geotification.title = ""
                    geotification.snippet = address!
                    geotification.icon = UIImage(named: "point.png")
                    geotification.map = self.mapVw
                    self.startMonitoring(geotification: geotification)
                }
            }
            else {
                geotification.position = geotification.coordinate
                geotification.title = ""
                geotification.snippet = ""
                geotification.icon = UIImage(named: "point.png")
                geotification.map = self.mapVw
                self.startMonitoring(geotification: geotification)
            }
        }, failure: { (error) in
            
            geotification.position = geotification.coordinate
            geotification.title = ""
            geotification.snippet = ""
            geotification.icon = UIImage(named: "point.png")
            geotification.map = self.mapVw
            self.startMonitoring(geotification: geotification)
            print(error.localizedDescription)
        })
        
        
        let circleCenter : CLLocationCoordinate2D  = geotification.coordinate
        let circ = GMSCircle(position: circleCenter, radius: geotification.radius)
        circ.fillColor = UIColor(red: 0.0, green: 0.7, blue: 0, alpha: 0.1)
        circ.strokeColor = UIColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 0.5)
        circ.strokeWidth = 2.5;
        circ.map = self.mapVw;
        
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude , longitude: coordinate.longitude , zoom: 15.0)
        self.mapVw.camera = camera
        
        
        
    }
    
    func region(withGeotification geotification: Geotification) -> CLCircularRegion {
        
        let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
        
        region.notifyOnEntry = true
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    
    //MARK:- UIButton Actions
    @IBAction func btn_trackLocation_action(_ sender: UIBarButtonItem) {
        
        if geotifications.count == 0{
            
            FTIndicator.showError(withMessage: "First create a geofence region")
        }
       else if geotifications.count > 0 {
            
            if(self.geotifications[0].identifier.caseInsensitiveCompare(self.userName) == ComparisonResult.orderedSame){
                
                if UserDefaults.standard.value(forKey: "friendName") != nil {
                    
                    self.friendName = UserDefaults.standard.value(forKey: "friendName") as! String
                    
                    if !UserDefaults.standard.bool(forKey: "isEligibleForTracking") {
                        FTIndicator.showError(withMessage: "User is outside your geofence area")
                    }
                    else {
                        self.performSegue(withIdentifier: "trackLocation", sender: self)
                    }
                }
            }
            else {
                FTIndicator.showError(withMessage: "First create a geofence region")
            }
        }
    }
    
    
    func checkUserNameExist(UserName: String, completion: @escaping(Bool) -> Void) {
        
        Auth.auth().fetchProviders(forEmail: UserName, completion: { (providers, error) in
            
            if providers == nil {
                completion(false)
                // user doesn't exist
            } else {
                completion(true)
                // user does exist
            }
        })
    }
    
    @IBAction func barBtn_addGeofencing_action(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "", message: "Enter the name of the user you want to track.", preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Submit", style: .default) { (alertAction) in
            let textField = alert.textFields![0] as UITextField
            
            self.friendName = textField.text!
            
            if (self.friendName.count < 1) {
                FTIndicator.showToastMessage("Enter user name")
            }
            else {
                
                
                self.friendName = self.friendName.trimmingCharacters(in: .whitespaces)
                
                self.checkUserNameExist(UserName: self.friendName + "@gmail.com" ) { isExist in
                    if isExist {
                        print("Username exist")
                        
                        UserDefaults.standard.set( self.friendName , forKey: "friendName")
                        self.performSegue(withIdentifier: "addGeofencing", sender: self)
                        let alert = UIAlertController(title: "", message: "Select an area on the map to create a geofence with radius field given below.", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        
                        
//                        if !UserDefaults.standard.bool(forKey: "isEligibleForTracking") {
//                            FTIndicator.showError(withMessage: "User is outside your geofence area")
//                        }
//                        else {
//                            self.performSegue(withIdentifier: "trackLocation", sender: self)
//                        }
                        
                    }
                    else {
                        print("Username not exist")
                        FTIndicator.showError(withMessage: "User not found!")
                    }
                }
            }
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Enter user name"
        }
        
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler:{ (UIAlertAction)in
            print("User click cancel button")
            
        }))
        self.present(alert, animated:true, completion: nil)
   
    }
    
    //MARK:- UINavigation Method
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "trackLocation" {
            
            let trackLocation_VC = segue.destination as! Tracklocation_VC
            trackLocation_VC.friendName = self.friendName
            trackLocation_VC.userName = self.userName
            trackLocation_VC.geotification = self.geotifications[0]
            
        }
        
        if segue.identifier == "addGeofencing" {
            
            let AddGeofencing_VC = segue.destination as! AddGeofencing_VC
            AddGeofencing_VC.delegate = self
            AddGeofencing_VC.friendName = self.friendName
            
        }
    }
    
    
    func handleEvent(forRegion region: CLRegion! , isExit:Bool) {
        print("Geofence triggered!")
        
        if (isExit) {
            FTIndicator.showInfo(withMessage: "Exit Geofence area - VC")
        }
        else {
            FTIndicator.showInfo(withMessage: "Enter Geofence area - VC")
        }
    }
}



// MARK: - CLLocationManagerDelegate
extension Map_VC: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse || status == .authorizedAlways  else {
            return
        }
        locationManager.startUpdatingLocation()

        mapVw.isMyLocationEnabled = true
        mapVw.settings.myLocationButton = true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let location = locations.first else {
            return
        }

        if (isFirstTimeViewLoaded) {
            isFirstTimeViewLoaded = false
            mapVw.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        }

        let newLocation = locations.last as! CLLocation
        print("current position: \(newLocation.coordinate.longitude) , \(newLocation.coordinate.latitude)")
        
        let message = "{\"lat\":\(newLocation.coordinate.latitude),\"lng\":\(newLocation.coordinate.longitude), \"alt\": \(newLocation.altitude)}"
        
        print("&&&&&&&&&&&&&&\(self.userName)__-______-____________")

        self.client.publish(message , toChannel: self.userName ,
                            compressed: false, withCompletion: { (status) in

                                if !status.isError {

                                    print("msg sent successfully!")
                                    // Message successfully published to specified channel.
                                }
                                else{

                                     print("ERROR")
                                }
        })

    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error.localizedDescription)")
        let errorAlert = UIAlertView(title: "Error", message: "Failed to Get Your Location", delegate: nil, cancelButtonTitle: "Ok")
        errorAlert.show()
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
//    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
//        if region is CLCircularRegion {
//
//            UserDefaults.standard.set(true , forKey: "isEligibleForTracking")
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
//        if region is CLCircularRegion {
//            UserDefaults.standard.set(false , forKey: "isEligibleForTracking")
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        
        print("start")
    }
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        var str_state:String = ""
        
        switch state {
        case .unknown:
            str_state = "unknown"
            print("unknown : \(region.identifier)")
            UserDefaults.standard.set(false , forKey: "isEligibleForTracking")
        case .inside:
            str_state = "inside"
            print("inside : \(region.identifier)")
            UserDefaults.standard.set(true , forKey: "isEligibleForTracking")
        case .outside:
            str_state = "outside"
            print("outside : \(region.identifier)")
            UserDefaults.standard.set(false , forKey: "isEligibleForTracking")
        default:
            str_state = "default"
            print("default")
            UserDefaults.standard.set(false , forKey: "isEligibleForTracking")
        }
        
        
        print(str_state)
        
        let msg:NSDictionary = ["geofenceState": str_state ,
                                "geofenceCreatedBy"    : geotifications[0].identifier ]
        
        print(msg)
        
        self.client.publish(msg , toChannel: "Geofence" ,
                            compressed: false, withCompletion: { (status) in
                                
                                if !status.isError {
                                    
                                    print("msg sent successfully!")
                                    // Message successfully published to specified channel.
                                }
                                else{
                                    
                                    print("ERROR")
                                }
        })
    }
    
    // New presence event handling.
    func client(_ client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        
        // Handle presence event event.data.presenceEvent (one of: join, leave, timeout, state-change).
        if event.data.channel != event.data.subscription {
            
            // Presence event has been received on channel group stored in event.data.subscription.
        }
        else {
            
            // Presence event has been received on channel stored in event.data.channel.
        }
        
        if event.data.presenceEvent != "state-change" {
            
            print("\(event.data.presence.uuid) \"\(event.data.presenceEvent)'ed\"\n" +
                "at: \(event.data.presence.timetoken) on \(event.data.channel) " +
                "(Occupancy: \(event.data.presence.occupancy))");
        }
        else {
            
            print("\(event.data.presence.uuid) changed state at: " +
                "\(event.data.presence.timetoken) on \(event.data.channel) to:\n" +
                "\(event.data.presence.state)");
        }
    }
    
    // Handle subscription status change.
    func client(_ client: PubNub, didReceive status: PNStatus) {
        
        if status.operation == .subscribeOperation {
            
            // Check whether received information about successful subscription or restore.
            if status.category == .PNConnectedCategory || status.category == .PNReconnectedCategory {
                
                let subscribeStatus: PNSubscribeStatus = status as! PNSubscribeStatus
                if subscribeStatus.category == .PNConnectedCategory {
                    
                    //  if (!UserDefaults.standard.bool(forKey: "isEligibleForTracking")) {
                    
                    
                    //  }
                    
                }
                else {
                    
                   // FTIndicator.showToastMessage("Error in connecting User")
                   // self.navigationController?.popViewController(animated: true)
                    /**
                     This usually occurs if subscribe temporarily fails but reconnects. This means there was
                     an error but there is no longer any issue.
                     */
                }
            }
            else if status.category == .PNUnexpectedDisconnectCategory {
                
                /**
                 This is usually an issue with the internet connection, this is an error, handle
                 appropriately retry will be called automatically.
                 */
            }
                // Looks like some kind of issues happened while client tried to subscribe or disconnected from
                // network.
            else {
                
                let errorStatus: PNErrorStatus = status as! PNErrorStatus
                if errorStatus.category == .PNAccessDeniedCategory {
                    
                    /**
                     This means that PAM does allow this client to subscribe to this channel and channel group
                     configuration. This is another explicit error.
                     */
                }
                else {
                    
                    /**
                     More errors can be directly specified by creating explicit cases for other error categories
                     of `PNStatusCategory` such as: `PNDecryptionErrorCategory`,
                     `PNMalformedFilterExpressionCategory`, `PNMalformedResponseCategory`, `PNTimeoutCategory`
                     or `PNNetworkIssuesCategory`
                     */
                }
            }
        }
    }

    
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        
        // Extract content from received message
        let receivedMessage = message.data.message as! NSDictionary
        
        let createdBy:String = receivedMessage.value(forKey: "geofenceCreatedBy") as! String
        let state:String = receivedMessage.value(forKey: "geofenceState") as! String
        
        if (createdBy == self.userName) {
            
             print(state)
            
            switch state {
            case "unknown":
                UserDefaults.standard.set(false , forKey: "isEligibleForTracking")
            case "inside":
                UserDefaults.standard.set(true , forKey: "isEligibleForTracking")
            case "outside":
                UserDefaults.standard.set(false , forKey: "isEligibleForTracking")
            default:
                UserDefaults.standard.set(false , forKey: "isEligibleForTracking")
            }
        }
    }


}



