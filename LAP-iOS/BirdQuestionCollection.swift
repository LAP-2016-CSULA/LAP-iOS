//
//  BirdQuestionCollection.swift
//  LAP-iOS
//
//  Created by Kevin Argumedo on 2/24/16.
//  Copyright © 2016 Kevin Argumedo. All rights reserved.
//

import Foundation
import UIKit
import Heimdallr
import Alamofire
import Kingfisher

class BirdQuestionCollection : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var birds = [JSON]()
    var selected = [Bool]();
    var birdsPerched = [JSON]()
    var observation: Observation!;
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var bottomBar: UINavigationItem!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bottomBar.titleView = UIImageView(image: UIImage(named: "topbaricon"))

        title = "Bird Questions";
    }
    
    override func viewWillAppear(animated: Bool) {
        
        let myUrl = NSURL(string: "http://isitso.pythonanywhere.com/birds")
        let request = NSURLRequest(URL: myUrl!)
        
        self.observation.heimdallr.self.authenticateRequest(request)
        { (result) in
//                print(self.observation.ats.retrieveAccessToken()!.accessToken)
                switch result {
                case .Success:
                    
                    let parameters  = ["access_token": self.observation.ats.retrieveAccessToken()!.accessToken]
                    
                    Alamofire.request(.GET, myUrl!, parameters: parameters)
                        .responseJSON { response in
                            
                            if let tempJSON = response.result.value
                            {
                                for(_,jso) in JSON(tempJSON)
                                {
                                    self.birds.append(jso)
                                    self.selected.append(false);
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.birds.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
            as! BirdQuestionCell
        
        cell.name.text = String(birds[indexPath.row]["name"])
        
        let URL = NSURL(string: String(self.birds[indexPath.row]["image"]))!
        let resource = Resource(downloadURL: URL, cacheKey: String(self.birds[indexPath.row]["image"]))
        
        cell.imageView.kf_setImageWithResource(resource, placeholderImage: nil,
            optionsInfo: [.Transition(ImageTransition.Fade(1))])

        cell.checked = selected[indexPath.row]
        
        if(cell.checked!)
        {
            cell.checkedButton.setImage(UIImage(named:"checkedMark.png"), forState: UIControlState.Normal)
        }
        else
        {
            cell.checkedButton.setImage(UIImage(named:"checkMark.png"), forState: UIControlState.Normal)
        }
        
        cell.checkedButton?.layer.setValue(indexPath, forKey: "sendIndex")
        cell.checkedButton?.layer.setValue(cell, forKey: "sendCell")
        cell.checkedButton?.addTarget(self, action: "checkMark:", forControlEvents: UIControlEvents.TouchUpInside)
        
        return cell
    }
    
    func checkMark(sender:UIButton)
    {
        let cell = sender.layer.valueForKey("sendCell") as! BirdQuestionCell
        let index = sender.layer.valueForKey("sendIndex") as! NSIndexPath
        if(cell.checked!)
        {
            self.selected[index.row] = false
        }
        else
        {
            self.selected[index.row] = true
        }        
        self.collectionView.reloadData();
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "saveBirds")
        {
            for i in (0...birds.count-1)
            {
                if(selected[i])
                {
                    self.birdsPerched.append(self.birds[i])
                }
            }
        }
    }
}
