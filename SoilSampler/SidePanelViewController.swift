//
//  LeftViewController.swift
//  SlideOutNavigation
//
//  Created by James Frost on 03/08/2014.
//  Copyright (c) 2014 James Frost. All rights reserved.
//

import UIKit


class MenuItem {
    var _title : String
    var _viewController: UIViewController!
    var _action: () -> ()
    var _toggles: Bool = false
    init(title: String, viewController: UIViewController, action: () -> (), toggles: Bool)
    {
        _title = title
        _action = action
        _viewController = viewController
        _toggles = toggles
    }
    func doAction() { _action() }
}

protocol SidePanelViewControllerDelegate {
    func itemSelected(item: UIViewController)
}

class SidePanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: SidePanelViewControllerDelegate?
    var menuItems = [MenuItem]()
    var mapViewController: ViewController! {
        didSet {
            addMenuItem("Current Field", vc: mapViewController, action: {[unowned self] in self.mapViewController.hideSampleTable()}, toggles: false)
            addMenuItem("Samples", vc: mapViewController, action: {[unowned self] in self.mapViewController.showSampleTable()},toggles: true)
            addMenuItem("Heatmap", vc: mapViewController, action:
                {[unowned self] in self.mapViewController.heatMapOn = !self.mapViewController.heatMapOn}, toggles: true)
            addMenuItem("Toggle Sample Annotations", vc: mapViewController, action: {[unowned self] in self.mapViewController.annotationsOn = !self.mapViewController.annotationsOn}, toggles: true)
            addMenuItem("Toggle Field Annotations", vc: mapViewController, action: {[unowned self] in self.mapViewController.fieldOn = !self.mapViewController.fieldOn}, toggles: true)
            addMenuItem("Go to location", vc: mapViewController, action: {[unowned self] in self.mapViewController.askForNewLocation()},toggles: false)
        }
    }
    
    var settingsController: SettingsViewController! {
        didSet {
            addMenuItem("Settings", vc: settingsController, action: {}, toggles: false)
            settingsController.mapViewController = mapViewController
        }
    }

    var helpController: UIViewController! {
        didSet {
            addMenuItem("Help", vc: helpController, action: {}, toggles: false)
        }
    }
    
    var savedFieldController: SavedFieldsTableViewController! {
        didSet {
            addMenuItem("Saved Fields", vc: savedFieldController, action: {}, toggles: false)
            savedFieldController.mapViewController = mapViewController
            savedFieldController.delegate = self.delegate
        }
    }
    
    func addMenuItem(name: String, vc: UIViewController, action: ()->(), toggles: Bool)
    {
        menuItems.append(MenuItem(title: name, viewController: vc, action: action, toggles: toggles))
    }

    struct TableView {
        struct CellIdentifiers {
            static let MenuCell = "MenuCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()

    }
    
    // MARK: Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return menuItems.count
    }
    // Mark: Table View Delegate
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TableView.CellIdentifiers.MenuCell, forIndexPath: indexPath) as! MenuCell
        cell.configureFor(menuItems[indexPath.row])
        cell.accessoryView?.hidden = true
        if menuItems[indexPath.row]._toggles {
            cell.textLabel?.textColor = UIColor(red: 0, green: 0.3, blue: 1, alpha: 1)
//            cell.toggleImageView.image = UIImage(named: "draggable_icon")
//            //            cell.accessoryView?.setNeedsDisplay()
        }
//        cell.imageNameLabel.sizeToFit()

//        tableWidth = max(cell.imageNameLabel.frame.maxX, tableWidth)
//        println("size: \(tableWidth)")
        return cell
    }
    
  //  var tableWidth: CGFloat = 0.0

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        _ = tableView.dequeueReusableCellWithIdentifier(TableView.CellIdentifiers.MenuCell, forIndexPath: indexPath) as! MenuCell
//        if menuItems[indexPath.row]._toggles {
//            cell.toggleImageView.image = UIImage(named: "draggable_icon")
//            //            cell.accessoryView?.setNeedsDisplay()
//        }
        //cell.configureFor(menuItems[indexPath.row])
        delegate?.itemSelected(menuItems[indexPath.row]._viewController)
        menuItems[indexPath.row].doAction()

    }
    
}

class MenuCell: UITableViewCell {
    @IBOutlet weak var imageNameLabel: UILabel!
    
    private var _menuItem: MenuItem!
    func configureFor(menuItem: MenuItem) {
        imageNameLabel.text = menuItem._title
        _menuItem = menuItem
    }
    
//    func checks() -> Bool {
//        if _menuItem != nil {
//            return _menuItem.checks()
//        }
//        return false
//    }
}