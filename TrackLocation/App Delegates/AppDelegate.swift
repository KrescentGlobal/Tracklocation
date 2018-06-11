//
//  AppDelegate.swift
//  TrackLocation
//
//  Created by Krescent Global on 28/05/18.
//  Copyright © 2018 Krescent Global. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import FirebaseAuth
import IQKeyboardManager
import CoreLocation
import FTIndicator


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate  {

    var window: UIWindow?
    
    let googleApiKey = "AIzaSyCK6AanmTeq3wudQhk28dwelF3tjbZ7Ksc"
    let locationManager = CLLocationManager()
   

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        IQKeyboardManager.shared().isEnabled = true
        UIApplication.shared.statusBarStyle = .lightContent
        FirebaseApp.configure()
        GMSServices.provideAPIKey(googleApiKey)
        
        
        if (UserDefaults.standard.bool(forKey: "isUserLogin")) {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "nav")
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func handleEvent(forRegion region: CLRegion! , isExit:Bool) {
        print("Geofence triggered!")
        
        if (isExit) {
            FTIndicator.showInfo(withMessage: "Exit Geofence area")
        }
        else {
            FTIndicator.showInfo(withMessage: "Enter Geofence area")
        }
    }
 

}

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region , isExit: false)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region , isExit: true)
        }
    }
}



