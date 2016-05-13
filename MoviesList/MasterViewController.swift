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

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let entry = entries[indexPath.row]
        cell.textLabel!.text = entry["title"]?["label"] as? String
        cell.detailTextLabel?.text = entry["summary"]?["label"] as? String
        if let images = entry["im:image"] as? [[String:AnyObject]], url = images[0]["label"] as? String where images.count > 0 {
            print("What's up?")
        }
        return cell
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

