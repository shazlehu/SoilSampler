//
//  LocationManager.swift
//  MapTest
//
//  Created by Samuel Hazlehurst on 2/20/15.
//  Copyright (c) 2015 Terranian Farm. All rights reserved.
//

import CoreLocation
import MapKit

class LocationManager: NSObject, CLLocationManagerDelegate {
  
     struct Constants {
         struct Alert {
            static let Title = "Location Access Disabled"
            static let Message = "In order to use this app's full funtionality, please open this app's settings and set location access to 'While Using'."
            static let Cancel = "Cancel"
            static let Open = "Open Settings"
            static let OK = "Ok"
            static let DeniedTitle = "Location Access Restricted"
            static let DeniedMessage = "This phone has its Location Services restricted, Soil Sampler Pro will have limited usability."
        }
        static let AccuracyThreshold = 10.0
    }
    let _locationManager = CLLocationManager()
    var _fieldManager : FieldManager!
    var _map: MKMapView!
    var _viewController: UIViewController!

    var locationStatus : CLAuthorizationStatus = .NotDetermined

    init(fieldManager: FieldManager, aMap: MKMapView, aView: UIViewController)
    {
        super.init()
        _fieldManager = fieldManager
        _map = aMap
        _viewController = aView
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.requestWhenInUseAuthorization()
    }
    
    var myLocations = [CLLocation]()
    var location: CLLocation = CLLocation(latitude: 0,longitude: 0)
    
    func locationManager(manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation])
    {
        
        let loc = locations as [CLLocation]
        let newLoc = loc[loc.endIndex-1]
        
        if (newLoc.horizontalAccuracy <= Constants.AccuracyThreshold)
        {
            manager.stopUpdatingLocation()
        }
        
        location = newLoc
    }
    

    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        locationStatus = status
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            _locationManager.startUpdatingLocation()
        case .Denied:
            let alertController = UIAlertController(
                title: Constants.Alert.Title,
                message: Constants.Alert.Message,
                preferredStyle: .Alert)
            
            alertController.addAction(UIAlertAction(title: Constants.Alert.Cancel, style: .Cancel, handler: nil))
            
            let openAction = UIAlertAction(title: Constants.Alert.Open, style: .Default)
                {
                    (action) in
                    if let url = NSURL(string: UIApplicationOpenSettingsURLString)
                    {
                        UIApplication.sharedApplication().openURL(url)
                    }
            }
            
            alertController.addAction(openAction)
            
            _viewController.presentViewController(alertController, animated: true, completion: nil)
        case .Restricted:
            let alertController = UIAlertController(
                title: Constants.Alert.DeniedTitle,
                message: Constants.Alert.DeniedMessage,
                preferredStyle: .Alert)
            
            alertController.addAction(
                UIAlertAction(
                    title: Constants.Alert.OK,
                    style: .Cancel, handler: nil))
        case .NotDetermined: fallthrough
        default: break
        }
    }
    
    func setAccuracy(high: Bool)
    {
        if high {
            _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        }
        else {
            _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
}
