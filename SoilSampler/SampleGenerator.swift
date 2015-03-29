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

struct Sample : Printable {
    var point : CLLocationCoordinate2D
    var depth : Double = 0.0
    
    var description : String {
        get {
            return "\(point.latitude),\(point.longitude),\(depth)"
        }
    }
}

class SampleGenerator {
    
    var field = [CLLocationCoordinate2D]()
    private var samplePoints = [Sample]()
    var count : Int { get { return samplePoints.count } }
    
    var annotations = [AnyObject]()
    var sampleDensity: Int = 10
    var fileName = "log.csv"
    
    subscript(index: Int) -> Sample {
        get {
            return samplePoints[index]
        }
        set (newValue) {
            samplePoints[index] = newValue
        }
    }
    
    func addFieldPoint(p : CLLocationCoordinate2D) -> Int {
        field.append(p)
        return field.count - 1
    }
    
    func updateFieldPoint(index: Int, coord: CLLocationCoordinate2D)
    {
        field[index] = coord
    }
    
    func clear() {
        field.removeAll(keepCapacity: true)
        samplePoints.removeAll(keepCapacity: true)
    }

    func clearSample() {
        samplePoints.removeAll(keepCapacity: true)
    }
    
    func getSampleCoords () -> [CLLocation] {
        var coords = [CLLocation]()
        for s in samplePoints {
            coords.append(CLLocation(latitude: s.point.latitude, longitude: s.point.longitude))
        }
        return coords
    }
    
    func getDepths() -> [NSNumber] {
        var depths = [NSNumber]()
        for s in samplePoints {
            depths.append(NSNumber(double: s.depth))
        }
        return depths
    }
    
    private var fileurl : NSURL! = nil
    
    func writeFile() -> NSURL
    {
        
        let dir : NSURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.CachesDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last as NSURL
        fileurl =  dir.URLByAppendingPathComponent(fileName)
        
        var string : String = "\(NSDate()),,\n"
        
        for s in samplePoints {
            string += "\(s.description)\n"
        }
        println(string)
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        if NSFileManager.defaultManager().fileExistsAtPath(fileurl.path!) {
            var err:NSError?
            if let fileHandle = NSFileHandle(forWritingToURL: fileurl, error: &err) {
                fileHandle.seekToEndOfFile()
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
        for (var i = 0; i < field.count - 1; i++) {
            let slope = abs(getSlope(field[i], end: field[i+1]))
            if (slope > 1) && isVertical {
                candidateSides.append((field[i], field[i+1]))
            }
            else if (slope < 1) && !isVertical {
                candidateSides.append((field[i], field[i+1]))
            }
        }
        
        if abs(getSlope(field.last!, end: field.first!)) > 1 {
            candidateSides.append((field.last!, field.first!))
        }
        
        if (candidateSides.isEmpty == true) { return (field[0],field[1]) }
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
        
        if field.count < 3 { return nil }
        
        // find bounding rectangle
        
        var min = CLLocationCoordinate2D(latitude: field[0].latitude, longitude: field[0].longitude)
        var max = CLLocationCoordinate2D(latitude: field[0].latitude, longitude: field[0].longitude)
        
        for p in field {
            if p.latitude > max.latitude { max.latitude = p.latitude }
            if p.longitude > max.longitude { max.longitude = p.longitude }
            if p.latitude < min.latitude { min.latitude = p.latitude }
            if p.longitude < min.longitude { min.longitude = p.longitude }
        }
        
        // algorithm from http://www.codeproject.com/Tips/84226/Is-a-Point-inside-a-Polygon
        
        func pointInPolygon(point: CLLocationCoordinate2D, polygon poly: [CLLocationCoordinate2D]) -> Bool
        {
            var c : Bool = false
            
            for var i = 0, j = poly.count - 1; i < field.count; j = i++ {
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
                
                if pointInPolygon(p, polygon: field) {
                    samplePoints.append(Sample(point: p, depth: 0))
                    rowLength++
               }
            }

            // reverse every other row for efficient traversal
            if (i % 2 == 1) && (rowLength > 1)
            {
                let end = samplePoints.endIndex - 1
                let start = end - rowLength + 1
                let reverseRow = samplePoints[start...end].reverse()
                samplePoints.replaceRange(start...end, with: reverseRow)
            }
        }
        return samplePoints
    }
}