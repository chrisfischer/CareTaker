//
//  PatientMenuViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/8/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

let DELAY_DURATION = 3.0

class PatientMenuViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let userRef = FIRDatabase.database().reference().child("users").child((FIRAuth.auth()?.currentUser?.uid)!)
    var hasCareTaker: Bool = false
    var ctPhone: String?
    
    let motionController = MotionController()
    let locationController = LocationController()
    
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userId = FIRAuth.auth()?.currentUser?.uid
        
        // set up nav bar colors
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.barStyle = .default
        navigationBarAppearace.backgroundColor = .white
        navigationBarAppearace.barTintColor = .white
        navigationBarAppearace.tintColor = Colors.blue
        navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.black]
        navigationBarAppearace.isTranslucent = false
        UIApplication.shared.statusBarStyle = .default
        
        
        setUpGesture()
        locationController.setUpLocation()
        locationController.startLocation()
        
        motionController.setUpMotion()
        motionController.startActiveMotion()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(toLogOut), name: NSNotification.Name(rawValue: loggedOutPatientKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(removedCaretaker), name: NSNotification.Name(rawValue: removedCaretakerKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(addedCaretaker), name: NSNotification.Name(rawValue: hasCaretakerKey), object: nil)
        
        // get caretaker's phone number
        userRef.child("careTakers").observeSingleEvent(of: .value, with: { snapshot in
            if (snapshot.value != nil && snapshot.exists()) {
                let careTakerDict = snapshot.value as! [String: String]
                if !careTakerDict.isEmpty {
                    // has caretaker
                    self.hasCareTaker = true
                    let ctUID = Array((snapshot.value as! [String: String]).values).first
                    if let ctUID = ctUID {
                        let ref = FIRDatabase.database().reference().child("users").child(ctUID).child("info").child("phone")
                        ref.observeSingleEvent(of: .value, with: { snapshot in
                            self.ctPhone = snapshot.value as? String
                        })
                    }
                    return
                }
                // no caretaker
                self.hasCareTaker = false
            }
        })
        
    }
    
    func toLogOut() {
        motionController.stopMotion()
        locationController.stopLocation()
        FIRDatabase.database().reference().child("users").child(userId!).child("status").setValue(ActivityStates.loggedOut.rawValue)
    }
    
    func removedCaretaker() {
        hasCareTaker = false
    }
    
    func addedCaretaker() {
        hasCareTaker = true
    }
    
    
    // MARK: - Emergency Call Buttons
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var emergencyView: UILabel!
    @IBOutlet weak var callCareTakerView: UILabel!
    
    var emergencyTimeIsUp = false
    var isEmergencyPressed = false
    var currentEmergencyPressId = 0
    var emergencyCircleLayer: CircleLayer?
    
    var careTakerTimeIsUp = false
    var isCareTakerPressed = false
    var currentCareTakerPressId = 0
    var careTakerCircleLayer: CircleLayer?
    
    func setUpGesture() {
        let emergencyLongPress = UILongPressGestureRecognizer(target: self, action: #selector(emergencyLongPress(recognizer:)))
        emergencyLongPress.delegate = self
        emergencyLongPress.minimumPressDuration = 0
        
        let careTakerLongPress = UILongPressGestureRecognizer(target: self, action: #selector(careTakerLongPress(recognizer:)))
        careTakerLongPress.delegate = self
        careTakerLongPress.minimumPressDuration = 0
        
        emergencyView.isUserInteractionEnabled = true
        emergencyView.backgroundColor = UIColor.clear
        emergencyView.layer.backgroundColor = Colors.red.cgColor
        emergencyView.addGestureRecognizer(emergencyLongPress)
        
        callCareTakerView.isUserInteractionEnabled = true
        callCareTakerView.backgroundColor = UIColor.clear
        callCareTakerView.layer.backgroundColor = Colors.blue.cgColor
        callCareTakerView.addGestureRecognizer(careTakerLongPress)
        
    }
    
    func emergencyLongPress(recognizer: UILongPressGestureRecognizer) {
        
        if recognizer.state == .began {
            // on begining of press
            isEmergencyPressed = true
            emergencyTimeIsUp = false
            delay(delay: DELAY_DURATION, closure: makeEmergencyTimerUp(id: currentEmergencyPressId + 1))
            currentEmergencyPressId = currentEmergencyPressId + 1
            
            // change caretaker label
            self.callCareTakerView.layer.backgroundColor = Colors.lightGray.cgColor
            self.callCareTakerView.text = "Hold to place call"
            
            UIView.animate(withDuration: 0.2) {
                self.emergencyView.layer.backgroundColor = UIColor.white.cgColor
                self.emergencyView.textColor = Colors.red
            }
            
            emergencyCircleLayer = CircleLayer(center: recognizer.location(in: emergencyView), parentFrame: emergencyView.frame, color: Colors.red)
            emergencyView.layer.addSublayer((emergencyCircleLayer?.circleLayer)!)
            emergencyCircleLayer?.animateExpand()
            
        } else if recognizer.state == .ended {
            isEmergencyPressed = false
            if !emergencyTimeIsUp {
                // press released early
                emergencyCircleLayer?.circleLayer?.removeAllAnimations()
                emergencyCircleLayer?.circleLayer?.removeFromSuperlayer()
                
                UIView.animate(withDuration: 0.2) {
                    // reset emergency label
                    self.emergencyView.layer.backgroundColor = Colors.red.cgColor
                    self.emergencyView.textColor = .white
                    
                    // reset caretaker label
                    self.callCareTakerView.layer.backgroundColor = Colors.blue.cgColor
                    self.callCareTakerView.text = "Call Caretaker"
                }
            }
        }
    }
    
    func makeEmergencyTimerUp(id: Int) -> () -> () {
        func timerUp() {
            if isEmergencyPressed && currentEmergencyPressId == id {
                // after timer is up
                emergencyTimeIsUp = true
                emergencyCircleLayer?.circleLayer?.removeFromSuperlayer()
                
                self.emergencyView.layer.backgroundColor = Colors.red.cgColor
                self.emergencyView.textColor = .white
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.emergencyView.layer.backgroundColor = UIColor.white.cgColor
                    self.emergencyView.textColor = Colors.red
                    
                    // reset caretaker label
                    self.callCareTakerView.layer.backgroundColor = Colors.blue.cgColor
                    self.callCareTakerView.text = "Call Caretaker"
                }, completion: { finished in
                    if finished {
                        UIView.animate(withDuration: 0.2) {
                            self.emergencyView.layer.backgroundColor = Colors.red.cgColor
                            self.emergencyView.textColor = .white
                        }
                    }
                })
                //showAlert(message: "An emergency call as been placed")
            }
        }
        return timerUp
        
    }
    
    func careTakerLongPress(recognizer: UILongPressGestureRecognizer) {
        
        if recognizer.state == .began {
            // on begining of press
            isCareTakerPressed = true
            careTakerTimeIsUp = false
            delay(delay: DELAY_DURATION, closure: makeCareTakerTimerUp(id: currentCareTakerPressId + 1))
            currentCareTakerPressId = currentCareTakerPressId + 1
            
            // change emergency label
            self.emergencyView.layer.backgroundColor = Colors.lightGray.cgColor
            self.emergencyView.text = "Hold to place call"
            
            UIView.animate(withDuration: 0.2) {
                self.callCareTakerView.layer.backgroundColor = UIColor.white.cgColor
                self.callCareTakerView.textColor = Colors.blue
            }
            
            careTakerCircleLayer = CircleLayer(center: recognizer.location(in: callCareTakerView), parentFrame: callCareTakerView.frame, color: Colors.blue)
            callCareTakerView.layer.addSublayer((careTakerCircleLayer?.circleLayer)!)
            careTakerCircleLayer?.animateExpand()
            
        } else if recognizer.state == .ended {
            isCareTakerPressed = false
            if !careTakerTimeIsUp {
                // press released early
                careTakerCircleLayer?.circleLayer?.removeAllAnimations()
                careTakerCircleLayer?.circleLayer?.removeFromSuperlayer()
                
                UIView.animate(withDuration: 0.2) {
                    // reset caretaker label
                    self.callCareTakerView.layer.backgroundColor = Colors.blue.cgColor
                    self.callCareTakerView.textColor = .white
                    
                    // reset emergency label
                    self.emergencyView.layer.backgroundColor = Colors.red.cgColor
                    self.emergencyView.text = "Emergency"
                }
            }
        }
    }
    
    func makeCareTakerTimerUp(id: Int) -> () -> () {
        func timerUp() {
            if isCareTakerPressed && currentCareTakerPressId == id {
                // after timer is up
                careTakerTimeIsUp = true
                careTakerCircleLayer?.circleLayer?.removeFromSuperlayer()
                
                self.callCareTakerView.layer.backgroundColor = Colors.blue.cgColor
                self.callCareTakerView.textColor = .white
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.callCareTakerView.layer.backgroundColor = UIColor.white.cgColor
                    self.callCareTakerView.textColor = Colors.blue
                    
                    // reset emergency label
                    self.emergencyView.layer.backgroundColor = Colors.red.cgColor
                    self.emergencyView.text = "Emergency"
                }, completion: { finished in
                    if finished {
                        UIView.animate(withDuration: 0.2) {
                            self.callCareTakerView.layer.backgroundColor = Colors.blue.cgColor
                            self.callCareTakerView.textColor = .white
                        }
                    }
                })
                if !hasCareTaker || ctPhone == nil {
                    showAlert()
                } else {
                    guard let number = URL(string: "telprompt://" + ctPhone!) else { return }
                    UIApplication.shared.open(number, options: [:], completionHandler: nil)
                }
            }
        }
        return timerUp
        
    }
    
    
    func delay(delay: Double, closure: @escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "No caretaker found!", message: "To add a caretaker, tap the info button in the top right.", preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
}
