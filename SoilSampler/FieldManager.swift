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
    arc4random_buf(&r, Int(sizeof(T)))
    return r
}

public extension Double {
    /**
    Create a random num Double
    - parameter lower: number Double
    - parameter upper: number Double
    :return: random number Double
    By DaRkDOG
    */
    public static func random(lower lower: Double, upper: Double) -> Double {
        let r = Double(arc4random(UInt64)) / Double(UInt64.max)
        return (r * (upper - lower)) + lower
    }
}

public extension CLLocationCoordinate2D {
    var length : Double {
        get {return sqrt(self.latitude * self.latitude + self.longitude * self.longitude)}
    }
}

class Sample : CustomStringConvertible {
    
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

extension CLLocationCoordinate2D : CustomStringConvertible {
    public var description : String {
        get {
            return "Corner,\(latitude),\(longitude),0.0"
        }
    }
}
struct FieldConstants {
    static let DefaultName = "Untitled"
}

class Field {
    
    var name: String!
    
    var title: String {
        return name.componentsSeparatedByString("/").last!
    }
    
    var samples = [Sample]()
    var corners = [CLLocationCoordinate2D]()
    var date = NSDate()
    var isEditable : Bool = true
    
    init(named: String) {
        NSLog(named)
        name = named
    }
    /*
    var heatMapDict: NSMutableDictionary {
        get {
            let hmDict = NSMutableDictionary()
            for s in samples {
                var mp = MKMapPointForCoordinate(s.point)

                // hack b/c we don't have @encode
                let obType = NSValue(MKCoordinate: s.point).objCType
                let pointValue = NSValue(bytes: &mp, objCType: obType)
            // should the heat map dictionary belong to the Field object?
                hmDict.setObject(NSNumber(double: s.depth), forKey: pointValue)
            }
            return hmDict
        }
    }
*/
    var heatMapDict: [MKMapPoint:Float] {
        get {
            var hmDict = [MKMapPoint:Float]()
            for s in samples {
                let mp = MKMapPointForCoordinate(s.point)
                
                hmDict[mp] = Float(s.depth)
            }
            return hmDict
        }
    }

}

class FieldManager {
    
    var savedFields = [Field]()

    private var _currentFieldIndex :Int = 0
    var currentFieldIndex : Int {
        get {
            return _currentFieldIndex
        }
        set {
            if newValue > savedFields.endIndex {
                _currentFieldIndex = savedFields.endIndex - 1
            }
            else if newValue < 0 {
                _currentFieldIndex = 0
            }
            else {
                _currentFieldIndex = newValue
            }
        }
    }
    
    var _currentField: Field {
        get {
            if _currentFieldIndex > savedFields.count {
                return savedFields.last!
            }
            return savedFields[_currentFieldIndex]
        }
    }

    var count : Int { get { return _currentField.samples.count } }
    
    var annotations = [AnyObject]()
    var sampleDensity: Int = 10
    
    subscript(index: Int) -> Sample {
        get {
            return _currentField.samples[index]
        }
        set (newValue) {
            _currentField.samples[index] = newValue
        }
    }
    let dateFormatter = NSDateFormatter()
    
    init()
    {
        dateFormatter.timeStyle = NSDateFormatterStyle.FullStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.FullStyle
        
        loadFieldsFromFile()
        if savedFields.count == 0 {
            savedFields.append(Field(named: FieldConstants.DefaultName))
        }
    }
    
    
    func newField()
    {
        saveCurrentField()
        let names = savedFields.map {
            (f: Field) -> String in
            return f.name
        }
        
        var newName : String = FieldConstants.DefaultName
        var suffix = 1
        while ((names.filter {$0 == newName}).count > 0) {
            newName = FieldConstants.DefaultName + "-\(suffix+=1)"
        }
        
        savedFields.append(Field(named: newName))
        currentFieldIndex = savedFields.endIndex - 1
    }
    
    func deleteField(index: Int)
    {
        // delete file
        let fileManager = NSFileManager.defaultManager()
        let dir : NSURL? = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last
        var err:NSError?
        let fileURL =  dir!.URLByAppendingPathComponent("\(savedFields[index].name).csv")
        
        if fileManager.fileExistsAtPath(fileURL.path!) {
            do {
                // delete old file
                try fileManager.removeItemAtURL(fileURL)
            } catch let error as NSError {
                err = error
            }
        }
        
        if (err != nil)
        {
            NSLog(err!.localizedDescription)
        }
        
        // delete in array
        savedFields.removeAtIndex(index)
        
        if currentFieldIndex >= index {
            currentFieldIndex -= 1
        }

    }
    
    func setFieldName(name: String)
    {
        // need to check if name's already taken
        // need to delete old file.
        deleteFieldNamed(_currentField.title)
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
    
    
    // File is CSV of the format PointType = {Corner, Sample}, Latitude, Longitude, depth
    
    enum PointType : CustomStringConvertible {
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

    func loadFieldsFromFile()
    {
        let fileManager = NSFileManager.defaultManager()
        let dir : NSURL? = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last

        do {
            
            let files = try fileManager.contentsOfDirectoryAtURL(dir!,  includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            for i in 0 ..< files.count {
                do {
                    let fileHandle = try NSFileHandle(forReadingFromURL: files[i])
                    let data = NSString(data: fileHandle.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) as! String
                    // read line by line
                    if let name = files[i].URLByDeletingPathExtension {
                        savedFields.append(Field(named: name.absoluteString))
                    }
                    
                    // tokenize by newline "\n"
                    let lines = data.componentsSeparatedByString("\n")
                    
                    // first line is date
                    if let date = dateFormatter.dateFromString(lines[0]) {
                        savedFields[i].date = date
                    }
                    
                    for j in 1 ..< lines.count {
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
                                    depth: (sampleVals[3] as NSString).doubleValue))
                        default:
                            break
                        }
                        let nonZeroSamples = savedFields[i].samples.map {
                            (sample : Sample) -> Bool in sample.depth > 0
                        }
                        savedFields[i].isEditable = (nonZeroSamples.count == 0)
                    }
                    fileHandle.closeFile()
                } catch let error as NSError {
                    NSLog("Can't open fileHandle \(error)")
                }
            }
            // sort files by date
            self.savedFields.sortInPlace({($0 as Field).date.compare(($1 as Field).date) == NSComparisonResult.OrderedAscending })
        } catch let error as NSError {
            NSLog("Can't load fields: \(error)")
        }
    }
    
    func deleteFieldNamed(name: String)
    {
        let fileManager = NSFileManager.defaultManager()
        
        let dir : NSURL = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last! as NSURL
  
        let fileURL =  dir.URLByAppendingPathComponent("\(name).csv")
        
        do {
            try fileManager.removeItemAtURL(fileURL)
        } catch let error as NSError {
            NSLog("Can't delete \(fileURL) because \(error)")
        }

    }

    func saveAllFields() -> [NSURL]
    {
        var returnURLS = [NSURL]()
        for field in savedFields {
            returnURLS.append(saveField(field)!)
        }
        return returnURLS
    }
    
    func saveField(field: Field) -> NSURL?
    {
        let fileManager = NSFileManager.defaultManager()

        let dir : NSURL = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last! as NSURL
        var err:NSError?
        let fileURL =  dir.URLByAppendingPathComponent("\(field.title).csv")
        
        // date at top of the file
        var string = dateFormatter.stringFromDate(field.date) + "\n"

        for c in field.corners {
            string += "\(c.description)\n"
        }
        for s in field.samples {
            string += "\(s.description)\n"
        }
        
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            
            if fileManager.fileExistsAtPath(fileURL.path!) {
                do {
                    // delete old file
                    try fileManager.removeItemAtURL(fileURL)
                } catch let error as NSError {
                    err = error
                }
            }
            do {
                try data.writeToURL(fileURL, options: .DataWritingAtomic)
            } catch let error as NSError {
                err = error
                NSLog("Can't write \(err)")
                return nil
            }
        }
        return fileURL
    }
    
    func saveCurrentField() -> NSURL?
    {
        return saveField(_currentField)
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
        for i in 0 ..< _currentField.corners.count - 1 {
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


    var sortedCorners: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
    func generateTestPoints(isRandom : Bool) -> [Sample]?
    {
        // check if we have a polygon
        
        if _currentField.corners.count < 3 { return nil }
        
        // find bounding rectangle
        
        var min = CLLocationCoordinate2D(latitude: _currentField.corners[0].latitude, longitude: _currentField.corners[0].longitude)
        var max = CLLocationCoordinate2D(latitude: _currentField.corners[0].latitude, longitude: _currentField.corners[0].longitude)
        
        var center = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        for p in _currentField.corners {
            center.latitude += p.latitude
            center.longitude += p.longitude
            if p.latitude > max.latitude { max.latitude = p.latitude }
            if p.longitude > max.longitude { max.longitude = p.longitude }
            if p.latitude < min.latitude { min.latitude = p.latitude }
            if p.longitude < min.longitude { min.longitude = p.longitude }
        }
        
        
        center.latitude /= Double(_currentField.corners.count)
        center.longitude /= Double(_currentField.corners.count)
        
        // sort corners around center point
        
//        let center = CLLocationCoordinate2D(
//                        latitude: (max.latitude + min.latitude) / 2,
//                        longitude: (max.longitude + min.longitude) / 2)
        
        sortedCorners = _currentField.corners.sort {
            (a, b) in
            if (a.latitude - center.latitude >= 0 && b.latitude - center.latitude < 0) {
                return true
            }
            if (a.latitude - center.latitude < 0 && b.latitude - center.latitude >= 0) {
                return false
            }
            if (a.latitude - center.latitude == 0 && b.latitude - center.latitude == 0) {
                if (a.longitude - center.longitude >= 0 || b.longitude - center.longitude >= 0) {
                    return a.longitude > b.longitude
                }
                return b.longitude > a.longitude;
            }
            
            // compute the cross product of vectors (center -> a) x (center -> b)
            let det = (a.latitude - center.latitude) * (b.longitude - center.longitude) - (b.latitude - center.latitude) * (a.longitude - center.longitude)
            if (det < 0) {
                return true
            }
            if (det > 0) {
                return false
            }
            
            // points a and b are on the same line from the center
            // check which point is closer to the center
            let d1 = (a.latitude - center.latitude) * (a.latitude - center.latitude) + (a.longitude - center.longitude) * (a.longitude - center.longitude)
            let d2 = (b.latitude - center.latitude) * (b.latitude - center.latitude) + (b.longitude - center.longitude) * (b.longitude - center.longitude)
            return d1 > d2
        }
        
        
        // algorithm from http://www.codeproject.com/Tips/84226/Is-a-Point-inside-a-Polygon
        
        func pointInPolygon(point: CLLocationCoordinate2D, polygon poly: [CLLocationCoordinate2D]) -> Bool
        {
            var c : Bool = false
            var i = 0
            var j = poly.count - 1
            while i < poly.count {
                if (poly[i].longitude > point.longitude) != (poly[j].longitude > point.longitude) {
                    if point.latitude <
                    ((poly[j].latitude - poly[i].latitude) *
                    (point.longitude - poly[i].longitude) /
                    (poly[j].longitude - poly[i].longitude)) +
                        poly[i].latitude {
                        c = !c
                    }
            // handle the case when the point is on the line
                    if point.latitude ==
                        ((poly[j].latitude - poly[i].latitude) *
                        (point.longitude - poly[i].longitude) /
                        (poly[j].longitude - poly[i].longitude)) +
                        poly[i].latitude {
                        return true
                    }
                }
            // case where point lies on horizontal line
                else if poly[i].longitude == point.longitude && poly[j].longitude == point.longitude {
                    if (point.latitude > poly[i].latitude && point.latitude < poly[j].latitude) || (point.latitude < poly[i].latitude && point.latitude > poly[j].latitude){
                        return true
                    }
                }
            
                j = i
                i += 1
            }
            return c
        }
        
       // var totalTestPoints = 0
        
        let side = sqrt(Double(sampleDensity))
        let deltaLat = (max.latitude - min.latitude) / side
        let deltaLong = (max.longitude - min.longitude) / side
        
        // get functions to make points parallel to the longest vertical and horizontal sides
        
        var (start,end) = findLongestLatitudeSide()!
        
        let longFunc = getYaxisFunc(start, end: end)
        
        (start,end) = findLongestLongitudeSide()!
        let latFunc = getXaxisFunc(start, end: end)
        
        for i in 0 ..< Int(side) + 1 {
            
            var rowLength = 0 // count of how many points lie in the polygon
            for j in 0 ..< Int(side) + 1 {

                var p = CLLocationCoordinate2D(latitude: min.latitude + deltaLat * Double(i), longitude: min.longitude + deltaLong * Double(j))
                
                if (isRandom) { // add random variance
                    p.latitude += Double.random(lower: -deltaLat/4, upper: deltaLat/4)
                    p.longitude += Double.random(lower: -deltaLong/4, upper: deltaLong/4)
                }
                
                // adjust for skewed sides
                p.longitude += longFunc(p.latitude)
                p.latitude += latFunc(p.longitude)
                
                if pointInPolygon(p, polygon: sortedCorners) {
                    _currentField.samples.append(Sample(point: p, depth: 0))
                    rowLength += 1
               }
            }

            // reverse every other row for efficient traversal
            if (i % 2 == 1) && (rowLength > 1)
            {
                let end = _currentField.samples.endIndex - 1
                let start = end - rowLength + 1
                let reverseRow = Array(_currentField.samples[start...end].reverse())
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