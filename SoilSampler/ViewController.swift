//
//  ViewController.swift
//  MapTest
//
//  Created by Samuel Hazlehurst on 2/16/15.
//  Copyright (c) 2015 Terranian Farm. All rights reserved.
//

/* Future feature list:

    -Navigate in background from point to point w/ vibration
    -Navigate in foreground
    -Fancy annotations
    -Ability to move sample points
    -Save to Google Drive
    -Per field settings
    -Automagically make heatmap
    -Samples parallel to field edge - check
*/


import UIKit
import MapKit
import CoreLocation
import Foundation

class ViewController: CenterViewController, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, MKMapViewDelegate
{
// MARK: Constants
    private struct Constants {
        static let DefaultSpan = MKCoordinateSpanMake(0.001, 0.001)
        struct Alerts {
            static let Title = "Really delete sample points?"
            static let FieldSample = "Delete field and sample"
            static let SampleOnly = "Delete sample"
            static let Cancel = "Cancel"
            static let DefineField = "Please tap the map to mark field corners."
            static let DefineFieldAndSample = "Please tap the map to mark field corners, use the +/- buttons to generate samples."
            static let OK = "Ok"
        }
        static let Title = "Define Sample"
        static let ClearedTitle = "Samples: 0"
        static let ShareMessage = "This is a spreadsheet of latitude & longitude coordinates and penetrometer depths."
        static let ShareTitle = "Share a spreadsheet of your penetrometer readings."
        
        struct Table {
            static let AnimationDuration :NSTimeInterval = 0.5
            static let HeightMultiplier :CGFloat = 0.4
            static let MapHeightMultiplier :CGFloat = 0.7
        }
    }
    
    let sampler = SampleGenerator()

    @IBOutlet weak var map: MKMapView! {
        didSet {
            map.showsUserLocation = true
            map.mapType = MKMapType.Hybrid
            map.delegate = self
            var region = MKCoordinateRegion(center: map.userLocation.coordinate, span: Constants.DefaultSpan)
            map.setRegion(region, animated: false)
        }
    }

    var locationManager: LocationManager!

    @IBOutlet weak var randomOrGrid: UISegmentedControl!
    
    var sampleAnnotations = [AnyObject]()
    var fieldAnnotations = [AnyObject]()
    
    var mapToolBarConstraint : NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set constraint between toolbar and map so we can change it later
        
        mapToolBarConstraint = NSLayoutConstraint(item: map, attribute: .Bottom, relatedBy: .Equal, toItem: toolBar, attribute: .Top, multiplier: 1, constant: 0)
        view.addConstraint(mapToolBarConstraint)
        if view.needsUpdateConstraints() { view.updateConstraints() }
        locationManager = LocationManager(aSampler: self.sampler, aMap: self.map, aView: self)
    }
    
    // MARK: IBActions
    
    @IBAction func clear(sender: AnyObject) {
        let cancelAlert = UIAlertController(title: Constants.Alerts.Title, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        cancelAlert.addAction(UIAlertAction(title: Constants.Alerts.FieldSample, style: UIAlertActionStyle.Destructive, handler: doClear))

        cancelAlert.addAction(UIAlertAction(title: Constants.Alerts.SampleOnly, style: UIAlertActionStyle.Destructive, handler: doClearSample))
        
        cancelAlert.addAction(UIAlertAction(title: Constants.Alerts.Cancel, style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(cancelAlert, animated: true, completion: nil)
        
    }
    // Clear all the annotations and the samples
    func doClear(action: UIAlertAction!)
    {
        map.removeAnnotations(sampleAnnotations)
        map.removeAnnotations(fieldAnnotations)
        sampleAnnotations.removeAll(keepCapacity: true)
        fieldAnnotations.removeAll(keepCapacity: true)
        sampler.clear()
        hideSampleTable()
        self.navigationItem.title = Constants.Title
    }
    
    
    // Clear only sample, not the field
    func doClearSample(action: UIAlertAction!)
    {
        map.removeAnnotations(sampleAnnotations)
        sampleAnnotations.removeAll(keepCapacity: true)
        sampler.clearSample()
        
        hideSampleTable()
        self.navigationItem.title = Constants.ClearedTitle
    }


    @IBAction func changeSampleNumber(sender: UIStepper) {
        sampler.sampleDensity = Int(sender.value)
        self.doClearSample(nil)
        getSamplingPoints(self)
    }
    
    
    @IBAction func shareFile(sender: AnyObject) {
        
        let objectsToShare = [Constants.ShareMessage, sampler.writeFile()]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

        // New Excluded Activities Code

        
        activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList, UIActivityTypeMessage,
            UIActivityTypeCopyToPasteboard]
        
        activityVC.title = Constants.ShareTitle
        self.presentViewController(activityVC, animated: true, completion: nil)

    }

    @IBAction func goToUserLocation(sender: AnyObject) {
        var region = MKCoordinateRegion(center: map.userLocation.coordinate, span: Constants.DefaultSpan)
        map.setRegion(region, animated: false)
    }
    
    @IBAction func getSamplingPoints(sender: AnyObject) {
        doClearSample(nil)
        
        if let points = sampler.generateTestPoints(randomOrGrid.selectedSegmentIndex == 1) {
        
            for var i = 0; i < points.count; i++ {
            
                var annotation = CustomAnnotation(index: i)
        
                annotation.setCoordinate(points[i].point)
                annotation.isCorner = false
                
                map.addAnnotation(annotation)
                sampleAnnotations.append(annotation)
            }

            self.navigationItem.title = "Samples: \(points.count)"
        }
        else {
            let fieldAlert = UIAlertController(title: Constants.Alerts.DefineField, message: nil, preferredStyle: UIAlertControllerStyle.Alert)

            fieldAlert.addAction(UIAlertAction(title: Constants.Alerts.OK, style: UIAlertActionStyle.Default, handler: nil))

            self.presentViewController(fieldAlert, animated: true, completion: nil)
        }
    }
    @IBOutlet weak var toolBar: UIToolbar!
    
    // MARK: Sample Table Functions
    
    var takingSamples = false
    func showSampleTable() {
        if sampler.count == 0 {
            let fieldAlert = UIAlertController(title: Constants.Alerts.DefineFieldAndSample, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            
            fieldAlert.addAction(UIAlertAction(title: Constants.Alerts.OK, style: UIAlertActionStyle.Default, handler: nil))
            
            self.presentViewController(fieldAlert, animated: true, completion: nil)
            
        }
        else if tableView == nil {
            let mapFrame = self.map.frame

            self.toolBar.deActivate()
            UIView.animateWithDuration(Constants.Table.AnimationDuration) {
                self.tableView = UITableView(frame: CGRect(x: self.map.frame.origin.x, y: self.map.frame.height, width: self.map.frame.width, height: mapFrame.height * Constants.Table.HeightMultiplier))
                
                self.map.frame = CGRect(x: self.map.frame.origin.x, y: self.map.frame.origin.y, width: self.map.frame.width, height: self.map.frame.height * Constants.Table.MapHeightMultiplier)

                self.view.addSubview(self.tableView)
                
                self.tableView.frame = CGRect(x: self.map.frame.origin.x, y: self.map.frame.height, width: self.map.frame.width, height: mapFrame.height * Constants.Table.HeightMultiplier)

                self.tableConstraints.append(NSLayoutConstraint(item: self.tableView, attribute: .Bottom, relatedBy: .Equal, toItem: self.toolBar, attribute: .Top, multiplier: 1, constant: 0))
                self.view.addConstraints(self.tableConstraints)
                
                if self.view.needsUpdateConstraints() { self.view.updateConstraints() }
                self.takingSamples = true
                
            }
        }
    }
    
    func hideSampleTable()
    {
        if (tableView != nil) {
            UIView.animateWithDuration(Constants.Table.AnimationDuration) {
                self.tableView.removeFromSuperview()
                self.view.removeConstraints(self.tableConstraints)
                self.tableConstraints.removeAll(keepCapacity: true)
                self.view.addConstraint(self.mapToolBarConstraint)
                
                if self.view.needsUpdateConstraints() { self.view.updateConstraints() }
                self.tableView = nil
                self.toolBar.activate()
                self.takingSamples = false
            }
        }
        
    }
    

    private var _heatMapDict: NSMutableDictionary = NSMutableDictionary()
    
    // callback for steppers in sample table
    
    func stepperValueChanged(sender :UIStepper!)
    {
        if let stepper = sender as? CustomStepper {
            var s = sampler[stepper.sampleIndex]
            let point = s.point
            
            stepper.label.text! = "(\(nf.stringFromNumber(point.latitude)!),\(nf.stringFromNumber(point.longitude)!), \(sender.value))"
            sampler[stepper.sampleIndex].depth = sender.value
            
            stepper.annotation.weight = sender.value
            
            var mp = MKMapPointForCoordinate(point)
            
            // hack b/c we don't have @encode
            let obType = NSValue(MKCoordinate: point).objCType
            let pointValue = NSValue(bytes: &mp, objCType: obType)
            
            _heatMapDict.setObject(NSNumber(double: s.depth), forKey: pointValue)
        }
    }

    private var lastSelected : CustomAnnotation!
    private var tableView : UITableView! {
        didSet {
            tableView?.delegate = self
            tableView?.dataSource = self
        }
    }
    private var tableConstraints = [AnyObject]()
    

    // Function called when users selects a table row
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if let cell : UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)
        {
            // need to set bit on cell's annotation
            if let cCell = cell as? CustomTableCell {
                if (lastSelected != nil)
                {
                    map.removeAnnotation(lastSelected)
                    lastSelected.isSelected = false
                    map.addAnnotation(lastSelected)
                }
                cCell.annotation.isSelected = true
                map.removeAnnotation(cCell.annotation)
                map.addAnnotation(cCell.annotation)
                lastSelected = cCell.annotation
            }

            map.setCenterCoordinate(lastSelected.coordinate, animated: true)
        }
    }
    

    // MARK: UITableViewDataSource Functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampler.count
    }
    
    // function called to populate the table view
    let nf = NSNumberFormatter()

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->   UITableViewCell {
        
        if let cell: CustomTableCell = tableView.dequeueReusableCellWithIdentifier(indexPath.description) as? CustomTableCell
        {
            return cell
        }
        else
        {
            
            let label = UILabel(frame: CGRect(x:8, y:0, width:200, height:50))
            let sample = sampler[indexPath.item]
            let point = sample.point
            let cAnnotation = sampleAnnotations[indexPath.item] as CustomAnnotation
            let cell = CustomTableCell(annotation: cAnnotation, style: UITableViewCellStyle(rawValue: 0)!, reuseIdentified:indexPath.description)
            nf.maximumSignificantDigits = 5
            label.text = "(\(nf.stringFromNumber(point.latitude)!),\(nf.stringFromNumber(point.longitude)!), \(nf.stringFromNumber(sample.depth)!))"
            
            let stepper = CustomStepper(frame: CGRect(x:200, y:8, width:100, height:50), aLabel: label, index: indexPath.item,annotation: cAnnotation)
            
            stepper.autorepeat = true
            stepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: .ValueChanged)
            stepper.value = sample.depth
            cell.addSubview(label)
            cell.addSubview(stepper)
            
            if indexPath.item == 0 {
                var span = MKCoordinateSpanMake(0.001, 0.001)
                var region = MKCoordinateRegion(center: point, span: span)
                
                map.setRegion(region, animated: false)
            }
            return cell
        }
    }

    // MARK: Settings functions
    
    var hm : HeatMap!
    
    var heatMapOn : Bool = false {
        didSet {
            if heatMapOn {
                if hm == nil {
                    hm = HeatMap(data: _heatMapDict)
                }
                else {
                    map.removeOverlay(hm)
                    hm.setData(_heatMapDict)
                }
                map.addOverlay(hm)
            }
            else if hm != nil {
                map.removeOverlay(hm)
            }
        }
    }
    

    var annotationsOn : Bool = true {
        didSet {
            if annotationsOn {
                map.addAnnotations(sampleAnnotations)
            }
            else {
                map.removeAnnotations(sampleAnnotations)
            }
        }
    }
    
    var fieldOn : Bool = true {
        didSet {
            if fieldOn {
                map.addAnnotations(fieldAnnotations)
            }
            else {
                map.removeAnnotations(fieldAnnotations)
            }
        }
    }

    // MARK: MapView Delegate Functions
  
    
    @IBAction func addFieldCorner(sender: UILongPressGestureRecognizer) {
        
        if takingSamples { return }
        
        if sender.state == UIGestureRecognizerState.Began {
            let mapPoint : CLLocationCoordinate2D = map.convertPoint(sender.locationInView(map), toCoordinateFromView: map)
            
            var annotation = CustomAnnotation(index: sampler.addFieldPoint(mapPoint))
            
            annotation.isCorner = true
            annotation.setCoordinate(mapPoint)
            
            map.addAnnotation(annotation)
            fieldAnnotations.append(annotation)
            
        }
    }
    

    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        view.setSelected(true, animated: false)
    }
    
    func mapView(mapView: MKMapView!, viewForOverlay overlay: MKOverlay!) -> MKOverlayView! {
        return HeatMapView(overlay: overlay)
    }

    func mapView(mapView: MKMapView!,
        viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
    {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        if let a = annotation as? CustomAnnotation {
            
            if a.isCorner {
                var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("Corner") as? MKPinAnnotationView
                if pinView == nil {
                    let annotationView = CustomAnnotationView(annotation: a, reuseIdentifier: "Corner")
//                    annotationView.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as UIButton
//                    annotationView.canShowCallout = true
                    return annotationView
                }
                pinView?.annotation = a
                return pinView
            }

            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("StandardIdentifier") as? MKPinAnnotationView
            
            if (pinView == nil) {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "StandardIdentifier")
            }

            pinView!.pinColor = MKPinAnnotationColor.Red
            pinView!.animatesDrop = false
            if (a.isSelected) {
                pinView!.pinColor = MKPinAnnotationColor.Purple
            }
            return pinView
        }
        return nil
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState)
    {
        if newState == MKAnnotationViewDragState.Starting {
            view.image = UIImage(named: "draggable_icon_selected")
        }
        
        if newState == MKAnnotationViewDragState.Ending {
            if let ca = view.annotation as? CustomAnnotation
            {
                sampler.updateFieldPoint(ca.fieldIndex, coord: ca.coordinate)
            }
            view.dragState = MKAnnotationViewDragState.None;
            if sampler.field.count > 3 {
                self.doClearSample(nil)
                getSamplingPoints(self)
            }
            view.image = UIImage(named: "draggable_icon")
        }
        
    }
    
    func mapView(mapView: MKMapView!,
        didUpdateUserLocation userLocation: MKUserLocation!)
    {
        goToUserLocation(self)
    }
/*
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer!
    {
        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 4
            return polylineRenderer
        }
        return nil
    }
*/

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension UIToolbar {
    
    func activate() {
        for button in self.items as [UIBarButtonItem] {
            button.enabled = true
        }
    }
    
    func deActivate() {
        for button in self.items as [UIBarButtonItem] {
            button.enabled = false
        }
    }
}

