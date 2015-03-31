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
            static let Title = "Background Location Access Disabled"
            static let Message = "In order to use this app's full funtionality, please open this app's settings and set location access to 'Always'."
            static let Cancel = "Cancel"
            static let Open = "Open Settings"
        }
    }
    
    let _locationManager = CLLocationManager()
    var _fieldManager : FieldManager!
    var _map: MKMapView!
    var _viewController: UIViewController!
    
    init(fieldManager: FieldManager, aMap: MKMapView, aView: UIViewController)
    {
        super.init()
        _fieldManager = fieldManager
        _map = aMap
        _viewController = aView
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.requestWhenInUseAuthorization()
        
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
            _locationManager.startUpdatingLocation()
        case .NotDetermined: fallthrough
        case .AuthorizedWhenInUse, .Restricted, .Denied:
            let alertController = UIAlertController(
            title: Constants.Alert.Title,
            message: Constants.Alert.Message,
            preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: Constants.Alert.Cancel, style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: Constants.Alert.Open, style: .Default)
            {
                    (action) in
                    if let url = NSURL(string: UIApplicationOpenSettingsURLString)
                    {
                        UIApplication.sharedApplication().openURL(url)
                    }
            }
            
            alertController.addAction(openAction)
            
            aView.presentViewController(alertController, animated: true, completion: nil)
        default:
            _locationManager.requestWhenInUseAuthorization()

        }
    }
    
    var myLocations = [CLLocation]()
    var location: CLLocation = CLLocation(latitude: 0,longitude: 0)
    
    func locationManager(manager: CLLocationManager!,
        didUpdateLocations locations: [AnyObject]!)
    {
        
        let loc = locations as [CLLocation]
        let newLoc = loc[loc.endIndex-1]
        
        if (newLoc.horizontalAccuracy <= 10.0)
        {
            manager.stopUpdatingLocation()
        }
        
        location = newLoc
    }
    

    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        }
        
    }
}
