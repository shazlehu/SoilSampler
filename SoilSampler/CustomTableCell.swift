//
//  CustomTableCell.swift
//  MapTest
//
//  Created by Samuel Hazlehurst on 3/20/15.
//  Copyright (c) 2015 Terranian Farm. All rights reserved.
//

import Foundation

class CustomStepper: UIStepper {
    var label: UILabel!
    var sampleIndex: Int = 0
    var annotation: CustomAnnotation!
    init(frame: CGRect, aLabel: UILabel, index: Int, annotation: CustomAnnotation) {
        super.init(frame: frame)
        label = aLabel
        sampleIndex = index
        self.annotation = annotation
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CustomTableCell: UITableViewCell {
    var annotation : CustomAnnotation!
    init(annotation: CustomAnnotation, style: UITableViewCellStyle, reuseIdentified: String)
    {
        super.init(style: style, reuseIdentifier: reuseIdentified)
        self.annotation = annotation
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

