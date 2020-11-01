//
//  GraphView.swift
//  bicis
//
//  Created by Javier de Martín Gil on 14/02/2019.
//  Copyright © 2019 Javier de Martín. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import SwiftUI

struct PredictionGraphViewRepresentable: UIViewRepresentable {
    
    var prediction: [Int]
    var availability: [Int]
    
    func makeUIView(context: Context) -> UIView {
        return PredictionGraphView(frame: .zero, false)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
//        uiView.text = text
        
        guard let predictionGraph = uiView as? PredictionGraphView else { return }
        
//        predictionGraph.prediction = prediction
        
        predictionGraph.drawLine(values: prediction, isPrediction: true)
        predictionGraph.drawLine(values: availability, isPrediction: false)
    }
}

/**
 Handles the received prediction data from the server and draws the graph
 */

extension PredictionGraphView: HomeViewControllerGraphViewDelegate {
    func hideGraphView() {
        actualAvailabilityLayer.removeFromSuperlayer()
        drawingLayer.removeFromSuperlayer()
    }
    func setStationTitleFor(name: String) {

        stationTitle.removeFromSuperview()

        stationTitle = {

            let label = NBLabel(frame: CGRect(x: 10, y: 5, width: self.frame.width, height: 40.0))
            label.applyProtocolUIAppearance()
            label.text = "  " + name
            
            if shouldShowBorder {
                label.textColor = .white
            } else {
                label.textColor = UIColor(named: "TextAndGraphColor")
            }
            
            label.layer.masksToBounds = false
            label.font = UIFont.preferredFont(for: .title2, weight: .bold)

            label.sizeToFit()

            return label
        }()

        addSubview(stationTitle)
    }
}

public extension UIBezierPath {
    
    convenience init?(quadCurve points: [CGPoint]) {
        guard points.count > 1 else { return nil }
        
        self.init()
        
        var p1 = points[0]
        move(to: p1)
        
        if points.count == 2 {
            addLine(to: points[1])
        }
        
        for i in 0..<points.count {
            let mid = midPoint(p1: p1, p2: points[i])
            
            addQuadCurve(to: mid, controlPoint: controlPoint(p1: mid, p2: p1))
            addQuadCurve(to: points[i], controlPoint: controlPoint(p1: mid, p2: points[i]))
            
            p1 = points[i]
        }
    }
    
    private func midPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    private func controlPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        var controlPoint = midPoint(p1: p1, p2: p2)
        let diffY = abs(p2.y - controlPoint.y)
        
        if p1.y < p2.y {
            controlPoint.y += diffY
        } else if p1.y > p2.y {
            controlPoint.y -= diffY
        }
        return controlPoint
    }
}

class PredictionGraphView: UIView {

    // MARK: Instance Properties
    var stationTitle: UILabel = {
        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.font = UIFont.preferredFont(for: .title3, weight: .bold)
        
        return label
    }()
    var stationTitleText: String?

    var viewHeight: CGFloat = -1.0
    var viewWidth: CGFloat = -1.0
    
    lazy var animation: CABasicAnimation = {
        // Animate the drawing of the actual availability
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 0.5
        animation.autoreverses = false
        return animation
    }()

    let shapeLayer = CAShapeLayer()
    let actualAvailabilityLayer: CAShapeLayer = {
    
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 4.5
        layer.strokeStart = 0.0
        return layer
    }()
    
    let drawingLayer: CAShapeLayer = {
        
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 2.5
        layer.strokeStart = 0.0
        layer.lineDashPattern = [4, 4]
        return layer
    }()
    
    var shouldShowBorder: Bool = true

    private var shadowLayer: CAShapeLayer!
    
    init(frame: CGRect, prediction: [Int], availability: [Int]) {
        super.init(frame: frame)
    }
    
    init(frame: CGRect, _ shouldShowBorder: Bool = true) {
        super.init(frame: frame)
        
        self.shouldShowBorder = shouldShowBorder
        
        if shouldShowBorder {
            self.backgroundColor = .systemBlue
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func updateConstraints() {
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.accessibilityIdentifier = "PredictionGraph"
        self.backgroundColor = UIColor.systemBackground
        
        if self.shouldShowBorder {
            self.backgroundColor = .systemBlue
            addGradient()
        }
    }
    
    func getPercentageOfDay() -> (CGFloat, Int) {
   
        let date = Date()
        let calendar = Calendar.current
        let minute = Int(calendar.component(.minute, from: date) / 10)
        let hour = calendar.component(.hour, from: date)

        let step: Double = Double(hour * 6 + minute)

        let consumedDayPercentage: CGFloat = CGFloat((step / Constants.lengthOfTheDay))

        return (consumedDayPercentage, Int(step))
    }
    
    func addGradient() {

        // Add Border
        let layer: CALayer? = self.layer
        layer?.cornerRadius = Constants.cornerRadius
        layer?.masksToBounds = true
        layer?.borderWidth = 2.0
        layer?.borderColor = UIColor(white: 0.25, alpha: 0.4).cgColor
    }

    func drawLine(values: [Int], isPrediction: Bool) {

        viewHeight = (self.frame.size.height - stationTitle.frame.size.height * 1.4)
        viewWidth = self.frame.width * CGFloat(values.count) / CGFloat(Constants.lengthOfTheDay)
        
        guard values.count > 0 else { return }
    
        var path = UIBezierPath()

        var heightProportion: CGFloat = 0.0 // CGFloat(values[0]) / CGFloat(values.max()!)

        // Mover el punto inicial al origen de X y a la altura que corresponde al valor obtenido.
        let initialCoordinates = CGPoint(x: 0.0, y: viewHeight - viewHeight * heightProportion + stationTitle.frame.size.height * 0.8)

        path.move(to: initialCoordinates)
        
        let arrayOfPoints: [CGPoint] = values.enumerated().map({ (index, element) in
            
            heightProportion = CGFloat(element) / CGFloat(values.max()!)
            
            if heightProportion.isNaN {
                heightProportion = 0.0
            }
            
            let point: CGPoint = {
                let xPosition = CGFloat(index) * viewWidth / CGFloat(values.count)
                let yPosition = viewHeight - viewHeight * heightProportion + stationTitle.frame.size.height * 0.8
                
                return CGPoint(x: xPosition, y: yPosition)
            }()
            
            return point
        })
        
        path = UIBezierPath(quadCurve: arrayOfPoints)!
        
        if shouldShowBorder {
            actualAvailabilityLayer.strokeColor =  UIColor.white.cgColor
        } else {
            actualAvailabilityLayer.strokeColor =  UIColor(named: "TextAndGraphColor")?.cgColor
        }

        if isPrediction {
            
            if shouldShowBorder {
                drawingLayer.strokeColor = UIColor.white.cgColor
            } else {
                drawingLayer.strokeColor = UIColor(named: "TextAndGraphColor")?.cgColor
            }

            path.apply(CGAffineTransform(translationX: 0, y: +10.0))

            drawingLayer.path = path.cgPath

            self.layer.addSublayer(drawingLayer)

        } else {

            path.lineJoinStyle = .round
            path.apply(CGAffineTransform(translationX: 0, y: +10.0))
            actualAvailabilityLayer.path = path.cgPath
            path.stroke()

            self.layer.addSublayer(actualAvailabilityLayer)

            actualAvailabilityLayer.add(animation, forKey: "line")
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }

    /// As the view hides remove all information related to the
    func hideView() {

        actualAvailabilityLayer.removeFromSuperlayer()
        drawingLayer.removeFromSuperlayer()
        stationTitle.text = ""
    }
}
