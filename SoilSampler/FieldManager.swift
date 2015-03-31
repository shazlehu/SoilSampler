//
//  SamplerTester.swift
//  MapTest
//
//  Created by Samuel Hazlehurst on 2/19/15.
//  Copyright (c) 2015 Terranian Farm. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
//import CoreData


public func arc4random <T: IntegerLiteralConvertible> (type: T.Type) -> T {
    var r: T = 0
    arc4random_buf(&r, UInt(sizeof(T)))
    return r
}

public extension Double {
    /**
    Create a random num Double
    :param: lower number Double
    :param: upper number Double
    :return: random number Double
    By DaRkDOG
    */
    public static func random(#lower: Double, upper: Double) -> Double {
        let r = Double(arc4random(UInt64)) / Double(UInt64.max)
        return (r * (upper - lower)) + lower
    }
}

public extension CLLocationCoordinate2D {
    var length : Double {
        get {return sqrt(self.latitude * self.latitude + self.longitude * self.longitude)}
    }
}

class Sample : Printable {
    var point : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0,longitude: 0)
    var depth : Double = 0.0
    
    init(point: CLLocationCoordinate2D, depth: Double)
    {
        self.point = point
        self.depth = depth
    }
    
    var description : String {
        get {
            return "Sample,\(point.latitude),\(point.longitude),\(depth)"
        }
    }
}

extension CLLocationCoordinate2D : Printable {
    public var description : String {
        get {
            return "Corner,\(latitude),\(longitude),0.0"
        }
    }
}

struct Field {
    var name: String = "Unnamed"
    var samples = [Sample]()
    var corners = [CLLocationCoordinate2D]()
}

class FieldManager {
    
    var savedFields = [Field]()

    // current field properties
//    var field = [CLLocationCoordinate2D]()
    var _currentField = Field()
//    private var samplePoints = [Sample]()
    var count : Int { get { return _currentField.samples.count } }
    
    var annotations = [AnyObject]()
    var sampleDensity: Int = 10
    var fileName = "log.csv"
    
    subscript(index: Int) -> Sample {
        get {
            return _currentField.samples[index]
        }
        set (newValue) {
            _currentField.samples[index] = newValue
        }
    }
    
    func newField()
    {
        writeFile()
        _currentField = Field()
        savedFields.append(_currentField)
    }
    
    func setFieldName(name: String)
    {
        // need to check if name's already taken
        _currentField.name = name
    }

    func addFieldPoint(p : CLLocationCoordinate2D) -> Int {
        _currentField.corners.append(p)
        return _currentField.corners.count - 1
    }
    
    func updateFieldPoint(index: Int, coord: CLLocationCoordinate2D)
    {
        _currentField.corners[index] = coord
    }
    
    func clear() {
        _currentField.corners.removeAll(keepCapacity: true)
        _currentField.samples.removeAll(keepCapacity: true)
    }

    func clearSample() {
        _currentField.samples.removeAll(keepCapacity: true)
    }
    
    func getSampleCoords () -> [CLLocation] {
        var coords = [CLLocation]()
        for s in _currentField.samples {
            coords.append(CLLocation(latitude: s.point.latitude, longitude: s.point.longitude))
        }
        return coords
    }
    
    func getDepths() -> [NSNumber] {
        var depths = [NSNumber]()
        for s in _currentField.samples {
            depths.append(NSNumber(double: s.depth))
        }
        return depths
    }
    
    private var fileurl : NSURL! = nil
    
    
    // File is CSV of the format PointType = {Corner, Sample}, Latitude, Longitude, depth
    
    enum PointType : Printable {
        case Corner
        case Sample
        var description : String {
            get {
                switch self {
                case .Corner :
                    return "Corner"
                case .Sample :
                    return "Sample"
                }
            }
        }
    }
    
    func loadFieldsFromFile(named: String)
    {
        let dir : NSURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last as NSURL
        var err:NSError?
        if let files = NSFileManager.defaultManager().contentsOfDirectoryAtURL(dir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, error: &err) as? [NSURL] {

            for (var i = 0; i < files.count; i++) {
                
                var fieldName = files[i].lastPathComponent?.stringByDeletingPathExtension
                fileurl =  dir.URLByAppendingPathComponent(named + ".csv")
                if let fileHandle = NSFileHandle(forWritingToURL: fileurl, error: &err) {
                    let data = NSString(data: fileHandle.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) as String
                    
                    // read line by line
                    savedFields[i] = Field()
                    let lines = data.componentsSeparatedByString("\n")
                    
                    // first line is date
                    for (var j = 1; j < lines.count; j++) {
                        let sampleVals = lines[j].componentsSeparatedByString(",")
                        
                        switch sampleVals[0] {
                        case "Corner":
                            savedFields[i].corners.append(
                                CLLocationCoordinate2D(
                                    latitude: (sampleVals[1] as NSString).doubleValue,
                                    longitude: (sampleVals[2] as NSString).doubleValue))
                        case "Sample":
                            savedFields[i].samples.append(
                                Sample(
                                    point : CLLocationCoordinate2D(
                                        latitude: (sampleVals[1] as NSString).doubleValue,
                                        longitude: (sampleVals[2] as NSString).doubleValue),
                                    depth: 0.0 as Double))
                                                default:
                            NSLog("Unknown type in saved field file!")
                        }
                    }
                    
                    fileHandle.closeFile()
                }
                else {
                    NSLog("Can't open fileHandle \(err)")
                }

            }
        }
    }
    
    func writeFile() -> NSURL
    {
        
        let dir : NSURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last as NSURL
        var err:NSError?
        let files = NSFileManager.defaultManager().contentsOfDirectoryAtURL(dir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, error: &err) as? [NSURL]
        
        fileurl =  dir.URLByAppendingPathComponent("\(_currentField.name).csv")
        
        var string : String = "\(NSDate())\n"
      
        for c in _currentField.corners {
            string += "\(c.description)\n"
        }
        for s in _currentField.samples {
            string += "\(s.description)\n"
        }
        
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        if NSFileManager.defaultManager().fileExistsAtPath(fileurl.path!) {
            var err:NSError?
            if let fileHandle = NSFileHandle(forWritingToURL: fileurl, error: &err) {
//                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }
            else {
                NSLog("Can't open fileHandle \(err)")
            }
        }			
        else {
            var err:NSError?
            if !data.writeToURL(fileurl, options: .DataWritingAtomic, error: &err) {
                NSLog("Can't write \(err)")
            }
        }
        return fileurl
    }
    
    
    
    /*
    
        algorithm works by generating a point in the bounding rectangle, then checking if it's in the polygon.
    
    */
    
    func distance(a: CLLocationCoordinate2D, b:CLLocationCoordinate2D) -> Double {
        return sqrt((a.latitude - b.latitude)*(a.latitude - b.latitude) +
            (a.longitude - b.longitude)*(a.longitude - b.longitude))
    }
    func getSlope(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> Double {
        return (end.latitude - start.latitude)/(end.longitude - start.longitude)
    }
    
    func findLongestSide(isVertical: Bool) -> (start: CLLocationCoordinate2D, end: CLLocationCoordinate2D)
    {
        var candidateSides = [(CLLocationCoordinate2D,CLLocationCoordinate2D)]()
        for (var i = 0; i < _currentField.corners.count - 1; i++) {
            let slope = abs(getSlope(_currentField.corners[i], end: _currentField.corners[i+1]))
            if (slope > 1) && isVertical {
                candidateSides.append((_currentField.corners[i], _currentField.corners[i+1]))
            }
            else if (slope < 1) && !isVertical {
                candidateSides.append((_currentField.corners[i], _currentField.corners[i+1]))
            }
        }
        
        if abs(getSlope(_currentField.corners.last!, end: _currentField.corners.first!)) > 1 {
            candidateSides.append((_currentField.corners.last!, _currentField.corners.first!))
        }
        
        if (candidateSides.isEmpty == true) { return (_currentField.corners[0],_currentField.corners[1]) }
        var longestSide = candidateSides[0]
        for side in candidateSides {
            if (distance(side.0, b: side.1) > distance(longestSide.0, b: longestSide.1)) {
                longestSide = side
            }
        }
        return longestSide
        
    }
    
    func findLongestLongitudeSide() -> (start: CLLocationCoordinate2D, end: CLLocationCoordinate2D)?
    {
        return findLongestSide(false)
    }
    
    func findLongestLatitudeSide() -> (start: CLLocationCoordinate2D, end: CLLocationCoordinate2D)? {
        return findLongestSide(true)
    }
    
    // y = mx + b
    // x = (y - b) / m

    func getXaxisFunc(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> (Double) -> Double
    {
        let slope = (end.latitude - start.latitude)/(end.longitude - start.longitude)
        let xIntercept = start.latitude - slope * start.longitude

        return { (slope * $0 + xIntercept) - start.latitude}
    }
    
    func getYaxisFunc(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> (Double) -> Double
    {
        let slope = (end.latitude - start.latitude)/(end.longitude - start.longitude)
        let xIntercept = start.latitude - slope * start.longitude
        
        return {($0 - xIntercept) / slope  - start.longitude}
    }


    func generateTestPoints(isRandom : Bool) -> [Sample]?
    {
        // check is we have a polygon
        
        if _currentField.corners.count < 3 { return nil }
        
        // find bounding rectangle
        
        var min = CLLocationCoordinate2D(latitude: _currentField.corners[0].latitude, longitude: _currentField.corners[0].longitude)
        var max = CLLocationCoordinate2D(latitude: _currentField.corners[0].latitude, longitude: _currentField.corners[0].longitude)
        
        for p in _currentField.corners {
            if p.latitude > max.latitude { max.latitude = p.latitude }
            if p.longitude > max.longitude { max.longitude = p.longitude }
            if p.latitude < min.latitude { min.latitude = p.latitude }
            if p.longitude < min.longitude { min.longitude = p.longitude }
        }
        
        // algorithm from http://www.codeproject.com/Tips/84226/Is-a-Point-inside-a-Polygon
        
        func pointInPolygon(point: CLLocationCoordinate2D, polygon poly: [CLLocationCoordinate2D]) -> Bool
        {
            var c : Bool = false
            
            for var i = 0, j = poly.count - 1; i < _currentField.corners.count; j = i++ {
                if (((poly[i].longitude > point.longitude) !=
                    (poly[j].longitude > point.longitude)) &&
                    (point.latitude < (poly[j].latitude - poly[i].latitude) *
                        (point.longitude-poly[i].longitude) /
                        (poly[j].longitude - poly[i].longitude) + poly[i].latitude) )
                {
                    c = !c
                }
            }
            return c
        }
        
        var totalTestPoints = 0
        
        let side = sqrt(Double(sampleDensity))
        let deltaLat = (max.latitude - min.latitude) / side
        let deltaLong = (max.longitude - min.longitude) / side
        
        // get functions to make points parallel to the longest vertical and horizontal sides
        
        var (start,end) = findLongestLatitudeSide()!
        
        let longFunc = getYaxisFunc(start, end: end)
        
        (start,end) = findLongestLongitudeSide()!
        let latFunc = getXaxisFunc(start, end: end)
        
        for var i = 0; i < Int(side) + 1; i++ {
            
            var rowLength = 0 // count of how many points lie in the polygon
            for var j = 0; j < Int(side) + 1; j++ {

                var p = CLLocationCoordinate2D(latitude: min.latitude + deltaLat * Double(i), longitude: min.longitude + deltaLong * Double(j))
                
                if (isRandom) { // add random variance
                    p.latitude += Double.random(lower: -deltaLat/4, upper: deltaLat/4)
                    p.longitude += Double.random(lower: -deltaLong/4, upper: deltaLong/4)
                }
                
                // adjust for skewed sides
                p.longitude += longFunc(p.latitude)
                p.latitude += latFunc(p.longitude)
                
                if pointInPolygon(p, polygon: _currentField.corners) {
                    _currentField.samples.append(Sample(point: p, depth: 0))
                    rowLength++
               }
            }

            // reverse every other row for efficient traversal
            if (i % 2 == 1) && (rowLength > 1)
            {
                let end = _currentField.samples.endIndex - 1
                let start = end - rowLength + 1
                let reverseRow = _currentField.samples[start...end].reverse()
                _currentField.samples.replaceRange(start...end, with: reverseRow)
            }
        }
        return _currentField.samples
    }
    
    /*
    var cdField = Field()
    
    func saveToCoreData()
    {
    if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
    if let context = appDelegate.managedObjectContext {
    
    //cdField.corners = NSSet(array: field as [AnyObject])
    
    //                for sample in samplePoints {
    //                    var newSample = NSEntityDescription.insertNewObjectForEntityForName("Sample",inManagedObjectContext: context) as NSManagedObject
    //                    newSample.setValue(sample.point.latitude, forKey: "latitude")
    //                    newSample.setValue(sample.point.longitude, forKey: "longitude")
    
    //                }
    context.save(nil)
    }
    }
    }
    
    func loadFromCoreData()
    {
    if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
    if let context = appDelegate.managedObjectContext {
    let request = NSFetchRequest(entityName: "Sample")
    }
    }
    
    }
    */
}