//
//  TravelLocationPointAnnotation.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/11/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import Foundation
import MapKit

class TravelLocationPointAnnotation: MKPointAnnotation {

    var pin: Pin!

    init(pin: Pin) {
        super.init()
        self.pin = pin
    }

}
