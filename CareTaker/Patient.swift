//
//  Patient.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/14/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import Foundation
import UIKit

class Patient {
    
    var firstName: String
    var lastName: String
    var UID: String
    var email: String
    var phone: String
    var imageUrl: String?
    var image: UIImage?
    var status: String?
    
    init(firstName: String, lastName: String, email: String, phone: String, imageUrl: String?, image: UIImage?, UID: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.UID = UID
        self.email = email
        self.phone = phone
        self.image = image
        self.imageUrl = imageUrl
    }
}
