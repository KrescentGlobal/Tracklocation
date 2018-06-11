//
//  CreateUser_VC.swift
//  TrackLocation
//
//  Created by Krescent Global on 28/05/18.
//  Copyright © 2018 Krescent Global. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FTIndicator
import GoogleMaps

class CreateUser_VC: UIViewController {

    //MARK:- Outlets
    @IBOutlet weak var txtField_userName: UITextField!
    
    let locationManager = CLLocationManager()
    
    //MARK:- UIView life-cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.txtField_userName.text = ""
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
        }
            // 3. we do have authorization
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            //locationManager.startUpdatingLocation()
        }
    }
    
    
    
    
    @IBAction func btn_Done_action(_ sender: UIButton) {
        
        if txtField_userName.text == "" {
            
            FTIndicator.showToastMessage("Please enter user name")
            
        } else {
            
            var userName:String = self.txtField_userName.text!
            userName = userName.trimmingCharacters(in: .whitespaces)
            
            print(userName)
            
            Auth.auth().createUser(withEmail: userName + "@gmail.com", password: "123456789") { (user, error) in
                
                if error == nil {
                    
                    FTIndicator.showToastMessage("User created successfully!")
                    UserDefaults.standard.set(true , forKey: "isUserLogin")
                    self.performSegue(withIdentifier: "map", sender: self)
                    
                    UserDefaults.standard.setValue(userName , forKey: "userName")
                } else {
                    FTIndicator.showError(withMessage: error?.localizedDescription)
                }
            }
        }
        
    }
    
    
   
}
