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
    init(title: String, viewController: UIViewController, action: () -> ())
    {
        _title = title
        _action = action
        _viewController = viewController
    }
    func doAction() { _action() }
    func checks() -> Bool { return false }
}

protocol SidePanelViewControllerDelegate {
    func itemSelected(item: MenuItem)
}

class SidePanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: SidePanelViewControllerDelegate?
    var menuItems: Array<MenuItem> = [MenuItem]()
    var mapViewController: ViewController! {
        didSet {
            addMenuItem("Define Field Boundaries", vc: mapViewController, action: {[unowned self] in self.mapViewController.hideSampleTable()})
            addMenuItem("Toggle Heatmap", vc: mapViewController, action:
                {[unowned self] in self.mapViewController.heatMapOn = !self.mapViewController.heatMapOn})
            addMenuItem("Collect Samples", vc: mapViewController, action: {[unowned self] in self.mapViewController.showSampleTable()})
            addMenuItem("Toggle Sample Annotations", vc: mapViewController, action: {[unowned self] in self.mapViewController.annotationsOn = !self.mapViewController.annotationsOn})
            addMenuItem("Toggle Field Annotations", vc: mapViewController, action: {[unowned self] in self.mapViewController.fieldOn = !self.mapViewController.fieldOn})
            addMenuItem("Go to location", vc: mapViewController, action: {[unowned self] in self.mapViewController.askForNewLocation()})
        }
    }
    
    var settingsController: SettingsViewController! {
        didSet {
            addMenuItem("Settings", vc: settingsController, action: {})
        }
    }

    var helpController: UIViewController! {
        didSet {
            addMenuItem("Help", vc: helpController, action: {})
        }
    }
    
    func addMenuItem(name: String, vc: UIViewController, action: ()->())
    {
        menuItems.append(MenuItem(title: name, viewController: vc, action: action))
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
        let cell = tableView.dequeueReusableCellWithIdentifier(TableView.CellIdentifiers.MenuCell, forIndexPath: indexPath) as MenuCell
        cell.configureFor(menuItems[indexPath.row])
        cell.accessoryView?.hidden = true
        return cell
    }
    

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let cell = tableView.dequeueReusableCellWithIdentifier(TableView.CellIdentifiers.MenuCell, forIndexPath: indexPath) as MenuCell
        if menuItems[indexPath.row].checks() {
            cell.accessoryView?.hidden = false
            cell.accessoryView?.setNeedsDisplay()
        }
        cell.configureFor(menuItems[indexPath.row])
        delegate?.itemSelected(menuItems[indexPath.row])
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
    
    func checks() -> Bool {
        if _menuItem != nil {
            return _menuItem.checks()
        }
        return false
    }
}