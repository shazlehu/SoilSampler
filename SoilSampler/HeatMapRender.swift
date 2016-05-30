//
//  HeatMapRenderer.swift
//  SoilSampler
//
//  Created by Samuel Hazlehurst on 1/20/16.
//  Copyright © 2016 Terranian Farm. All rights reserved.
//

import Foundation
import MapKit


class HeatMapRenderer : MKOverlayRenderer {
    static let kSBHeatRadiusInPoints = 300

// This sets the spread of the heat from each map point (in screen pts.)
//static let NSInteger kSBHeatRadiusInPoints = 300;

// These affect the transparency of the heatmap
// Colder areas will be more transparent
// Currently the alpha is a two piece linear function of the value
// Play with the pivot point and max alpha to affect the look of the heatmap

// This number should be between 0 and 1
    static let kSBAlphaPivotX : CGFloat = 0.333;

// This number should be between 0 and MAX_ALPHA
    static let kSBAlphaPivotY : CGFloat = 0.5;

// This number should be between 0 and 1
    static let kSBMaxAlpha : CGFloat = 0.85;

    var _scaleMatrix = [Float](count: 2 * HeatMapRenderer.kSBHeatRadiusInPoints * 2 * HeatMapRenderer.kSBHeatRadiusInPoints, repeatedValue: 0.0)

    override init(overlay: MKOverlay)
    {
        super.init(overlay: overlay)
        
        populateScaleMatrix()
    }
    
    func populateScaleMatrix()
    {
        for i in 0 ..< 2 * HeatMapRenderer.kSBHeatRadiusInPoints {
            for j in 0 ..< 2 * HeatMapRenderer.kSBHeatRadiusInPoints {
                let iDiff = i - HeatMapRenderer.kSBHeatRadiusInPoints
                let jDiff = j - HeatMapRenderer.kSBHeatRadiusInPoints
                let distance = sqrt(Float(iDiff * iDiff + jDiff * jDiff))

                var scaleFactor = 1.0 - distance / Float(HeatMapRenderer.kSBHeatRadiusInPoints)
                if scaleFactor < 0 {
                    scaleFactor = 0
                } else {
                    scaleFactor = (expf(-distance/10.0) - expf(-Float(HeatMapRenderer.kSBHeatRadiusInPoints)/10.0)) / expf(0)
                }
                _scaleMatrix[j * 2 * HeatMapRenderer.kSBHeatRadiusInPoints + i] = scaleFactor;
            }
        }
    }
    
    func colorForValue(value : Double) -> (red : CGFloat, green : CGFloat, blue : CGFloat, alpha: CGFloat)
    {
        var red, green, blue, alpha : CGFloat
        let localVal : Double = value > 1 ? 1 : sqrt(value)
    
        if localVal < Double(HeatMapRenderer.kSBAlphaPivotY) {
            alpha = CGFloat(localVal * Double(HeatMapRenderer.kSBAlphaPivotY / HeatMapRenderer.kSBAlphaPivotX))
        } else {
            let temp = Double((HeatMapRenderer.kSBMaxAlpha - HeatMapRenderer.kSBAlphaPivotY) / (1 - HeatMapRenderer.kSBAlphaPivotX)) * localVal - Double(HeatMapRenderer.kSBAlphaPivotX)
            let dAlpha = Double(HeatMapRenderer.kSBAlphaPivotY) + temp
                
            alpha = CGFloat(dAlpha)
        }
    
        //formula converts a number from 0 to 1.0 to an rgb color.
        //uses MATLAB/Octave colorbar code
        if(localVal <= 0) {
            red = 0.0
            green = 0.0
            blue = 0.0
            alpha = 0.0
        } else if(localVal < 0.125) {
            red = 0.0
            green = 0.0
            blue = CGFloat(4.0 * (localVal + 0.125))
        } else if localVal < 0.375 {
            red = 0
            green = CGFloat(4 * (localVal - 0.125))
            blue = 1
        } else if localVal < 0.625 {
            red = CGFloat(4 * (localVal - 0.375))
            green = 1
            blue = CGFloat(1 - 4 * (localVal - 0.375))
        } else if localVal < 0.875 {
            red = 1
            green = CGFloat(1 - 4 * (localVal - 0.625))
            blue = 0
        } else {
            red = max(CGFloat(1 - 4 * (localVal - 0.875)), 0.5)
            green = 0
            blue = 0
        }
        
        // swapping red and blue
        var temp : CGFloat = 0
        temp = green
        green = red
        red = blue
        blue = temp
        return (red,green,blue,alpha)
    }
    
    override func drawMapRect(mapRect : MKMapRect, zoomScale: MKZoomScale, inContext: CGContextRef)
    {
        let usRect : CGRect  = rectForMapRect(mapRect)
        //rect in user space coordinates (NOTE: not in screen points)
        let zoom = zoomScale / 4; // this seems to make it work better.  should make it a setting
        let columns = ceil(CGRectGetWidth(usRect) * zoom)
        let rows = ceil(CGRectGetHeight(usRect) * zoom)
        let arrayLen = columns * rows;
    
        //allocate an array matching the screen point size of the rect
        var pointValues = [Float](count: Int(arrayLen), repeatedValue: 0.0)

        
//        if (pointValues ) {
            //pad out the mapRect with the radius on all sides.
            // we care about points that are not in (but close to) this rect
        var paddedRect : CGRect = rectForMapRect(mapRect)
        paddedRect.origin.x -= CGFloat(HeatMapRenderer.kSBHeatRadiusInPoints) / zoom
        paddedRect.origin.y -= CGFloat(HeatMapRenderer.kSBHeatRadiusInPoints) / zoom;
        paddedRect.size.width += 2 * CGFloat(HeatMapRenderer.kSBHeatRadiusInPoints) / zoom;
        paddedRect.size.height += 2 * CGFloat(HeatMapRenderer.kSBHeatRadiusInPoints) / zoom;
        let paddedMapRect : MKMapRect = mapRectForRect(paddedRect)
        
        // Get the dictionary of values out of the model for this mapRect and zoomScale.
        let hm : HeatMap = self.overlay as! HeatMap

        let heat = hm.mapPointsWithHeatInMapRect(paddedMapRect, atScale: zoom)
        
        for (key, value) in heat {
            //convert key to mapPoint
//            MKMapPoint mapPoint;
//            [key getValue:&mapPoint];
//            double value = [[heat objectForKey:key] doubleValue];
//            let value = heat[key]
            //figure out the correspoinding array index
            let usPoint : CGPoint = pointForMapPoint(key)
            
            let matrixCoord : CGPoint = CGPointMake((usPoint.x - usRect.origin.x) * zoom,
                (usPoint.y - usRect.origin.y) * zoom)
            
            if (value > 0) { //don't bother with 0 or negative values
                //iterate through surrounding pixels and increase
                for i in 0 ..< 2 * HeatMapRenderer.kSBHeatRadiusInPoints {
                    for j in 0 ..< 2 * HeatMapRenderer.kSBHeatRadiusInPoints {
                        //find the array index
                        let column = floor(matrixCoord.x - CGFloat(HeatMapRenderer.kSBHeatRadiusInPoints) + CGFloat(i))
                        let row = floor(matrixCoord.y - CGFloat(HeatMapRenderer.kSBHeatRadiusInPoints) + CGFloat(j))
                        
                        //make sure this is a valid array index
                        if row >= 0 && column >= 0 && row < rows && column < columns {
                            let index = Int(columns * row + column)
                            pointValues[index] += value * Float(_scaleMatrix[j * 2 * HeatMapRenderer.kSBHeatRadiusInPoints + i])
                        }
                    }
                }
            }
        }
        
        for i in 0 ..< Int(arrayLen) {
            if (pointValues[i] > 0) {
                let column = i % Int(columns)
                let row = i / Int(columns)

                let (red, green, blue, alpha) = self.colorForValue(Double(pointValues[i]))
                CGContextSetRGBFillColor(inContext, red, green, blue, alpha);
                
                //scale back up to userSpace
                let matchingUsRect = CGRectMake(usRect.origin.x + CGFloat(column) / zoom,
                    usRect.origin.y + CGFloat(row) / zoom,
                    1/zoom,
                    1/zoom)
                
                CGContextFillRect(inContext, matchingUsRect)
            }
        }
        
        
    }
}
