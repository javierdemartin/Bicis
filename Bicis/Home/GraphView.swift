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

            let label = UILabel(frame: CGRect(x: 5, y: 5, width: self.frame.width, height: 40.0))
            label.text = name
            label.textColor = UIColor(named: "TextAndGraphColor")
            label.frame.size.width = name.width(withConstrainedHeight: 19.0, font: Constants.headerFont)
            label.font = Constants.headerFont
            label.layer.masksToBounds = false

            label.sizeToFit()

            return label
        }()

        addSubview(stationTitle)
    }
}

class PredictionGraphView: UIView {

    // MARK: Instance Properties
    var stationTitle = UILabel()
    var stationTitleText: String?

    var viewHeight: CGFloat = -1.0
    var viewWidth: CGFloat = -1.0

    let shapeLayer = CAShapeLayer()
    let actualAvailabilityLayer = CAShapeLayer()
    let drawingLayer = CAShapeLayer()

    private var shadowLayer: CAShapeLayer!

    func getPercentageOfDay() -> (CGFloat, Int) {

        let date = Date()
        let calendar = Calendar.current
        let minute = Int(calendar.component(.minute, from: date) / 10)
        let hour = calendar.component(.hour, from: date)

        let step: Double = Double(hour * 6 + minute)

        let consumedDayPercentage: CGFloat = CGFloat((step / Constants.lengthOfTheDay))

        return (consumedDayPercentage, Int(step))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
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
        self.clipsToBounds = true
        self.layer.cornerRadius = Constants.cornerRadius
        self.backgroundColor = UIColor.systemBlue
    }

    func drawLine(values: [Int], isPrediction: Bool) {

        viewHeight = (self.frame.size.height - stationTitle.frame.size.height * 1.4)
        // Esto se deberia poder sustituir por el porcentaje del día que se tiene ya
        viewWidth = self.frame.width * CGFloat(values.count) / CGFloat(Constants.lengthOfTheDay)

//        let maxValue = max(values.max()!, maxValue)

        if values.count > 0 {

            // create whatever path you want
            let path = UIBezierPath()
            var nextPoint = CGPoint()

            var heightProportion = CGFloat(values[0]) / CGFloat(values.max()!)

            // Mover el punto inicial al origen de X y a la altura que corresponde al valor obtenido.
            let initialCoordinates = CGPoint(x: 0.0, y: viewHeight - viewHeight * heightProportion + stationTitle.frame.size.height * 0.9)

            path.move(to: initialCoordinates)

            for element in 0..<values.count {

                heightProportion = CGFloat(values[element]) / CGFloat(values.max()!)

                let xPosition = CGFloat(element) * viewWidth / CGFloat(values.count)
                let yPosition = viewHeight - viewHeight * heightProportion + stationTitle.frame.size.height*0.9

                nextPoint = CGPoint(x: xPosition, y: yPosition)
                path.addLine(to: nextPoint)
            }

            actualAvailabilityLayer.fillColor = UIColor.clear.cgColor
            actualAvailabilityLayer.strokeColor =  UIColor(named: "TextAndGraphColor")?.cgColor
            actualAvailabilityLayer.lineWidth = 3
            actualAvailabilityLayer.strokeStart = 0.0

            if isPrediction {

                drawingLayer.strokeColor = UIColor(named: "TextAndGraphColor")?.cgColor
                drawingLayer.lineWidth = 3
                drawingLayer.strokeStart = 0.0
                drawingLayer.lineDashPattern = [4, 4]

                nextPoint = CGPoint(x: CGFloat(values.count - 1) * viewWidth / CGFloat(values.count), y: 300.0)

                path.apply(CGAffineTransform(translationX: 0, y: +10.0))

                drawingLayer.path = path.cgPath
                drawingLayer.fillColor = UIColor.clear.cgColor

                self.layer.addSublayer(drawingLayer)

            } else {

                path.apply(CGAffineTransform(translationX: 0, y: +10.0))
                actualAvailabilityLayer.path = path.cgPath

                self.layer.addSublayer(actualAvailabilityLayer)

                // Animate the drawing of the actual availability
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.fromValue = 0
                animation.toValue = 1
                animation.duration = 0.5
                animation.autoreverses = false

                actualAvailabilityLayer.add(animation, forKey: "line")
            }

            self.updateConstraints()
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
