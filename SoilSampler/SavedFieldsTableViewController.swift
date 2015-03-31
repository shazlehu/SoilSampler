//
//  SavedFieldsTableViewController.swift
//  SoilSampler
//
//  Created by Samuel Hazlehurst on 3/30/15.
//  Copyright (c) 2015 Terranian Farm. All rights reserved.
//

import UIKit

class SavedFieldsTableCell : UITableViewCell
{
    @IBOutlet weak var fieldName: UILabel!
    @IBOutlet weak var date: UILabel!
}

class SavedFieldsTableViewController: UITableViewController, UIAlertViewDelegate
{
    var mapViewController : ViewController!
    var delegate: SidePanelViewControllerDelegate?
    
    @IBAction func newField(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
//        delegate?.itemSelected(mapViewController)
        mapViewController.newField()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.tableView.allowsMultipleSelectionDuringEditing = false

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return mapViewController._fieldManager.savedFields.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SavedFieldsTableCell", forIndexPath: indexPath) as SavedFieldsTableCell

        // Configure the cell...
        cell.fieldName.text = mapViewController._fieldManager.savedFields[indexPath.item].name
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        mapViewController.setCurrentField(indexPath.item)
        delegate?.itemSelected(mapViewController)
    }

    var _fieldToDelete : NSIndexPath?
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            let cancelAlert = UIAlertController(title: "Delete field: " + mapViewController._fieldManager.savedFields[indexPath.item].name + "?", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            
            cancelAlert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: deleteField))
            _fieldToDelete = indexPath
            cancelAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
            
            self.presentViewController(cancelAlert, animated: true, completion: nil)
            

        }
    }
    func deleteField(action: UIAlertAction!)
    {
        mapViewController.deleteField(_fieldToDelete!.item)
        var paths = [AnyObject]()
        paths.append(_fieldToDelete!)
        tableView.deleteRowsAtIndexPaths(paths, withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
