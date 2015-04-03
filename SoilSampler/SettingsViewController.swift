//
//  SettingsViewController.swift
//  MapTest
//
//  Created by Samuel Hazlehurst on 3/22/15.
//  Copyright (c) 2015 Terranian Farm. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    var mapViewController: ViewController!
    
    @IBAction func setAccuracy(sender: UISegmentedControl) {
        mapViewController._locationManager.setAccuracy(sender.selectedSegmentIndex == 1)
    }
}
