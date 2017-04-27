//
//  MotionController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/20/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CoreMotion
import FirebaseAuth

class MotionController {
    
    // updates per sec
    static let FREQUENCY = 3
    
    var userId : String?
    
    var lastMotionState: ActivityStates = .away
    var lastMotion = (0.0,0.0,0.0)
    
    let motionManager = CMMotionManager()
    
    func setUpMotion() {
        userId = FIRAuth.auth()?.currentUser?.uid
        
        motionManager.accelerometerUpdateInterval = 1.0/Double(MotionController.FREQUENCY)
    }
    
    func stopMotion() {
        motionManager.stopAccelerometerUpdates()
    }
    
    // MARK: - Background Motion
    
    func startMotion() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: { data, error in
            guard error == nil else { return }
            
            guard let x = data?.acceleration.x, let y = data?.acceleration.y, let z = data?.acceleration.z else { return }
            
            let dx = abs(x - self.lastMotion.0)
            let dy = abs(y - self.lastMotion.1)
            let dz = abs(z - self.lastMotion.2)
            
            self.lastMotion = (x,y,z)
            
            if dx <= 0.007 && dy <= 0.007 && dz <= 0.007 {
                self.setDatabaseState(.away)
            } else if abs(x) > 0 || abs(y) > 0 || abs(z) > 0 {
                self.setDatabaseState(.active)
            }
            
            DispatchQueue.main.async {
                self.stopMotion()
            }
            
        })
        
    }
    
    // MARK: - Active Motion
    
    var awayCounter = 0
    
    func startActiveMotion() {
        motionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: { data, error in
            guard error == nil else { return }
            
            guard let x = data?.acceleration.x, let y = data?.acceleration.y, let z = data?.acceleration.z else { return }
            
            let dx = abs(x - self.lastMotion.0)
            let dy = abs(y - self.lastMotion.1)
            let dz = abs(z - self.lastMotion.2)
            
            self.lastMotion = (x,y,z)
            
            if dx <= 0.009 && dy <= 0.009 && dz <= 0.009 {
                self.awayCounter = self.awayCounter + 1
                // 6 seconds
                if self.awayCounter == 6 * MotionController.FREQUENCY {
                    //reset counter
                    self.awayCounter = 0
                    self.setDatabaseState(.away)
                    
                    //reduce frequency of updates
                    self.motionManager.accelerometerUpdateInterval = 1.0/Double(MotionController.FREQUENCY) * 3.0
                }
            } else if abs(x) > 0 || abs(y) > 0 || abs(z) > 0 {
                // reset away counter
                self.awayCounter = 0
                
                self.setDatabaseState(.active)
                
                // put frequency back
                self.motionManager.accelerometerUpdateInterval = 1.0/Double(MotionController.FREQUENCY)
            }
            
        })
    }
    
    // MARK: - Update Firebase
    
    func setDatabaseState(_ state: ActivityStates) {
        if (lastMotionState != state) {
            
            let statusRef = FIRDatabase.database().reference().child("users").child(userId!).child("status")
            statusRef.setValue(state.rawValue)
            // also set time last active
            if state == ActivityStates.away || state == ActivityStates.loggedOut {
                let timeRef = FIRDatabase.database().reference().child("users").child(userId!).child("timeLastActive")
                timeRef.setValue(Int(Date().timeIntervalSince1970))
            }
            lastMotionState = state
        }
    }
    
}
