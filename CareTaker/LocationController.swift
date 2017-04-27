//
//  LocationController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/20/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import Foundation
import CoreLocation
import FirebaseDatabase
import FirebaseAuth

class LocationController: NSObject, CLLocationManagerDelegate {
    static let userId = FIRAuth.auth()?.currentUser?.uid
    
    static var isBackground = false
    
    let locationManager = CLLocationManager()
    
    func setUpLocation() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        
        motionController.setUpMotion()
    }
    
    let motionController = MotionController()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let ref = FIRDatabase.database().reference()
        
        ref.child("users").child(LocationController.userId!).child("lastLocation").setValue([
            "latitude": locations.last?.coordinate.latitude,
            "longitude": locations.last?.coordinate.longitude
            ])
        
        if LocationController.isBackground {
            motionController.startMotion()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if(status != .authorizedAlways) {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func startLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopLocation() {
        locationManager.stopUpdatingLocation()
    }
}
