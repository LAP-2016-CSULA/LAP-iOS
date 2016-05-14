//
//  AnnotationViewController.swift
//  LAP-iOS
//
//  Created by Hugo Sanchez on 3/6/16.
//  Copyright © 2016 Kevin Argumedo. All rights reserved.
//

import Foundation
import UIKit
import Heimdallr
import Alamofire
import Kingfisher
import MapKit;

class AnnotationViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var observation: Observation!;
    
    @IBOutlet weak var bottomBar: UINavigationItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        let logo = UIImage(named: "topbaricon");
        let imageView = UIImageView(image:logo);
        self.bottomBar.titleView = imageView;
        title = "Trees";
    }
    
    override func viewWillAppear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.observation.treeList.annotationList.count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
            as! AnnotationCell
        
        cell.textLabel.text = self.observation.treeList.annotationList[indexPath.row].title;
        
        
        
        let URL = NSURL(string: String(self.observation.treeList.annotationList[indexPath.row].imageName))!
        let resource = Resource(downloadURL: URL, cacheKey: nil);
        
        cell.image.kf_showIndicatorWhenLoading = true;
        
        cell.image.kf_setImageWithResource(resource, placeholderImage: nil,
            optionsInfo: [.Transition(ImageTransition.Fade(1))])
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("toSpecie", sender: self);
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "toSpecie")
        {
            var dest = self.collectionView!.indexPathsForSelectedItems()!
            
            let indexPath = dest[0] as NSIndexPath
            
            let specieView = segue.destinationViewController as! ViewSpecie
            self.observation.treeID = self.observation.treeList.annotationList[indexPath.row].treeID;
            self.observation.specie = ["image":(self.observation.treeList.annotationList[indexPath.row].imageName)!, "name":self.observation.treeList.annotationList[indexPath.row].title!, "description": self.observation.treeList.annotationList[indexPath.row].info!, "treeID":self.observation.treeList.annotationList[indexPath.row].treeID!, "type":["id": 1]];
            specieView.observation = self.observation;
            
        }
    }
}
