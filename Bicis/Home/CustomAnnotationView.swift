//
//  CustomAnnotationView.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 03/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import UIKit
import MapKit

class CustomAnnotationView: MKMarkerAnnotationView {

    private let annotationFrame = CGRect(x: 0, y: 0, width: 40, height: 40)
    private var label: UILabel = UILabel()
    private var backgroundView: UIView = UIView()
    private let selectedLabel = UILabel(frame: CGRect(x: 0, y: -50, width: 100, height: 40))

    public var number: UInt32 = 0 {
        didSet {
            self.label.text = String(number)
        }
    }

    public var station: String = "" {
        didSet {
            self.selectedLabel.text = station
        }
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
    }

    func updateBackground(color: UIColor) {

        self.backgroundView.backgroundColor! = color
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {

        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.displayPriority = .required
        clusteringIdentifier = "\(CustomAnnotationView.self)"

        self.label = UILabel(frame: annotationFrame.offsetBy(dx: 0, dy: 0))
        self.backgroundView = UIView(frame: annotationFrame)

        self.backgroundView.layer.cornerRadius = 10
        self.backgroundView.layer.borderWidth = 4
        self.backgroundView.layer.borderColor = UIColor(named: "RedColor")?.darker(by: 5.0)?.cgColor
        backgroundView.backgroundColor = UIColor(named: "RedColor")
        self.addSubview(backgroundView)

        self.canShowCallout = false
        selectedLabel.backgroundColor = UIColor(named: "RedColor")
        selectedLabel.textColor = UIColor(named: "TextAndGraphColor") // Colors().annotationTextColor
        selectedLabel.tag = 199
        selectedLabel.layer.borderWidth = 5.0
        selectedLabel.layer.borderColor = UIColor(named: "TextAndGraphColor")?.cgColor
        selectedLabel.layer.cornerRadius = Appearance().cornerRadius
        selectedLabel.clipsToBounds = true
        selectedLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)

        if let annotation = annotation {
            guard let title = annotation.title else { return }

            guard let titlo = title else { return }

            setTitle(forStation: titlo)
        }

        self.frame = annotationFrame
        self.label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        self.label.textColor = UIColor(named: "TextAndGraphColor") // Colors().annotationTextColor
        self.label.textAlignment = .center
        self.backgroundColor = .clear
        self.addSubview(label)
        selectedLabel.isHidden = true

        self.canShowCallout = false
        self.tag = 200
    }

    func setTitle(forStation name: String) {

        selectedLabel.text = name
        selectedLabel.textAlignment = .center

        let textWidth = selectedLabel.text!.width(withConstrainedHeight: selectedLabel.frame.height, font: selectedLabel.font) * 1.2

        self.selectedLabel.frame = CGRect(x: 0, y: -50, width: textWidth, height: self.selectedLabel.frame.height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented!")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func draw(_ rect: CGRect) {
        guard UIGraphicsGetCurrentContext() != nil else { return }
    }

}
