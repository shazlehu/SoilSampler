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

class ViewController: CenterViewController, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, MKMapViewDelegate, UITextFieldDelegate
{
// MARK: Properties
    
    let _fieldManager = FieldManager()

    // Editable field name title
    var _textField : UITextField! {
        didSet {
            _textField.textColor = UIColor.redColor()
            _textField.text = _fieldManager._currentField.name
            _textField.textAlignment = NSTextAlignment.Center
            _textField.clearButtonMode = UITextFieldViewMode.WhileEditing
            _textField.delegate = self
            
            self.navigationItem.titleView = _textField
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        _fieldManager.setFieldName(textField.text)
        textField.resignFirstResponder()
        _textField.textColor = UIColor.blackColor()
        return true
    }
    
    func newField()
    {
        _fieldManager.newField()
        self.doClear(nil)
        _textField.text = Constants.DefaultFieldTitle
        _textField.textColor = UIColor.redColor()
    }

    func deleteField(index: Int) -> Bool
    {
        if (_fieldManager.savedFields.count == 1)
        {
            let cancelAlert = UIAlertController(title: Constants.Alerts.CantDeleteLastField, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            cancelAlert.addAction(UIAlertAction(title: Constants.Alerts.OK, style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(cancelAlert, animated: true, completion: nil)
            return false
        }
        else {
            _fieldManager.deleteField(index)
            setCurrentField(_fieldManager._currentFieldIndex)
            return true
        }
    }
    
    @IBOutlet weak var _map: MKMapView! {
        didSet {
            _map.showsUserLocation = true
            _map.mapType = MKMapType.Hybrid
            _map.delegate = self
            var region = MKCoordinateRegion(center: _map.userLocation.coordinate, span: Constants.StartSpan)
            _map.setRegion(region, animated: false)
        }
    }

    var _locationManager: LocationManager!

    @IBOutlet weak var _randomOrGrid: UISegmentedControl!
    
    var sampleAnnotations = [AnyObject]()
    var fieldAnnotations = [AnyObject]()
    
    var mapToolBarConstraint : NSLayoutConstraint!
    // Editable title field
    

    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set constraint between toolbar and map so we can change it later
        
        mapToolBarConstraint = NSLayoutConstraint(item: _map, attribute: .Bottom, relatedBy: .Equal, toItem: toolBar, attribute: .Top, multiplier: 1, constant: 0)
        view.addConstraint(mapToolBarConstraint)
        if view.needsUpdateConstraints() { view.updateConstraints() }
        _locationManager = LocationManager(fieldManager: self._fieldManager, aMap: self._map, aView: self)
        
        _textField = UITextField(frame: CGRectMake(0, 0, 200, 22))
        addAnnotationsForCurrentField()
    }

    func addAnnotationsForCurrentField()
    {
        // place any annotations saved in the current field
        for (var i = 0; i < _fieldManager._currentField.corners.count; i++) {
            addFieldCorner(_fieldManager._currentField.corners[i], fieldIndex: i)
        }
        
        for var i = 0; i < _fieldManager._currentField.samples.count; i++ {
            
            var annotation = CustomAnnotation(index: i)
            
            annotation.setCoordinate(_fieldManager._currentField.samples[i].point)
            annotation.isCorner = false
            
            _map.addAnnotation(annotation)
            sampleAnnotations.append(annotation)
        }

    }
    func setCurrentField(index: Int)
    {
        hideSampleTable()
        heatMapOn = false
        _fieldManager._currentFieldIndex = index
        _map.removeAnnotations(sampleAnnotations)
        _map.removeAnnotations(fieldAnnotations)
        sampleAnnotations.removeAll(keepCapacity: true)
        fieldAnnotations.removeAll(keepCapacity: true)
        
        addAnnotationsForCurrentField()
        _textField.text = _fieldManager._currentField.name
        _textField.textColor = UIColor.blackColor()
        
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
        annotationsOn = false
        fieldOn = false
        heatMapOn = false
        
        sampleAnnotations.removeAll(keepCapacity: true)
        fieldAnnotations.removeAll(keepCapacity: true)

        _fieldManager.clear()
        hideSampleTable()
        
        self.navigationItem.title = Constants.Title
    }
    
    
    // Clear only sample, not the field
    func doClearSample(action: UIAlertAction!)
    {
        annotationsOn = false
        heatMapOn = false
        
        sampleAnnotations.removeAll(keepCapacity: true)
        _fieldManager.clearSample()
        hideSampleTable()

        self.navigationItem.title = Constants.ClearedTitle
        
    }


    @IBAction func changeSampleNumber(sender: UIStepper) {
        _fieldManager.sampleDensity = Int(sender.value)
        self.doClearSample(nil)
        getSamplingPoints(self)
    }
    
    
    @IBAction func shareFile(sender: AnyObject) {
        
        let objectsToShare = [Constants.ShareMessage, _fieldManager.saveCurrentField()!]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

        // New Excluded Activities Code

        
        activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList, UIActivityTypeMessage,
            UIActivityTypeCopyToPasteboard]
        
        activityVC.title = Constants.ShareTitle
        self.presentViewController(activityVC, animated: true, completion: nil)

    }

    @IBAction func goToUserLocation(sender: AnyObject) {
        let region = MKCoordinateRegion(center: _map.userLocation.coordinate, span: Constants.DefaultSpan)
        _map.setRegion(region, animated: true)
    }
    
    func goToLocation(location: CLLocationCoordinate2D)
    {
        if CLLocationCoordinate2DIsValid(location){
            let region = MKCoordinateRegion(center: location, span: Constants.DefaultSpan)
            _map.setRegion(region, animated: false)
        }
        else {
            askForNewLocation(Constants.GoToAlert.ErrorTitle)
        }
    }

    
    func askForNewLocation(withTitle: String)
    {
        let gotoAlert = UIAlertController(title: withTitle, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let setAction = UIAlertAction(title: Constants.GoToAlert.Go, style: .Default)
            { [unowned self] (_) in
                let latitudeTextField = gotoAlert.textFields![0] as UITextField
                let longitudeTextField = gotoAlert.textFields![1] as UITextField
                
                if let lat = self.nf.numberFromString(latitudeTextField.text!) {
                    if let lon = self.nf.numberFromString(longitudeTextField.text!) {
                        let loc = CLLocationCoordinate2D(
                            latitude: lat.doubleValue,
                            longitude: lon.doubleValue)
                        self.goToLocation(loc)
                    }
                }
        }
        
        gotoAlert.addTextFieldWithConfigurationHandler
            { (textField) in
                textField.keyboardType = UIKeyboardType.DecimalPad
                textField.placeholder = "Latitude"
        }
        //{ (textField) in
        //            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
        //                setAction.enabled = textField.text != ""
        //            }
        //        }
        //
        gotoAlert.addTextFieldWithConfigurationHandler
            { (textField) in
                textField.keyboardType = UIKeyboardType.DecimalPad
                textField.placeholder = "Longitude"
        }
        
        gotoAlert.addAction(setAction)
        gotoAlert.addAction(UIAlertAction(title: Constants.Alerts.Cancel, style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(gotoAlert, animated: true, completion: nil)
        
    }
    
    func askForNewLocation()
    {
        askForNewLocation(Constants.GoToAlert.Title)
    }
    
    @IBAction func getSamplingPoints(sender: AnyObject) {
        doClearSample(nil)
        
        if let points = _fieldManager.generateTestPoints(_randomOrGrid.selectedSegmentIndex == 1) {
        
            for var i = 0; i < points.count; i++ {
            
                var annotation = CustomAnnotation(index: i)
        
                annotation.setCoordinate(points[i].point)
                annotation.isCorner = false
                
                _map.addAnnotation(annotation)
                sampleAnnotations.append(annotation)
            }
// This no longer works
//            self.navigationItem.title = "Samples: \(points.count)"
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
        if _fieldManager.count == 0 {
            let fieldAlert = UIAlertController(title: Constants.Alerts.DefineFieldAndSample, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            
            fieldAlert.addAction(UIAlertAction(title: Constants.Alerts.OK, style: UIAlertActionStyle.Default, handler: nil))
            
            self.presentViewController(fieldAlert, animated: true, completion: nil)
            
        }
        else if tableView == nil {
            let mapFrame = self._map.frame

            self.toolBar.deActivate()
            UIView.animateWithDuration(Constants.Table.AnimationDuration) {
                self.tableView = UITableView(frame: CGRect(x: self._map.frame.origin.x, y: self._map.frame.height, width: self._map.frame.width, height: mapFrame.height * Constants.Table.HeightMultiplier))
                
                self._map.frame = CGRect(x: self._map.frame.origin.x, y: self._map.frame.origin.y, width: self._map.frame.width, height: self._map.frame.height * Constants.Table.MapHeightMultiplier)

                self.view.addSubview(self.tableView)
                
                self.tableView.frame = CGRect(x: self._map.frame.origin.x, y: self._map.frame.height, width: self._map.frame.width, height: mapFrame.height * Constants.Table.HeightMultiplier)

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

    // callback for steppers in sample table
    
    func stepperValueChanged(sender :UIStepper!)
    {
        if let stepper = sender as? CustomStepper {
            let point = _fieldManager[stepper.sampleIndex].point
            
            stepper.label.text! = "(\(nf.stringFromNumber(point.latitude)!),\(nf.stringFromNumber(point.longitude)!), \(sender.value))"
            _fieldManager[stepper.sampleIndex].depth = sender.value
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
                    _map.removeAnnotation(lastSelected)
                    lastSelected.isSelected = false
                    _map.addAnnotation(lastSelected)
                }
                cCell.annotation.isSelected = true
                _map.removeAnnotation(cCell.annotation)
                _map.addAnnotation(cCell.annotation)
                lastSelected = cCell.annotation
            }

            _map.setCenterCoordinate(lastSelected.coordinate, animated: true)
        }
    }
    

    // MARK: UITableViewDataSource Functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _fieldManager.count
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
            let sample = _fieldManager[indexPath.item]
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
                
                _map.setRegion(region, animated: false)
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
                    hm = HeatMap(data: _fieldManager._currentField.heatMapDict)
                }
                else {
                    _map.removeOverlay(hm)
                    hm.setData(_fieldManager._currentField.heatMapDict)
                }
                _map.addOverlay(hm)
            }
            else if hm != nil {
                _map.removeOverlay(hm)
            }
        }
    }
    

    var annotationsOn : Bool = true {
        didSet {
            if annotationsOn {
                _map.addAnnotations(sampleAnnotations)
            }
            else {
                _map.removeAnnotations(sampleAnnotations)
            }
        }
    }
    
    var fieldOn : Bool = true {
        didSet {
            if fieldOn {
                _map.addAnnotations(fieldAnnotations)
            }
            else {
                _map.removeAnnotations(fieldAnnotations)
            }
        }
    }

    // MARK: MapView Delegate Functions
  
    func addFieldCorner(coord: CLLocationCoordinate2D, fieldIndex: Int)
    {
        var annotation = CustomAnnotation(index: fieldIndex)
        
        annotation.isCorner = true
        annotation.setCoordinate(coord)
        
        _map.addAnnotation(annotation)
        fieldAnnotations.append(annotation)
 
    }
    
    @IBAction func addFieldCorner(sender: UILongPressGestureRecognizer)
    {
        if takingSamples { return }
        
        if sender.state == UIGestureRecognizerState.Began {
            let coord : CLLocationCoordinate2D = _map.convertPoint(sender.locationInView(_map), toCoordinateFromView: _map)
            let index = _fieldManager.addFieldPoint(coord)
            addFieldCorner(coord, fieldIndex: index)
            if index >= 2 { // index >= 2 means we have three points
                getSamplingPoints(self)
            }
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
                _fieldManager.updateFieldPoint(ca.fieldIndex, coord: ca.coordinate)
            }
            view.dragState = MKAnnotationViewDragState.None;
            if _fieldManager._currentField.corners.count > 3 {
                self.doClearSample(nil)
                getSamplingPoints(self)
            }
            view.image = UIImage(named: "draggable_icon")
        }
        
    }
    
    private var hasSetUserLocation = false
    func mapView(mapView: MKMapView!,
        didUpdateUserLocation userLocation: MKUserLocation!)
    {
        if (!hasSetUserLocation) { goToUserLocation(self) }
        hasSetUserLocation = true
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
    
    // MARK: Constants
    private struct Constants {
        static let DefaultSpan = MKCoordinateSpanMake(0.001, 0.001)
        static let StartSpan = MKCoordinateSpanMake(90,180)
        static let DefaultFieldTitle = "Tap Here to name field"
        struct Alerts {
            static let CantDeleteLastField = "You must have at least one field."
            static let Title = "Really delete sample points?"
            static let FieldSample = "Delete field and sample"
            static let SampleOnly = "Delete sample"
            static let Cancel = "Cancel"
            static let DefineField = "Please tap the map to mark field corners."
            static let DefineFieldAndSample = "Please tap the map to mark field corners, use the +/- buttons to generate samples."
            static let OK = "Ok"
        }
        struct GoToAlert {
            static let Title = "Go to location:"
            static let ErrorTitle = "Latitude must be from -90 to 90, Longitude -180 to 180"
            static let Go = "Go"
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

