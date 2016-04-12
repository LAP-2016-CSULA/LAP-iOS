//
//  Observation.swift
//  LAP-iOS
//
//  Created by Hugo Sanchez on 3/15/16.
//  Copyright © 2016 Kevin Argumedo. All rights reserved.
//

import Foundation;
import UIKit
import MapKit
import CoreLocation
import Heimdallr
import Alamofire

class Observation{
//    Variables passed from MapViewController
    var user: JSON = [:];
    var ats: OAuthAccessTokenKeychainStore;
    var heimdallr: Heimdallr;
    var link = "";
    var treeLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0);
    var isUpdate = false;
    var treeList: CustomPointAnnotation!;
    var treeSelected = [JSON]();
    var specie: JSON = [:];
    var species = [JSON]();
    var viewOnly = false;
    
    init(ats: OAuthAccessTokenKeychainStore, heimdallr: Heimdallr) {
        self.ats = ats;
        self.heimdallr = heimdallr;
    }
    
    func setTreeLocation(treeLocation: CLLocationCoordinate2D){
        self.treeLocation = treeLocation;
    }
    
    
}
