//
//  activityStates.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/20/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import Foundation

enum ActivityStates: String {
    case active = "active"
    case away = "away"
    case loggedOut = "loggedOut"
    
    case inside = "Inside Geofence"
    case outside = "Outside Goefence"
    case noGeofence = "No Active Geofence"
}
