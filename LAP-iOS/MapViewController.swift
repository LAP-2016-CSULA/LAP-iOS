//
//  MapViewController.swift
//  LAP-iOS
//
//  Created by Hugo Sanchez on 12/31/15.
//  Copyright © 2015 Hugo Sanchez. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Heimdallr
import Alamofire

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var MapView: MKMapView!
    
    var heimdallr : Heimdallr!
    var ats : OAuthAccessTokenKeychainStore!

    
    let locationManager = CLLocationManager()
    var treeSelected:Bool = true
    var birdSelected:Bool = false
    var user:String = "";
    @IBOutlet weak var treeButton: UIBarButtonItem!
    @IBOutlet weak var birdButton: UIBarButtonItem!
    
    @IBAction func treeButtonTapped(sender: UIBarButtonItem) {
        if treeSelected == true{
            return;
        }
        else{
            sender.tintColor = UIColor.greenColor()
            birdButton.tintColor = UIColor.grayColor()
            treeSelected = true
            birdSelected = false
        }
        
        
    }
    
    @IBAction func birdButtonTapped(sender: UIBarButtonItem) {
        if birdSelected == true{
            return;
        }
        else{
            sender.tintColor = UIColor.redColor()
            treeButton.tintColor = UIColor.grayColor()
            birdSelected = true
            treeSelected = false
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
        self.mapView.mapType = MKMapType.Hybrid
        self.mapView.delegate = self;
        
        
        let url = NSURL(string: "http://isitso.pythonanywhere.com/userinfo/")
        let request = NSURLRequest(URL: url!)
        
        self.heimdallr.invalidateAccessToken();
        print("-------")
        print(self.ats.retrieveAccessToken()!.accessToken)
        
        _ = self.heimdallr.self.authenticateRequest(request)
            { (result) in
                
                print(self.ats.retrieveAccessToken()!.accessToken)
                switch result {
                case .Success:
                    let parameters  = ["access_token": self.ats.retrieveAccessToken()!.accessToken]
                    
                    Alamofire.request(.GET, "http://isitso.pythonanywhere.com/userinfo/", parameters: parameters)
                        .responseJSON { response in
                            print(response.result)
                            
                    
                            
                            if let JSON = response.result.value {
                                print("JSON: \(JSON["username"])")
                                
                                var access = "Student"
                                
                                if(String(JSON["is_staff"]) == "true")
                                {
                                    access = "Staff"
                                }
                                
                                if(String(JSON["first_name"]).isEmpty && String(JSON["last_name"]).isEmpty)
                                {
                                    
                                    if let t = JSON["username"]! {
                                    
                                        let tt = "Welcome " + String(t)
                                        self.displayMessage(tt)
                                    }
                                    
                                }
                                else
                                {
                                    if let t = JSON["first_name"]!
                                    {
                                        if let y = JSON["last_name"]!
                                        {
                                            let tt = "Welcome, \n" + String(t) + " " + String(y) + "\nAccess: " + access
                                            self.user = String(t) + " " + String(y)
                                            self.displayMessage(tt)
                                        }
                                    }
                                }
                            }
                    }
                case .Failure:
                    print("Failed")
                }
                
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        
        let center = CLLocationCoordinate2DMake(location!.coordinate.latitude, location!.coordinate.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.0011, longitudeDelta: 0.0011))
        
        self.mapView.setRegion(region, animated: true)
        
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Errors: " + error.localizedDescription)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let userLoggedIn = NSUserDefaults.standardUserDefaults().boolForKey("isUserLoggedIn")
        
        if(!userLoggedIn){
            self.performSegueWithIdentifier("loginView", sender: self)
        }
    }
    
    
    @IBAction func logoutButtonTapped(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isUserLoggedIn");
        NSUserDefaults.standardUserDefaults().synchronize();
        
        self.performSegueWithIdentifier("loginView", sender: self)
    }
    
    
    
    @IBAction func screenLongPressed(sender: UILongPressGestureRecognizer) {
        // DISPLAY ERROR MESSAGE IF TREE AND BIRD IS NOT SELECTED
        if sender.state != UIGestureRecognizerState.Began{
            return;
        }
        let annotation = MKPointAnnotation();
        if treeSelected == true {
            let refreshAlert = UIAlertController(title: "LAP", message: "Add tree at this location?", preferredStyle: UIAlertControllerStyle.Alert)
            
            refreshAlert.addAction(UIAlertAction(title: "YES", style: .Default, handler: { (action: UIAlertAction!) in
                //  === TASK 1 ========================
                //                ANOTHER SCREEN SHOULD BE PULLED UP DISPLAYING THE QUESTIONS
                //                THAT THE USER MUST ANSWER, PUT CODE FOR BRINGING UP THE QUESTIONARE HERE, THIS SECTION
                //                OF CODE WILL BE EXECUTED WHEN YES IS PRESSED.
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in

                if(self.mapView.annotations.count == 1){
                    print("Only one annotation left! Which is the user! count = ", self.mapView.annotations.count);
                    return; // to prevent user from being removed from map
                }
                else{
                    self.mapView.removeAnnotation(annotation)
                    
                }
                
            }))
            
            presentViewController(refreshAlert, animated: true, completion: nil)
            self.setPin(sender, annotation: annotation)
        }
        
    }
//    This method will be used to select a tree to match with a bird
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if(birdSelected){ // Bird is selected so do bird and tree matching
            print("Tree selected!!");
        }
    }
    func setPin(sender: UILongPressGestureRecognizer, annotation: MKPointAnnotation){
        let location = sender.locationInView(self.mapView)
        let locCoord = self.mapView.convertPoint(location, toCoordinateFromView: self.mapView)
        
        annotation.coordinate = locCoord
        annotation.title = "California Sycamore"
        annotation.subtitle = "Added by: "+self.user  ;
        
        self.mapView.addAnnotation(annotation)
        
    }
    
    func displayMessage(message: String){
        let myAlert = UIAlertController(title:"LAP", message:message, preferredStyle: UIAlertControllerStyle.Alert);
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil);
        myAlert.addAction(okAction);
        self.presentViewController(myAlert, animated:true, completion: nil);
    }
    
}

