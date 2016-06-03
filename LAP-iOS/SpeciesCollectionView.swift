//
//  SpeciesCollectionView.swift
//  LAP-iOS
//
//  Created by kevin on 1/26/16.
//  Copyright © 2016 Kevin Argumedo. All rights reserved.
//

import Foundation
import UIKit
import Heimdallr
import Alamofire
import Kingfisher
import SQLite

class SpeciesCollectionView : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    
    var observation: Observation!;
    
    @IBOutlet weak var bottomBar: UINavigationItem!
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let logo = UIImage(named: "topbaricon");
        let imageView = UIImageView(image:logo);
        self.bottomBar.titleView = imageView;
        title = "Species";
        let url = NSURL(string: "http://lap.pythonanywhere.com/api/treespecies")
        let request = NSURLRequest(URL: url!)
        
        
        self.observation.heimdallr.self.authenticateRequest(request)
        { (result) in
            switch result {
            case .Success:
                let parameters  = ["access_token": self.observation.ats.retrieveAccessToken()!.accessToken]
                
                Alamofire.request(.GET, self.observation.link, parameters: parameters)
                    .responseJSON { response in
                        
                        if let JSON1 = response.result.value
                        {
                            for(_,jso) in JSON(JSON1)
                            {
                                self.observation.species.append(jso)
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.collectionView.reloadData()
                        }
                }
            case .Failure:
                print("Failed")
            }
        }
    }

    
    override func viewWillAppear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.observation.species.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
        as! SpecieCell
        
        cell.specieName.text = String(self.observation.species[indexPath.row]["name"])
        
        cell.layer.borderWidth = 1;
        cell.layer.borderColor = UIColor(red: 187.0, green: 226.0, blue: 188.0, alpha: 1.0).CGColor;
        
        let URL = NSURL(string: String(self.observation.species[indexPath.row]["image"]))!
        let resource = Resource(downloadURL: URL, cacheKey: String(self.observation.species[indexPath.row]["image"]))
        cell.imageView.kf_showIndicatorWhenLoading = true;
        cell.imageView.kf_setImageWithResource(resource, placeholderImage: nil,
            optionsInfo: [.Transition(ImageTransition.Fade(1))])
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("toSpecie", sender: self);
    }
    
    @IBAction func cancelAdditionButton(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
   
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "toSpecie")
        {
            var dest = self.collectionView!.indexPathsForSelectedItems()!
            
            let indexPath = dest[0] as NSIndexPath
            
            let specieView = segue.destinationViewController as! ViewSpecie
            self.observation.specie = self.observation.species[indexPath.row];
            specieView.observation = self.observation;
        }
    }
    
}