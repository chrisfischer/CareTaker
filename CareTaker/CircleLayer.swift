//
//  CircleLayer.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/14/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit

class CircleLayer: CAShapeLayer {
    
    var circleLayer: CAShapeLayer?
    var center: CGPoint?
    var radius: Double?
    
    init(center: CGPoint, parentFrame: CGRect, color: UIColor) {
        super.init()
        
        self.center = center
        radius = findMaxRadius(center: center, parentFrame: parentFrame)
        
        let startPath = UIBezierPath(arcCenter: center, radius: CGFloat(20), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true).cgPath
        
        circleLayer = CAShapeLayer()
        circleLayer?.path = startPath
        circleLayer?.fillColor = color.cgColor

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animateExpand() {
        let expandAnimation: CABasicAnimation = CABasicAnimation(keyPath: "path")
        expandAnimation.fromValue = UIBezierPath(arcCenter: center!, radius: CGFloat(10), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true).cgPath
        expandAnimation.toValue = UIBezierPath(arcCenter: center!, radius: CGFloat(radius! + 5), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true).cgPath
        expandAnimation.duration = DELAY_DURATION
        expandAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        expandAnimation.fillMode = kCAFillModeForwards
        expandAnimation.isRemovedOnCompletion = false
        circleLayer?.add(expandAnimation, forKey: nil)
        
    }
    
    func findMaxRadius(center: CGPoint, parentFrame: CGRect) -> Double {
        let width = Double(parentFrame.width)
        let height = Double(parentFrame.height)
        let x = Double(center.x)
        let y = Double(center.y)
        
        if (x < width/2) {
            if (y < height/2) {
                // upper left corner
                let dx = width - x
                let dy = height - y
                return (dx * dx + dy * dy).squareRoot()
            } else {
                // bottom left corner
                let dx = width - x
                return (dx * dx + y * y).squareRoot()
            }
        } else {
            if (y < height/2) {
                // upper right corner
                let dy = height - y
                return (x * x + dy * dy).squareRoot()
                
            } else {
                // lower right corner
                return (x * x + y * y).squareRoot()
            }
        }
    }
}
