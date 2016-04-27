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
import SQLite


class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var MapView: MKMapView!
    @IBOutlet weak var addTreeOnUserButton: UIBarButtonItem!
    @IBOutlet weak var bottomBar: UINavigationItem!
    
    var heimdallr : Heimdallr!
    var ats : OAuthAccessTokenKeychainStore!
    var pinList = [JSON]();
    var trees = true;
    var userName:String = "";
    let locationManager = CLLocationManager()
    var delAnnot = CustomPointAnnotation!();
    var observation: Observation!;
    var guestLoggedIn: Bool!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.MapView.showsUserLocation = true
        self.MapView.delegate = self;
        let logo = UIImage(named: "topbaricon");
        let imageView = UIImageView(image:logo);
        self.bottomBar.titleView = imageView;
        self.MapView.mapType = MKMapType.Hybrid;
        logIn();
        
    }
    override func viewWillAppear(animated: Bool) {
        self.pinList.removeAll()
        self.MapView.removeAnnotations(MapView.annotations)

        self.observation = Observation(ats: self.ats, heimdallr: self.heimdallr);
        if self.guestLoggedIn != nil{
            if(self.guestLoggedIn == true){
                self.observation.guest = true;
                self.addTreeOnUserButton.enabled = false;
                self.addTreeOnUserButton.tintColor = UIColor.clearColor();
                self.MapView.gestureRecognizers?.removeAll();
            }
        }
        
        if let tempAnnot = delAnnot
        {
            self.MapView.removeAnnotation(tempAnnot);
            self.delAnnot = CustomPointAnnotation!();
        }
        
        let path = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true
            ).first!
        
        let db = try! Connection("\(path)/db.sqlite3")
        
        let treeTable = Table("treeTable")
        let id = Expression<Int64>("id")
        let species_id = Expression<Int64>("species_id")
        let species_type_id = Expression<Int64>("species_type_id")
        let species_type_name = Expression<String>("species_type_name")
        let species_scientific_name = Expression<String>("scientific_name")
        let species_name = Expression<String>("name")
        let species_description = Expression<String>("description")
        let species_image = Expression<String>("species_image")
        let changed_by = Expression<String>("changed_by")
        let long = Expression<String>("long")
        let lat = Expression<String>("lat")
        let image = Expression<String>("image")
        let date_modified = Expression<String>("date_modified")
        
        //table doesnt exist
        if(!tableExists("treeTable"))
        {
            print("Table Doesn't exist, Creating database")
            try! db.run(treeTable.create(ifNotExists:true ) { t in
                t.column(id, primaryKey: true)
                t.column(species_id)
                t.column(species_type_id)
                t.column(species_type_name)
                t.column(species_scientific_name)
                t.column(species_name)
                t.column(species_description)
                t.column(species_image)
                t.column(changed_by)
                t.column(long)
                t.column(lat)
                t.column(image)
                t.column(date_modified)
                })
            
            let url = NSURL(string: "http://isitso.pythonanywhere.com/treespecies/")
            let request = NSURLRequest(URL: url!)
            
            self.heimdallr.self.authenticateRequest(request)
            { (result) in
                
                
                
                //                print(self.ats.retrieveAccessToken()!.accessToken)
                switch result {
                case .Success:
                    let parameters  = ["access_token": self.ats.retrieveAccessToken()!.accessToken]
                    
                    Alamofire.request(.GET, "http://isitso.pythonanywhere.com/trees/?format=json", parameters: parameters)
                        .responseJSON { response in
                            
                            if let JSON1 = response.result.value
                            {
                                for(_,jso) in JSON(JSON1)
                                {
                                    self.pinList.append(jso)
                                    
                                    let tempDate = String(jso["date_modified"])
                                    
                                    var dateArray = tempDate.characters.split{$0 == "T"}.map(String.init)
                                    var timeArray = dateArray[1].characters.split{$0=="."}.map(String.init)
                                    
                                    let addDate = dateArray[0] + " " + timeArray[0]
                                    
                                    let insert = treeTable.insert(id <- Int64(String(jso["id"]))!, species_id <- Int64(String((jso["species"]["id"])))!,species_type_id <- Int64(String((jso["species"]["type"]["id"])))!, species_type_name <- String(jso["species"]["type"]["name"]), species_scientific_name <- String(jso["species"]["scientific_name"]), species_name <- String(jso["species"]["name"]), species_description <- String(jso["species"]["description"]), species_image <- String(jso["species"]["image"]), changed_by <- String(jso["changed_by"]), lat <- String(jso["lat"]), image <- String(jso["image"]), date_modified <- String(addDate), long<-String(jso["long"]))
                                    
                                    try! db.run(insert)
                                    
                                    let lat = jso["lat"].double!;
                                    let long = jso["long"].double!;
                                    
                                    let location:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                                    
                                    let annotation = CustomPointAnnotation();
                                    annotation.coordinate = location;
                                    annotation.title = String(jso["species"]["name"]);
                                    annotation.info = String(jso["species"]["description"]);
                                    annotation.treeID = Int(String(jso["id"]));
                                    annotation.imageName = String(jso["image"]);
                                    annotation.specieID = Int(String(jso["species"]["id"]));
                                    annotation.location = CLLocationCoordinate2D(latitude: lat, longitude: long);

                                    annotation.color = UIColor(colorLiteralRed: 0, green: 1, blue: 0, alpha: 1);
                                    
                                    
                                    self.MapView.addAnnotation(annotation);
                                }
                                self.combineCloseAnnotations()
                                
                                let currentDate = NSDate()
                                
                                let dateFormatter = NSDateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                NSUserDefaults.standardUserDefaults().setValue(String(dateFormatter.stringFromDate(currentDate)), forKey: "lastUpdate")
                            }
                    }
                case .Failure:
                    print("Failed")
                }
            }
        }
        //table already created
        else{
            let lastUpdate = String(NSUserDefaults.standardUserDefaults().valueForKey("lastUpdate")!)
            
            print(lastUpdate);
            let url = NSURL(string: "http://isitso.pythonanywhere.com/treespecies/")
            
            let request = NSURLRequest(URL: url!)
            self.heimdallr.self.authenticateRequest(request)
            { (result) in
                
                switch result {
                case .Success:
                    let parameters  = ["access_token": self.ats.retrieveAccessToken()!.accessToken, "time": lastUpdate]
                    
                    Alamofire.request(.GET, "http://isitso.pythonanywhere.com/trees/", parameters: parameters)
                        .responseJSON { response in
                            
                            if let JSON1 = response.result.value
                            {
                                for(_,jso) in JSON(JSON1)
                                {
                                    let treeQuery = Table("treeTable")
                                    var update = false
                                    let tempInt : Int64 = Int64(String(jso["id"]))!
                                    
                                    for _ in try! db.prepare(treeQuery.filter(id == tempInt)) {
                                        update = true
                                    }
                                    
                                    if(update)
                                    {
                                        print("This tree has been modified")
                                        let updateRow = treeQuery.filter(id == tempInt)
                                        try! db.run(updateRow.update(image <- String(jso["image"])))
                                    }
                                    else
                                    {
                                        let tempDate = String(jso["date_modified"])
                                        
                                        var dateArray = tempDate.characters.split{$0 == "T"}.map(String.init)
                                        var timeArray = dateArray[1].characters.split{$0=="."}.map(String.init)
                                        
                                        let addDate = dateArray[0] + " " + timeArray[0]
                                        
                                        let insert = treeTable.insert(id <- Int64(String(jso["id"]))!, species_id <- Int64(String((jso["species"]["id"])))!,species_type_id <- Int64(String((jso["species"]["type"]["id"])))!, species_type_name <- String(jso["species"]["type"]["name"]), species_scientific_name <- String(jso["species"]["scientific_name"]), species_name <- String(jso["species"]["name"]), species_description <- String(jso["species"]["description"]), species_image <- String(jso["species"]["image"]), changed_by <- String(jso["changed_by"]), lat <- String(jso["lat"]), image <- String(jso["image"]), date_modified <- String(addDate), long<-String(jso["long"]))
                                        
                                        try! db.run(insert)
                                    }
                                }
                                
                                for tree in try! db.prepare(treeTable) {
                                    
                                    let tempType = ["id": String(tree[species_type_id]), "name": String(tree[species_type_name])]
                                    
                                    let tempSpecie = ["id": String(tree[species_id]), "type": tempType, "scientific_name": tree[species_scientific_name], "name": tree[species_name], "description": tree[species_description], "image": tree[species_image]]
                                    
                                    let tempTreeObject = ["id" : String(tree[id]), "species": tempSpecie, "changed_by": String(tree[changed_by]), "long": String(tree[long]), "lat": String(tree[lat]), "image": String(tree[image]), "date_modified": String(tree[date_modified])]
                                    
                                    var pin = JSON(tempTreeObject)
                                    self.pinList.append(pin)
                                    
                                    let lat = Double(String(pin["lat"]))!
                                    let long = Double(String(pin["long"]))!
                                    
                                    let location:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                                    
                                    let annotation = CustomPointAnnotation()
                                    annotation.coordinate = location
                                    annotation.title = String(pin["species"]["name"]);
                                    annotation.info = String(pin["species"]["description"]);
                                    annotation.treeID = Int(String(pin["id"]));
                                    annotation.imageName = String(pin["image"]);
                                    annotation.specieID = pin["species"]["id"].int;
                                    annotation.location = CLLocationCoordinate2D(latitude: lat, longitude: long);
                                    annotation.color = UIColor(colorLiteralRed: 0, green: 1, blue: 0, alpha: 1);
                                    self.MapView.addAnnotation(annotation);
                                }
                                self.combineCloseAnnotations()
                                
                            }
                            
                            Alamofire.request(.GET, "http://isitso.pythonanywhere.com/deletedtrees", parameters: parameters)
                                .responseJSON
                                { response in
                                    
                                    if let JSON1 = response.result.value
                                    {
                                        for(_,jso) in JSON(JSON1)
                                        {
                                            print("deleted tree")
                                            let treeQuery = Table("treeTable")
                                            let tempInt : Int64 = Int64(String(jso["tree_id"]))!
                                            
                                            try! db.run(treeQuery.filter(id == tempInt).delete())
                                        }
                                    }
                            }
                    }
                case .Failure:
                    print("Failed")
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.MapView.reloadInputViews();
                let currentDate = NSDate()
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                NSUserDefaults.standardUserDefaults().setValue(String(dateFormatter.stringFromDate(currentDate)), forKey: "lastUpdate")
                
            }
        }
        
    }
    
    
    func combineCloseAnnotations(){
        for annotation in self.MapView.annotations{
            if let ann = annotation as? CustomPointAnnotation{
                let mapPoint = MKMapPointForCoordinate(ann.coordinate);
                let searchSize = MKMapSize(width: 50, height: 50);
                let searchArea = MKMapRect(origin: mapPoint, size: searchSize);
                var set = self.MapView.annotationsInMapRect(searchArea);
                set.remove(self.MapView.userLocation);
                
                if(set.count > 1){
                    let head = CustomPointAnnotation();
                    head.coordinate = ann.coordinate;
                    head.isHead = true;
                    head.color = UIColor(colorLiteralRed: 0, green: 0.5, blue: 0, alpha: 1);
                    
                    while(set.count > 0){
                        if let a = set.popFirst() as? CustomPointAnnotation{
                            if((a.isHead) != nil){
                                for pin in a.annotationList{
                                    head.annotationList.append(pin);
                                }
                                self.MapView.removeAnnotation(a);
                            }
                            else{
                                head.annotationList.append(a);
                                self.MapView.removeAnnotation(a);
                            }
                        }
                        
                    }
                    self.MapView.removeAnnotation(ann);
                    head.title = String(head.annotationList.count) + " trees";
                    self.MapView.addAnnotation(head);
                    
                }
            }
        }
        
    }
    
    func logIn(){
        self.observation = Observation(ats: self.ats, heimdallr: self.heimdallr);
        
        let url = NSURL(string: "http://isitso.pythonanywhere.com/userinfo/")
        let request = NSURLRequest(URL: url!);
        
        _ = self.heimdallr.self.authenticateRequest(request)
            { (result) in
                
                switch result {
                case .Success:
                    let parameters  = ["access_token": self.ats.retrieveAccessToken()!.accessToken]
                    
                    Alamofire.request(.GET, "http://isitso.pythonanywhere.com/userinfo/", parameters: parameters)
                        .responseJSON { response in
                            
                            
                            
                            if let JSON1 = response.result.value {
                                self.observation.user = JSON(JSON1)

                                var access = "Student"
                                
                                if let staff = JSON1["is_staff"]!
                                {
                                    if(String(staff) == "1")
                                    {
                                        access = "Staff"
                                    }
                                    
                                }
                                if(String(JSON1["first_name"]).characters.count == 10 && String(JSON1["last_name"]).characters.count == 10)
                                {

                                    if let t = JSON1["username"]! {
                                        let tt = String(t) + "\nAccess: " + access
//                                        self.displayMessage(String(tt), title:"Welcome");
                                    }
                                    
                                }
                                else
                                {
                                    if let t = JSON1["first_name"]!
                                    {
                                        if let y = JSON1["last_name"]!
                                        {
                                            let tt = String(t) + " " + String(y) + "\nAccess: " + access
                                            self.userName = String(t);
//                                            self.displayMessage(String(tt),title:"Welcome");
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

    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if(mapView.camera.altitude < 313){
            mapView.camera.altitude = 314;
        }
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if(mapView.camera.altitude < 313){
            mapView.camera.altitude = 314;
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        
        let center = CLLocationCoordinate2DMake(location!.coordinate.latitude, location!.coordinate.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.0011, longitudeDelta: 0.0011))
        
        self.MapView.setRegion(region, animated: true);
        
        self.locationManager.stopUpdatingLocation();
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Errors: " + error.localizedDescription)
    }
    
    override func viewDidAppear(animated: Bool) {
    }
    
    
    @IBAction func logoutButtonTapped(sender: AnyObject) {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet);
        let logoutAction = UIAlertAction(title: "Logout", style: .Default, handler: {(action: UIAlertAction!) in
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isUserLoggedIn");
            NSUserDefaults.standardUserDefaults().synchronize();
            KeychainWrapper.standardKeychainAccess().removeAllKeys();
            self.performSegueWithIdentifier("loginView", sender: self)
        });
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {(alert: UIAlertAction!) -> Void in
        });
        
        menu.addAction(logoutAction);
        menu.addAction(cancelAction);
        
        presentViewController(menu, animated: true, completion: nil);
    }
    
    
    @IBAction func screenLongPressed(sender: UILongPressGestureRecognizer) {
        // DISPLAY ERROR MESSAGE IF TREE AND BIRD IS NOT SELECTED
        if sender.state != UIGestureRecognizerState.Began{
            return;
        }
        
        let annotation = CustomPointAnnotation();
        let refreshAlert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
        refreshAlert.addAction(UIAlertAction(title: "Add Tree", style: .Default, handler: { (action: UIAlertAction!) in
            self.performSegueWithIdentifier("toTrees", sender: self)
        }))
            
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {(alert: UIAlertAction!) -> Void in
            if(self.MapView.annotations.count == 1){
                print("Only one annotation left! Which is the user! count = ", self.MapView.annotations.count);
                return; // to prevent user from being removed from map
            }
            else{
                self.MapView.removeAnnotation(annotation)
            }
        }));
        presentViewController(refreshAlert, animated: true, completion: nil);
        self.delAnnot = annotation
        self.setPin(sender,annotation: annotation);
    }
    

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let location = view.annotation?.coordinate;
        
        let center = CLLocationCoordinate2DMake(location!.latitude, location!.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.0011, longitudeDelta: 0.0011))
        
        self.MapView.setRegion(region, animated: true);
    }
    
    @IBAction func pinUserLocationButton(sender: AnyObject) {
        if(MapView.userLocation.coordinate.latitude == 0 && MapView.userLocation.coordinate.longitude == 0){
            displayMessage("Cannot locate user, Please make sure LAP has user location turned on",title: "Error");
            return;
        }
        self.moveMapOverUser(sender);
        let userLocation = MapView.userLocation;
        let annotation = CustomPointAnnotation();
        let refreshAlert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        refreshAlert.addAction(UIAlertAction(title: "Add Tree", style: .Default, handler: { (action: UIAlertAction!) in
            self.performSegueWithIdentifier("toTrees", sender: self)
        }))
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {(alert: UIAlertAction!) -> Void in
            if(self.MapView.annotations.count == 1){
                print("Only one annotation left! Which is the user! count = ", self.MapView.annotations.count);
                return; // to prevent user from being removed from map
            }
            else{
                self.MapView.removeAnnotation(annotation)
            }
        }));
        presentViewController(refreshAlert, animated: true, completion: nil);
        self.delAnnot = annotation
        self.setUserPin(userLocation,annotation: annotation);
        
    }
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is CustomPointAnnotation) {
            return nil
        }
        let annotation = annotation as! CustomPointAnnotation;
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if anView == nil {
            anView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView!.canShowCallout = true;
            anView!.pinTintColor = annotation.color;
            anView!.animatesDrop = false;
            let imageView = UIButton(frame: CGRectMake(0, 0, 30, 30));
            imageView.setImage(UIImage(named:"plusIcon"), forState: UIControlState.Normal);
            anView!.leftCalloutAccessoryView = imageView;
        }
        else {
            anView!.pinTintColor = annotation.color;
            anView!.annotation = annotation;
            anView!.animatesDrop = false;
        }
        
        return anView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let pin = view.annotation as? CustomPointAnnotation;
        self.observation.treeList = CustomPointAnnotation();
        
        
        if((pin!.isHead) != nil){
            self.observation.treeList = pin;
            self.observation.isUpdate = true;
            self.performSegueWithIdentifier("toAnnotationView", sender: self);
        }
        else{
            self.observation.treeSelected.removeAll();

            self.observation.treeSelected.append(["image":(pin?.imageName)!, "name":(pin?.title)!, "description": (pin?.info)!, "treeID":(pin?.treeID)!, "type":["id": 1]]);
            self.observation.setTreeLocation((pin?.coordinate)!);
            self.observation.isUpdate = true;
            self.observation.specie = self.observation.treeSelected[0];
            self.performSegueWithIdentifier("toUpdateTree", sender: self);
        }
    }
    
    @IBAction func moveMapOverUser(sender: AnyObject) {
        if(MapView.userLocation.coordinate.latitude == 0 && MapView.userLocation.coordinate.longitude == 0){
            displayMessage("Cannot locate user, Please make sure LAP has user location turned on",title: "Error");
            return;
        }
        let location = MapView.userLocation;
        
        let center = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.0011, longitudeDelta: 0.0011))
        
        self.MapView.setRegion(region, animated: true);
    }
    
    func mapView(mapView: MKMapView, didFailToLocateUserWithError error: NSError) {
        displayMessage("Cannot locate user, Please make sure LAP has user location turned on",title: "Error");
    }
    
    func setUserPin(sender: MKUserLocation, annotation: CustomPointAnnotation){
        self.observation.setTreeLocation(sender.coordinate);
        annotation.coordinate = (sender.location?.coordinate)!;
        self.MapView.addAnnotation(annotation);
    }
    
    func setPin(sender: UILongPressGestureRecognizer, annotation: CustomPointAnnotation){
        let location = sender.locationInView(self.MapView)
        let locCoord = self.MapView.convertPoint(location, toCoordinateFromView: self.MapView)
        
        self.observation.setTreeLocation(locCoord);
        annotation.coordinate = locCoord;
        self.MapView.addAnnotation(annotation)
    }
    
    func displayMessage(message: String, title: String){
        let myAlert = UIAlertController(title:title, message:message, preferredStyle: UIAlertControllerStyle.Alert);
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil);
        myAlert.addAction(okAction);
        self.presentViewController(myAlert, animated:true, completion: nil);
    }
    
    func tableExists(tableName: String) -> Bool {
        let path = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true
            ).first!
        
        let db = try! Connection("\(path)/db.sqlite3")
        let count:Int64 = db.scalar(
            "SELECT EXISTS(SELECT name FROM sqlite_master WHERE name = ?)", tableName
            ) as! Int64
        if count>0{
            return true
        }
        else{
            return false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if(segue.identifier == "toSpecies")
        {
            let heim = segue.destinationViewController as! SpeciesCollectionView
            self.observation.link = "http://isitso.pythonanywhere.com/treespecies/";
            self.observation.viewOnly = true;
            heim.observation = self.observation;
        }
        
        if(segue.identifier == "toTrees")
        {
            let heim = segue.destinationViewController as! SpeciesCollectionView
            self.observation.link = "http://isitso.pythonanywhere.com/treespecies";
            heim.observation = self.observation;
        }
        
        if(segue.identifier == "toProtocols"){
            
        }
        
        if(segue.identifier == "toUpdateTree"){
            let heim = segue.destinationViewController as! ViewSpecie
            heim.observation = self.observation;
        }
        
        if(segue.identifier == "toAnnotationView"){
            let heim = segue.destinationViewController as! AnnotationViewController;
            heim.observation = self.observation;
        }
    }

    
}


