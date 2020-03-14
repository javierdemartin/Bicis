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

    func setStationTitleFor(name: String) {

        stationTitle.removeFromSuperview()

        stationTitle = UILabel(frame: CGRect(x: 5, y: 5, width: self.frame.width, height: 40.0))
        stationTitle.text = name

        let myFont = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .heavy) //UIFont.systemFont(ofSize: 19.0, weight: .heavy)
        stationTitle.textColor = UIColor(named: "TextAndGraphColor")

        stationTitle.frame.size.width = name.width(withConstrainedHeight: 19.0, font: myFont)
        stationTitle.font = myFont
        stationTitle.layer.masksToBounds = false

        stationTitle.sizeToFit()

        addSubview(stationTitle)
    }
}

class PredictionGraphView: UIView {

    enum Shown {
        case shown, hidden
    }

    var isShown: Bool

    var stationTitle = UILabel()
    var stationTitleText: String?

    var viewHeight: CGFloat = -1.0
    var viewWidth: CGFloat = -1.0

    let lenDay = 144.0 //predictionData.count
    let shapeLayer = CAShapeLayer()
    let actualAvailabilityLayer = CAShapeLayer()
    let drawingLayer = CAShapeLayer()

    var maxValue: Int = 0

    private var shadowLayer: CAShapeLayer!
    private var cornerRadius: CGFloat = 25.0

    func getPercentageOfDay() -> (CGFloat, Int) {

        let date = Date()
        let calendar = Calendar.current
        let minute = Int(calendar.component(.minute, from: date) / 10)
        let hour = calendar.component(.hour, from: date)

        let step: Double = Double(hour * 6 + minute)

        let consumedDayPercentage: CGFloat = CGFloat((step / lenDay))

        return (consumedDayPercentage, Int(step))
    }

    override init(frame: CGRect) {
        isShown = false
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        isShown = false
        super.init(coder: aDecoder)
    }

    override func updateConstraints() {
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.accessibilityIdentifier = "PredictionGraph"
        self.clipsToBounds = true
        self.layer.cornerRadius = Appearance().cornerRadius
        self.backgroundColor = UIColor.systemBlue //UIColor(named: "RedColor")
    }

    func addShadows() {
        
        if shadowLayer == nil {
            shadowLayer = CAShapeLayer()

            shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
            shadowLayer.fillColor = UIColor.clear.cgColor

            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowPath = shadowLayer.path
            shadowLayer.shadowOffset = .zero
            shadowLayer.shadowOpacity = 1
            shadowLayer.shadowRadius = 3

            layer.insertSublayer(shadowLayer, at: 0)
        }
    }

    @objc func didPan(recognizer: UIPanGestureRecognizer) {

        print("-- \(recognizer.location(in: self))")
    }

    func initGestureRecognizers() {

        let panGR = UIPanGestureRecognizer(target: self, action: #selector(didPan(recognizer:)))
        addGestureRecognizer(panGR)
    }

    func drawLine(values: [Int], isPrediction: Bool) {

        if !isPrediction {
            actualAvailabilityLayer.removeFromSuperlayer()
        }

        viewHeight = (self.frame.size.height - stationTitle.frame.size.height * 1.5)
        viewWidth = self.frame.width * CGFloat(values.count) / CGFloat(lenDay)

        guard let maxVal = values.max() else { return }

        if maxVal > maxValue { maxValue = values.max()! }

        if values.count > 0 {

            // create whatever path you want
            let path = UIBezierPath()
            var nextPoint = CGPoint()

            var heightProportion = CGFloat(values[0]) / CGFloat(maxValue)

            // Mover el punto inicial al origen de X y a la altura que corresponde al valor obtenido.
            let initialCoordinates = CGPoint(x: 0.0, y: viewHeight - viewHeight * heightProportion + stationTitle.frame.size.height * 0.9)

            path.move(to: initialCoordinates)

            for element in 0..<values.count {

                heightProportion = CGFloat(values[element]) / CGFloat(maxValue)

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

    func hideView() {

        actualAvailabilityLayer.removeFromSuperlayer()
        drawingLayer.removeFromSuperlayer()
        stationTitle.text = ""

//        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
//
//            self.transform = CGAffineTransform(translationX: 0, y: -1 * (0 + 110.0))
//            self.layoutIfNeeded()
//        }, completion: { _ in
//
//            self.isShown = false
//        })

    }

    func showView() {

//        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
//
//            self.transform = CGAffineTransform(translationX: 0, y: 0 + 55.0)
//
//            self.isHidden = false
//            self.layoutIfNeeded()
//        }, completion: {_ in
//            self.isShown = true
//
//        })

    }
}
