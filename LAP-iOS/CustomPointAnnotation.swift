//
//  CustomPointAnnotation.swift
//  LAP-iOS
//
//  Created by Hugo Sanchez on 2/1/16.
//  Copyright © 2016 Kevin Argumedo. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

class CustomPointAnnotation: MKPointAnnotation {
    var imageName: String!;
    var treeID: Int!;
    var specieID: Int!;
    var info: String!;
    var annotationList: [CustomPointAnnotation] = [];
    var isHead: Bool!;
    var location: CLLocationCoordinate2D!;
    var color: UIColor!;
}