//
//  HeatMap.swift
//  SoilSampler
//
//  Created by Samuel Hazlehurst on 1/20/16.
//  Copyright © 2016 Terranian Farm. All rights reserved.
//

import Foundation
import MapKit

extension MKMapPoint : Hashable {
    
    public var hashValue: Int {
        get {
            
            // take the x and y coordinate hash values, discard the significant
            // half of the bits, shift the x the the significant size, and
            // combine them with a bitwise or
            
            let lowX = x.hashValue & (Int.max >> (sizeof(Int) * 4))
            let lowY = y.hashValue & (Int.max >> (sizeof(Int) * 4))
            let hash = (lowX << (sizeof(Int) * 4) ) | lowY
            
            return hash
        }
    }
}

public func ==(lhs: MKMapPoint, rhs: MKMapPoint) -> Bool
{
    return (lhs.x == rhs.x) && (lhs.y == rhs.y)
}

class HeatMap : NSObject, MKOverlay {
    
    static let kSBMapRectPadding : CGFloat = 100000
    static let kSBZoomZeroDimension : Int = 256
    static let kSBMapKitPoints : Int = 536870912
    static let kSBZoomLevels : Int = 20

    // Alterable constant to change look of heat map
    static let kSBScalePower : Int = 4

    // Alterable constant to trade off accuracy with performance
    // Increase for big data sets which draw slowly
    static let kSBScreenPointsPerBucket : Int = 10;


    var _max : Float = 0
    var _zoomedOutMax : Float = 0
    
    var _pointsWithHeat : [MKMapPoint:Float]?
    var _center = CLLocationCoordinate2D()
    var _boundingRect = MKMapRect()

//@synthesize max = _max;
//@synthesize zoomedOutMax = _zoomedOutMax;
//@synthesize pointsWithHeat = _pointsWithHeat;
//@synthesize center = _center;
//@synthesize boundingRect = _boundingRect;

    var coordinate: CLLocationCoordinate2D {
        get {
            return _center
        }
    }
    
    var boundingMapRect: MKMapRect {
        get {
            return _boundingRect
        }
    }

    /*

    
    - (id)initWithData:(NSDictionary *)heatMapData
    {
    if (self = [super init]) {
    [self setData:heatMapData];
    }
    return self;
    }
    

*/
    init(withHeatMapData: [MKMapPoint:Float])
    {
        //_pointsWithHeat = withHeatMapData
        super.init()
        
        setData(withHeatMapData)
    }

    func setData(newHeatMapData : [MKMapPoint:Float])
    {
        
        self._max = 0
        var upperLeftPoint, lowerRightPoint : MKMapPoint
  
        upperLeftPoint = Array(newHeatMapData.keys)[0]
        lowerRightPoint = upperLeftPoint
  
        var buckets = [Float](count: HeatMap.kSBZoomZeroDimension
            * HeatMap.kSBZoomZeroDimension, repeatedValue: 0.0)

        //iterate through to find the max and the bounding region
        //set up the internal model with the data
        //TODO: make sure this dictionary has the correct typing
        for point in newHeatMapData.keys {
            
            if point.x < upperLeftPoint.x {
                upperLeftPoint.x = point.x
            }
            
            if point.y < upperLeftPoint.y {
                upperLeftPoint.y = point.y
            }
            
            if point.x > lowerRightPoint.x {
                lowerRightPoint.x = point.x
            }
            
            if point.y > lowerRightPoint.y {
                lowerRightPoint.y = point.y
            }
            
            if let value = newHeatMapData[point] {
            
                if value > self._max {
                    self._max = value
                }
                
                //bucket the map point:
//                var col : Int = Int(point.x)
                let col = point.x /
                    (Double(HeatMap.kSBMapKitPoints) /
                    Double(HeatMap.kSBZoomZeroDimension))
                let iCol = Int(col)
                let row : Int = Int(point.y) /
                    (HeatMap.kSBMapKitPoints /
                    HeatMap.kSBZoomZeroDimension)
                
                let offset = HeatMap.kSBZoomZeroDimension * row + iCol
                
                buckets[offset] += value
            }
        }
        
        for i in 0 ..< HeatMap.kSBZoomZeroDimension * HeatMap.kSBZoomZeroDimension {
            if buckets[i] > self._zoomedOutMax {
                self._zoomedOutMax = buckets[i]
            }
        }
        
        //make the new bounding region from the two corners
        //probably should do some cusioning
        let width : Double = lowerRightPoint.x - upperLeftPoint.x + Double(HeatMap.kSBMapRectPadding)
        let height : Double = lowerRightPoint.y - upperLeftPoint.y + Double(HeatMap.kSBMapRectPadding)
        
        self._boundingRect = MKMapRectMake(
            upperLeftPoint.x -
                Double(HeatMap.kSBMapRectPadding) / 2,
            upperLeftPoint.y - Double(HeatMap.kSBMapRectPadding) / 2,
            width, height)
        self._center = MKCoordinateForMapPoint(
            MKMapPointMake(upperLeftPoint.x + width / 2,
                upperLeftPoint.y + height / 2))
        
        _pointsWithHeat = newHeatMapData
       
    }
    
    func mapPointsWithHeatInMapRect(rect : MKMapRect, atScale scale: MKZoomScale) -> [MKMapPoint:Float]
    {
        var toReturn = [MKMapPoint:Float]()
        let bucketDelta = CGFloat(HeatMap.kSBScreenPointsPerBucket) / scale
    
        let zoomScale = Double(log2(CGFloat(1)/scale))
        let slope = Double((self._zoomedOutMax - self._max) / Float((HeatMap.kSBZoomLevels - 1)))
        let x = Double(pow(zoomScale, Double(HeatMap.kSBScalePower))) /
            Double(pow(Float(HeatMap.kSBZoomLevels), Float(HeatMap.kSBScalePower - 1)))
        
        var scaleFactor = Double((x - 1) * slope + Double(self._max))

        if scaleFactor < Double(self._max) {
            scaleFactor = Double(self._max)
        }
    
        for point in self._pointsWithHeat!.keys {
        
            if MKMapRectContainsPoint(rect, point) {
                // Scale the value down by the max and add it to the return dictionary
                let value = _pointsWithHeat![point]
                let unscaled = Double(value!)
                var scaled = unscaled / scaleFactor;
                
                var bucketPoint = MKMapPoint()
                let originalX = point.x
                let originalY = point.y
                bucketPoint.x = originalX - originalX % Double(bucketDelta) + Double(bucketDelta / 2)
                bucketPoint.y = originalY - originalY % Double(bucketDelta) + Double(bucketDelta / 2)

                if let existingValue = toReturn[bucketPoint] {
                    scaled += Double(existingValue)
                }
                
                toReturn[bucketPoint] = Float(scaled)
            }
        }
        return toReturn
    }
}



