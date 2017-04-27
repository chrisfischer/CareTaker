//
//  Patients.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/8/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import Foundation
import FirebaseStorage
import UIKit

class PatientDatabase {
    
    
    // MARK: - Confirmed Patients
    
    static var patientArr: [Patient] = [Patient]()
    
    static func getCount() -> Int {
        return patientArr.count
    }
    
    static func addPatient(patient: Patient) {
        if patientArr.isEmpty {
            patientArr.append(patient)
        } else {
            for index in 0...(patientArr.count - 1) {
                if patientArr[index].UID == patient.UID {
                    patientArr.remove(at: index)
                    patientArr.append(patient)
                    return
                }
            }
            patientArr.append(patient)
        }
    }
    
    static func updateStatus(uid: String, status: String) {
        for patient in patientArr {
            if patient.UID == uid {
                patient.status = status
                return
            }
        }
    }
    
    static func getProfilePhotos(closure: @escaping () -> Void) {
        for patient in patientArr {
            
            let imageUrl = patient.imageUrl
            
            if imageUrl == nil{
                continue
            }
            if patient.image == nil {
                let url = URL(string: imageUrl!)
                getImage(url: url!, closure: { data in
                    patient.image = UIImage(data: data!)
                    closure()
                })
            }
        }
    }
    
    static func getImage (url: URL, closure: @escaping (Data?) -> Void) {
        let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
        
        var dataTask: URLSessionDataTask?
        
        if dataTask != nil {
            dataTask?.cancel()
        }
        
        dataTask = defaultSession.dataTask(with: url, completionHandler: {
            data, response, error in
            if error != nil {
                
                print(error!.localizedDescription)
                closure(nil)
                
            } else if let httpResponse = response as? HTTPURLResponse {
                
                if httpResponse.statusCode == 200 {
                    
                    if let imageData = data {
                        closure(imageData)
                    }
                    
                }
            }
        })
        
        dataTask?.resume()
    }
    
    static func removeAllPatients() {
        patientArr.removeAll()
    }
    
    static func removePatient(uid: String) {
        if patientArr.count == 0 {
            return
        }
        for i in 0...patientArr.count-1 {
            let currPatient = patientArr[i]
            if currPatient.UID == uid {
                patientArr.remove(at: i)
                return
            }
        }
    }
    
    // MARK: - Pending Patients
    
    static var pendingPatientArr = [String]()
    
    static func removeAllPendingPatients() {
        pendingPatientArr.removeAll()
    }
    
    static func removePending(email: String) {
        if pendingPatientArr.isEmpty {
            return
        }
        for i in 0...(pendingPatientArr.count - 1) {
            if pendingPatientArr[i] == email {
                pendingPatientArr.remove(at: i)
                return
            }
        }
    }
    
    static func getPendingCount() -> Int {
        return pendingPatientArr.count
    }
    
    
    // MARK: - Email validation
    
    // replaces '.' with ',' so it can be stored in Firebase
    static func emailRegex(email: String) -> String {
        return email.replacingOccurrences(of: ".", with: ",").lowercased()
    }
    
    // checks if is valid email
    static func isValidEmail(email: String) -> Bool {
        
        // from http://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
}
