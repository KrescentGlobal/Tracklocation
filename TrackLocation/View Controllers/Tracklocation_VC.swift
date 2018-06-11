//
//  Tracklocation_VC.swift
//  TrackLocation
//
//  Created by Krescent Global on 29/05/18.
//  Copyright © 2018 Krescent Global. All rights reserved.
//

import UIKit
import GoogleMaps
import PubNub
import FTIndicator

class Tracklocation_VC: UIViewController  , PNObjectEventListener , GMSMapViewDelegate {

    //MARK:- Outlets
    @IBOutlet weak var mapView: GMSMapView!
    
    
    //MARK:- Variables
    var friendName:String = ""
    var userName:String = ""
    var client: PubNub!
    private var path = GMSMutablePath()
    private var polyline = GMSPolyline()
    private var currentPositionMarker = GMSMarker()
    private var isFirstMessage = true
    private var locations = [CLLocation]()
    var geotification:Geotification!
    
    
    
    //MARK:- UIView life-cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize and configure PubNub client instance
        let configuration = PNConfiguration(publishKey: "pub-c-7f6fe50f-7ccd-4947-ac9a-9ce08b787cd3", subscribeKey: "sub-c-3c4ad716-623a-11e8-a1da-326bcdd3c500")
        configuration.uuid = self.userName
        self.client = PubNub.clientWithConfiguration(configuration)
        self.mapView.delegate = self
        
        self.client.subscribeToChannels([self.friendName , "Geofence"], withPresence: true)
        self.client.addListener(self)
        
        if self.geotification != nil {
            self.add(geotification: geotification)
        }
        
        FTIndicator.showToastMessage("Tracking Started!")
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.client.unsubscribeFromChannels([self.friendName], withPresence: false)
    }
    
    
    func add(geotification: Geotification) {
        
        self.mapView.clear()
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
                    geotification.icon = nil
                    geotification.map = self.mapView
                }
            }
            else {
                geotification.position = geotification.coordinate
                geotification.title = ""
                geotification.snippet = ""
                geotification.icon = nil
                geotification.map = self.mapView
            }
        }, failure: { (error) in
            
            geotification.position = geotification.coordinate
            geotification.title = ""
            geotification.snippet = ""
            geotification.icon = nil
            geotification.map = self.mapView
            print(error.localizedDescription)
        })
        
        
        let circleCenter : CLLocationCoordinate2D  = geotification.coordinate
        let circ = GMSCircle(position: circleCenter, radius: geotification.radius)
        circ.fillColor = UIColor(red: 0.0, green: 0.7, blue: 0, alpha: 0.1)
        circ.strokeColor = UIColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 0.5)
        circ.strokeWidth = 2.5;
        circ.map = self.mapView;
        
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude , longitude: coordinate.longitude , zoom: 15.0)
        self.mapView.camera = camera
        
    }
    
    //MARK:- UIButton Action
    
    @IBAction func barBtn_Stop_action(_ sender: UIBarButtonItem) {
        self.client.unsubscribeFromChannels([self.friendName], withPresence: false)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    //MARK:- Pubnub Client Delegates
    // Handle new message from one of channels on which client has been subscribed.
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        
        //  if client_uuid == self.friendName {
        
        // Extract content from received message
        print(message.data.channel)
        
        if (message.data.channel == "Geofence"){
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
                    FTIndicator.showInfo(withMessage: "User goes out from your geofence region. you are unable to track him now")
                    UserDefaults.standard.set(false , forKey: "isEligibleForTracking")
                    self.navigationController?.popViewController(animated: true)
                default:
                    UserDefaults.standard.set(false , forKey: "isEligibleForTracking")
                }
            }
        }
        else {
            
            let receivedMessage = message.data.message as! [NSString : Double]
            let lng : CLLocationDegrees! = receivedMessage["lng"]
            let lat : CLLocationDegrees! = receivedMessage["lat"]
            let alt : CLLocationDegrees! = receivedMessage["alt"]
            
            
            let newLocation2D = CLLocationCoordinate2DMake(lat, lng)
            let newLocation = CLLocation(coordinate: newLocation2D, altitude: alt, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp:Date())
            
            if (UserDefaults.standard.bool(forKey: "isEligibleForTracking")) {
            
            self.locations.append(newLocation)

            // Initilize the polyline
            if (self.isFirstMessage) {
                self.initializePolylineAnnotation()
                self.isFirstMessage = false
            }
            // Drawing the line
            self.updateOverlay(currentPosition: newLocation)
            // Update the map frame
            //   self.updateMapFrame(newLocation: newLocation, zoom: 17.0)
            // Update Marker position
            self.updateCurrentPositionMarker(currentLocation: newLocation)
            }
        }
        
    }
    
    
    //MARK:-GMS Delegatse
    func initializePolylineAnnotation() {
        self.polyline.strokeColor = UIColor.blue
        self.polyline.strokeWidth = 5.0
        self.polyline.map = self.mapView
    }
    
    func updateOverlay(currentPosition: CLLocation) {
        self.path.add(currentPosition.coordinate)
        self.polyline.path = self.path
    }
    
    func updateMapFrame(newLocation: CLLocation, zoom: Float) {
        let camera = GMSCameraPosition.camera(withTarget: newLocation.coordinate, zoom: zoom)
        self.mapView.animate(to: camera)
    }
    
    func updateCurrentPositionMarker(currentLocation: CLLocation) {
        self.currentPositionMarker.map = nil
        self.currentPositionMarker = GMSMarker(position: currentLocation.coordinate)
        self.currentPositionMarker.icon = GMSMarker.markerImage(with: UIColor.cyan)
        self.currentPositionMarker.map = self.mapView
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
                    
                    FTIndicator.showToastMessage("Error in connecting User")
                    self.navigationController?.popViewController(animated: true)
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

   

}
