//
//  MasterViewController.swift
//  MoviesList
//
//  Created by Matt Long on 5/12/16.
//  Copyright © 2016 Matt Long. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var entries = [[String:AnyObject]]()


    override func viewDidLoad() {
        super.viewDidLoad()
        self.downloadFeed()
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = entries[indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    var imageCache = [String:UIImage]()
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let entry = entries[indexPath.row]
        cell.textLabel!.text = entry.title
        cell.detailTextLabel?.text = entry.summary
        if let url = entry.firstImageUrl {
            if let image = imageCache[url] {
                cell.imageView?.image = image
            } else {
                self.downlaodImageAtUrl(url, completion: { 
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    })
                })
            }
        }
        return cell
    }
    
    func downlaodImageAtUrl(urlString:String, completion:(() -> ())?) {
        if let url = NSURL(string: urlString) {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) in
                if let data = data where error == nil {
                    if let image = UIImage(data: data) {
                        self.imageCache[urlString] = image
                        completion?()
                    }
                }
            })
            task.resume()
        }
    }

    func downloadFeed() {
        let url = NSURL(string: "https://itunes.apple.com/us/rss/topmovies/limit=50/json")
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) { [weak self] (data, response, error) in
            if let data = data where error == nil {
                do {
                    if let records = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject] {
                        if let feed = records["feed"] as? [String:AnyObject], entries = feed["entry"] as? [[String:AnyObject]] {
                            self?.entries = entries
                            
                            dispatch_async(dispatch_get_main_queue(), { 
                                self?.tableView.reloadData()
                            })
                        }
                    }
                } catch {
                    
                }
            }
        }
        
        task.resume()
    }
}

extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
    var title : String {
        return self.valueForString("title")
    }
    
    var summary : String {
        return self.valueForString("summary")
    }
    
    var firstImageUrl : String? {
        return self.imageUrls?.first
    }
    
    
    // MARK: Utility
    func valueForString(key:Key) -> String {
        guard let contentDictionary = self[key] as? [String:AnyObject], content = contentDictionary["label"] as? String else {
            return ""
        }
        return content
    }
    
    var imageUrls : [String]? {
        if let images = self["im:image"] as? [[String:AnyObject]] {
            let urls = images.flatMap({ (imageDictionary) -> String? in
                guard let label = imageDictionary["label"] as? String else {
                    return nil
                }
                return label
                
            })
            return urls
        }
        return nil
    }

}
