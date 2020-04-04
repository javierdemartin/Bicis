//
//  RoutePlannerViewController.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 09/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ReactiveSwift
import UIKit
import MapKit

extension RoutePlannerViewController: RoutePlannerViewModelDelegate {

    func gotDestinationRoute(station: BikeStation, route: MKRoute) {

        self.informationVerticalStackView.fadeIn(0.5, onCompletion: { })

        let calendar = Calendar.current
        let date = calendar.date(byAdding: .minute, value: route.expectedTravelTime.minutes, to: Date())

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        let roundedArrivalTime = dateFormatter.string(from: date!)

        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .short
        formatter.locale = Locale(identifier: Locale.current.languageCode!)

        guard self.viewModel.destinationStation.value != nil else { return }

        currentHourLabel.text = "\(dateFormatter.string(from: Date()))"
        predictedDocksAtDestinationUnitsLabel.text = "\(roundedArrivalTime)"

        currentDocksLabel.text = "\(self.viewModel.destinationStation.value!.freeRacks)"
        destinationStationLabel.text = "\(self.viewModel.destinationStation.value!.stationName)"

        viewModel.calculateRmseForStationByQueryingPredictions(completion: {

            if let rmseOfStation = self.viewModel.destinationStation.value!.inverseAccuracyRmse {

                self.accuracyOfPredictionLabel.text = "ACCURACY_OF_MODEL".localize(file: "RoutePlanner").replacingOccurrences(of: "%percentage", with: "\(Int(rmseOfStation))")

                // Warn the user of the low accuracy
                if Int(rmseOfStation) < 50 {
                    self.accuracyOfPredictionLabel.textColor = .systemRed
                    self.accuracyOfPredictionLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: .bold)
                }
            }

            if let destinationStation = self.viewModel.destinationStation.value {

                guard let availabilityArray = destinationStation.availabilityArray else { return }
                guard let predictionArray = destinationStation.predictionArray else { return }

                let remainderPredictionOfTheDay = predictionArray[(availabilityArray.count)...]

                // Current time
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm"

                // Replace last character by a 0, round to the nearest 10' interval
                var roundedArrivalTime = dateFormatter.string(from: Date())
                var arrayCharsOfTime = Array(roundedArrivalTime)
                arrayCharsOfTime[arrayCharsOfTime.count - 1] = "0"

                roundedArrivalTime = String(arrayCharsOfTime)

                guard let indexOfTime = Constants.listHours.firstIndex(of: roundedArrivalTime) else { return }

                // Calculate the availability at arrival
                self.predictedDocksAtDestinationLabel.text = "\(destinationStation.totalAvailableDocks - predictionArray[indexOfTime])"

                // Predicted available docks = Docks(t) - (Available docks - BikePredictions(t))
                if (destinationStation.totalAvailableDocks - (destinationStation.totalAvailableDocks - predictionArray[indexOfTime])) < 4  {
                    self.lowDockAvailabilityLabel.text = "LOW_DOCK_AVAILABILITY_WARNING".localize(file: "RoutePlanner")
                    self.lowDockAvailabilityLabel.fadeIn()
                }
            }
        })
    }

    func errorTooFarAway() {

        let dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm"
            return dateFormatter
        }()

        self.informationVerticalStackView.fadeIn(0.5, onCompletion: nil)

        guard let stationDestination = self.viewModel.destinationStation.value else { return }

        currentHourLabel.text = "\(dateFormatter.string(from: Date()))"
        predictedDocksAtDestinationUnitsLabel.text = "Too far"
        currentDocksLabel.text = "\(stationDestination.freeRacks)"
        predictedDocksAtDestinationLabel.text = "?"
        destinationStationLabel.text = "\(stationDestination.stationName)"

        // Only get the prediction
        self.lowDockAvailabilityLabel.text = "TOO_FAR_AWAY_WARNING".localize(file: "RoutePlanner")

        viewModel.calculateRmseForStationByQueryingPredictions(completion: {

            if let rmseOfStation = self.viewModel.destinationStation.value!.inverseAccuracyRmse {

                self.accuracyOfPredictionLabel.text = "ACCURACY_OF_MODEL".localize(file: "RoutePlanner").replacingOccurrences(of: "%percentage", with: "\(Int(rmseOfStation))")

                if Int(rmseOfStation) < 50 {
                    self.accuracyOfPredictionLabel.textColor = .systemRed
                    self.accuracyOfPredictionLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: .bold)
                }
            }

            if let destinationStation = self.viewModel.destinationStation.value {

                guard let availabilityArray = destinationStation.availabilityArray else { return }
                guard let predictionArray = destinationStation.predictionArray else { return }

                let remainderPredictionOfTheDay = predictionArray[(availabilityArray.count)...]
                print(remainderPredictionOfTheDay.count)

                self.lowDockAvailabilityStackView.isHidden = false
                self.lowDockAvailabilityLabel.text = "TOO_FAR_AWAY_WARNING".localize(file: "RoutePlanner")
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.drawDataWhateverImTired()
    }

    func presentAlertViewWithError(title: String, body: String) {

        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }
}

class RoutePlannerViewController: UIViewController {

    let viewModel: RoutePlannerViewModel
    let compositeDisposable: CompositeDisposable
    var filteredData: [String]

    let pullTabToDismissView: UIView = {

        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray
        view.layer.cornerRadius = 2.5
        return view
    }()

    let instructionsHeaderTextView: UITextView = {

        let textView = UITextView(frame: .zero, textContainer: nil)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.isSelectable = false
        textView.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .bold)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.sizeToFit()
        textView.isUserInteractionEnabled = true
        textView.text = "ROUTE_PLANNER_INSTRUCTIONS_TEXT_FIELD".localize(file: "RoutePlanner")
        return textView
    }()

    lazy var containerStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [informationVerticalStackView])
        stackView.alignment = UIStackView.Alignment.top
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    lazy var informationVerticalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [instructionsHeaderTextView, labelsDestinationStationVerticalStackView, statisticsAndLowDockStackView])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.isHidden = true
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.spacing = 25.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    lazy var statisticsAndLowDockStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [statisticsVerticalStackView, lowDockAvailabilityStackView])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.isHidden = false
        stackView.addBackground(color: .systemGroupedBackground)
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 25.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    lazy var statisticsVerticalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [freeRacksOnDestinationVerticalStackView, arrowImageView, predictedDocksAtDestinationVerticalStackView])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.isHidden = false
        stackView.distribution  = UIStackView.Distribution.equalSpacing

        stackView.spacing = 32.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    let arrowImageView: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.right")
        imageView.contentMode = .center
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

//    lazy var docksTextLabel: UILabel = {
//
//        let label = UILabel()
//        label.text = "DESTINATION_DOCKS_LABEL".localize(file: "RoutePlanner")
//        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .bold)
//        label.translatesAutoresizingMaskIntoConstraints = false
//
//        return label
//    }()

    lazy var lowDockAvailabilityStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [lowDockAvailabilityImageView, lowDockAvailabilityLabel])
        stackView.alignment = UIStackView.Alignment.leading
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 10.0
        stackView.isHidden = true
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    let lowDockAvailabilityImageView: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.contentMode = .center
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    let lowDockAvailabilityLabel: UITextView = {

        let textView = UITextView(frame: .zero, textContainer: nil)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.isSelectable = false
        textView.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .bold)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.sizeToFit()
        textView.isUserInteractionEnabled = true
        textView.text = "LOW_DOCK_AVAILABILITY_WARNING".localize(file: "RoutePlanner")

        return textView
    }()

    lazy var freeRacksOnDestinationVerticalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [currentHourLabel, currentDocksLabel])
        stackView.alignment = UIStackView.Alignment.center
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 15.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    lazy var currentDocksLabel: UILabel = {

        let label = UILabel()
        label.text = "..."
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    lazy var currentHourLabel: UILabel = {

        let label = UILabel()
        label.text = "START_TIME_COMMUTE".localize(file: "RoutePlanner")
        label.tintColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
//        label.lineBreakMode = .byClipping
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    lazy var accuracyOfPredictionLabel: UILabel = {

        let label = UILabel()
        label.text = "LOADING_PREDICTIONS".localize(file: "RoutePlanner")
        label.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var destinationStationStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [destinationStationImageView, destinationStationLabel])

        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    let destinationStationImageView: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin")
        imageView.contentMode = .center
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    lazy var labelsDestinationStationVerticalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [destinationStationStackView, accuracyOfPredictionLabel])
        stackView.alignment = UIStackView.Alignment.top
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView

    }()

    let destinationStationLabel: UILabel = {

        let label = UILabel()
        label.text = "Station Name"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)

        return label
    }()

    lazy var predictedDocksAtDestinationVerticalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [predictedDocksAtDestinationUnitsLabel, predictedDocksAtDestinationLabel])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 15.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    lazy var predictedDocksAtDestinationLabel: UILabel = {

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "DESTINATION_BIKES"
        label.textAlignment = .center
        label.text = "..."

        return label
    }()

    lazy var predictedDocksAtDestinationUnitsLabel: UILabel = {

        let label = UILabel()
        label.textAlignment = .center
        label.text = "END_TIME_COMMUTE".localize(file: "RoutePlanner")
        label.tintColor = .systemGray
        label.numberOfLines = 0
//        label.lineBreakMode = .byClipping
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false

            return label
        }()

    init(viewModel: RoutePlannerViewModel, compositeDisposable: CompositeDisposable) {

        self.viewModel = viewModel
        self.compositeDisposable = compositeDisposable
        self.filteredData = []

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {

        super.loadView()

        view = UIView()
        view.backgroundColor = .systemBackground

        view.addSubview(pullTabToDismissView)
        view.addSubview(containerStackView)

        NSLayoutConstraint.activate([
            pullTabToDismissView.heightAnchor.constraint(equalToConstant: 5),
            pullTabToDismissView.widthAnchor.constraint(equalToConstant: 40),
            pullTabToDismissView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            pullTabToDismissView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 16.0)
        ])

        NSLayoutConstraint.activate([
            destinationStationStackView.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor, constant: 32.0)
        ])

        NSLayoutConstraint.activate([
            destinationStationImageView.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor, constant: 16.0),
            destinationStationLabel.leadingAnchor.constraint(equalTo: destinationStationImageView.trailingAnchor, constant: 16.0)
        ])

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: pullTabToDismissView.bottomAnchor, constant: 16.0),
            containerStackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            containerStackView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
//            containerStackView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -16.0)
        ])

        NSLayoutConstraint.activate([
//            currentHourLabel.widthAnchor.constraint(equalToConstant:
//                (currentHourLabel.text?.width(withConstrainedHeight: currentHourLabel.frame.height + 20.0, font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)))! + 30.0),
//            predictedDocksAtDestinationUnitsLabel.widthAnchor.constraint(equalToConstant: (predictedDocksAtDestinationUnitsLabel.text?.width(withConstrainedHeight: predictedDocksAtDestinationUnitsLabel.frame.height + 20.0, font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)))! + 30.0)

            currentHourLabel.widthAnchor.constraint(equalToConstant: 100.0),
            predictedDocksAtDestinationUnitsLabel.widthAnchor.constraint(equalToConstant: 100.0),
//            currentDocksLabel.widthAnchor.constraint(equalToConstant: 100.0),
//            predictedDocksAtDestinationUnitsLabel.widthAnchor.constraint(equalToConstant: 100.0),
        ])

        NSLayoutConstraint.activate([
            currentDocksLabel.centerXAnchor.constraint(equalTo: currentHourLabel.centerXAnchor),
            predictedDocksAtDestinationLabel.centerXAnchor.constraint(equalTo: predictedDocksAtDestinationUnitsLabel.centerXAnchor)
        ])

        NSLayoutConstraint.activate([
            predictedDocksAtDestinationVerticalStackView.topAnchor.constraint(equalTo: statisticsVerticalStackView.topAnchor, constant: 16.0)
        ])

        NSLayoutConstraint.activate([
            destinationStationLabel.heightAnchor.constraint(equalToConstant: 100.0)
        ])

        NSLayoutConstraint.activate([
            lowDockAvailabilityStackView.leadingAnchor.constraint(equalTo: statisticsAndLowDockStackView.leadingAnchor, constant: 0),
            lowDockAvailabilityStackView.trailingAnchor.constraint(equalTo: statisticsAndLowDockStackView.trailingAnchor, constant: 0),
            lowDockAvailabilityStackView.topAnchor.constraint(equalTo: statisticsVerticalStackView.bottomAnchor, constant: 0)
        ])

        NSLayoutConstraint.activate([
            lowDockAvailabilityImageView.centerYAnchor.constraint(equalTo: lowDockAvailabilityLabel.centerYAnchor),
            lowDockAvailabilityImageView.widthAnchor.constraint(equalToConstant: 80.0),
            lowDockAvailabilityLabel.leadingAnchor.constraint(equalTo: lowDockAvailabilityImageView.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            instructionsHeaderTextView.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
        ])

        NSLayoutConstraint.activate([
            currentHourLabel.bottomAnchor.constraint(equalTo: currentDocksLabel.topAnchor, constant: -32),
            predictedDocksAtDestinationUnitsLabel.bottomAnchor.constraint(equalTo: predictedDocksAtDestinationLabel.topAnchor, constant: -32),
        ])

        NSLayoutConstraint.activate([
            destinationStationStackView.bottomAnchor.constraint(equalToSystemSpacingBelow: accuracyOfPredictionLabel.topAnchor, multiplier: -16.0)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.delegate = self

        setUpBindings()
    }

    func setUpBindings() {
    }
}
