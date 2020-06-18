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
import CoreLocation

extension InsightsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mostUsedStations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = "\(Array(mostUsedStations.keys)[indexPath.row]) \(Array(mostUsedStations.values)[indexPath.row])"

        return cell
    }
}

extension InsightsViewController: UITableViewDelegate {

}

extension InsightsViewController: InsightsViewModelDelegate {
    func showMostUsedStations(stations: [String: Int]) {
        dump(stations)

        mostUsedStations = stations
        mostUsedTableView.reloadData()
    }

    func fillClosestStationInformation(station: BikeStation) {
        alternativeStationNameLabel.text = station.stationName

//        guard let location = LocationServices.sharedInstance.locationManager?.location else {
//            closestAnnotationCommentsLabel.text = "CLOSEST_ANNOTATION_DESCRIPTION_WO_LOCATION".localize(file: "RoutePlanner").replacingOccurrences(of: "%number", with: "\(Int(station.freeRacks))")
//            return
//        }

//        let distance = station.distance(to: location) / 1000
//
//        if distance > 10 {
//            closestAnnotationCommentsLabel.text = "CLOSEST_ANNOTATION_DESCRIPTION_WO_LOCATION".localize(file: "RoutePlanner").replacingOccurrences(of: "%number", with: "\(Int(station.freeRacks))")
//            return
//        }
//
//        closestAnnotationCommentsLabel.text = "CLOSEST_ANNOTATION_DESCRIPTION".localize(file: "RoutePlanner").replacingOccurrences(of: "%number", with: "\(Int(station.freeRacks))").replacingOccurrences(of: "%distance", with: "\(distance.rounded(toPlaces: 2))")

    }

    func updateBikeStationOperations(nextRefill: String?, nextDischarge: String?) {

        if let refillText = nextRefill {

            refillGrouperStackView.isHidden = false
            refillLabel.text = refillText
            refillGrouperStackView.accessibilityLabel = NSLocalizedString("NEXT_REFILL_ACCESIBILITY_LABEL", comment: "").replacingOccurrences(of: "%time", with: refillText)
            dockOperationsStackView.isHidden = false
        } else {
            refillGrouperStackView.isHidden = true
            dockOperationsStackView.isHidden = true
        }

        if let dischargeText = nextDischarge {
            dischargeGrouperStackView.isHidden = false
            dockOperationsStackView.isHidden = false
            dischargeLabel.text = dischargeText
        } else {
            dischargeGrouperStackView.isHidden = true
            dockOperationsStackView.isHidden = true
        }
    }

    func gotDestinationRoute(station: BikeStation, route: MKRoute) {

        self.verticalStackView.fadeIn(0.5, onCompletion: { })

        let calendar = Calendar.current
        let date = calendar.date(byAdding: .minute, value: route.expectedTravelTime.minutes, to: Date())

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let roundedArrivalTime = dateFormatter.string(from: date!)

        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .short
        formatter.locale = Locale(identifier: Locale.current.languageCode!)

        guard self.viewModel.destinationStation.value != nil else { return }

        currentHourLabel.text = "NOW".localize(file: "RoutePlanner") //"\(dateFormatter.string(from: Date()))"
        predictedDocksAtDestinationUnitsLabel.text = "\(roundedArrivalTime)"

        currentDocksLabel.text = "\(self.viewModel.destinationStation.value!.freeRacks)"
        destinationStationLabel.text = "\(self.viewModel.destinationStation.value!.stationName)"

        viewModel.calculateRmseForStationByQueryingPredictions(completion: {

            if let rmseOfStation = self.viewModel.destinationStation.value!.inverseAccuracyRmse {

                if !rmseOfStation.isNaN {

                    self.accuracyOfPredictionLabel.text = "ACCURACY_OF_MODEL".localize(file: "RoutePlanner").replacingOccurrences(of: "%percentage", with: "\(Int(rmseOfStation))")

                    // Warn the user of the low accuracy
                    if Int(rmseOfStation) < 50 {
                        self.accuracyOfPredictionLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: .bold)
                    }
                } else {
                    self.accuracyOfPredictionLabel.text = "ACCURACY_OF_MODEL_ERROR".localize(file: "RoutePlanner")
                }
            }

            if let destinationStation = self.viewModel.destinationStation.value {

                guard let predictionArray = destinationStation.predictionArray else { return }

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
                if (destinationStation.totalAvailableDocks - (destinationStation.totalAvailableDocks - predictionArray[indexOfTime])) < 4 {
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

        self.verticalStackView.fadeIn(0.5, onCompletion: nil)

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
                
                if predictionArray.count > 0 {
                    let remainderPredictionOfTheDay = predictionArray[(availabilityArray.count)...]
                    print(remainderPredictionOfTheDay.count)
                } else {
                    return
                }

                

                self.lowDockAvailabilityStackView.isHidden = false
                self.lowDockAvailabilityLabel.text = "TOO_FAR_AWAY_WARNING".localize(file: "RoutePlanner")
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        viewModel.drawDataWhateverImTired()
    }

    func presentAlertViewWithError(title: String, body: String) {

        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }
}

class InsightsViewController: UIViewController {

    let viewModel: InsightsViewModel
    let compositeDisposable: CompositeDisposable
    var filteredData: [String]

    var mostUsedStations: [String: Int] = [:]
    
    // MARK: Pull tab to dismiss
    
    let pullTabToDismissView: UIView = {

        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray
        view.layer.cornerRadius = 2.5
        view.accessibilityIdentifier = "PULL_DOWN_TAB"

        return view
    }()
    
    // MARK: Scroll View

    let scrollView: UIScrollView = {

        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.isDirectionalLockEnabled = true

        return scrollView
    }()
    
    lazy var viewControllerLabel: UILabel = {
       
        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.text = "INSIGHTS_LABEL".localize(file: "RoutePlanner")
        label.font = UIFont.preferredFont(for: .title1, weight: .heavy)
        label.textAlignment = .left
        
        return label
    }()
    
    // MARK: Vertical Stack View
    
    lazy var verticalStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [viewControllerLabel, mostUsedTableView, labelsDestinationStationVerticalStackView, selectedStationGrouperGrouperStackView, closestStationStackView])
        stackView.applyProtocolUIAppearance()
        stackView.alignment = .center
        
        stackView.axis = .vertical
        stackView.isHidden = true
        stackView.distribution  = .equalSpacing

        return stackView
    }()
    
    // MARK: Instructions header

    let instructionsHeaderTextView: UITextView = {

        let textView = NBTextView(frame: .zero, textContainer: nil)
        textView.applyProtocolUIAppearance()
        
        textView.text = "ROUTE_PLANNER_INSTRUCTIONS_TEXT_FIELD".localize(file: "RoutePlanner")
        return textView
    }()
    
    // MARK: Free docks at destination

    lazy var statisticsAndLowDockStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [statisticsVerticalStackView, lowDockAvailabilityStackView])
        stackView.applyProtocolUIAppearance()
        
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.isHidden = false
        stackView.addBackground(color: .systemGroupedBackground)

        return stackView
    }()

    lazy var statisticsVerticalStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [freeRacksOnDestinationVerticalStackView, arrowImageView, predictedDocksAtDestinationVerticalStackView])
        stackView.applyProtocolUIAppearance()
        
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.isHidden = false
        stackView.addBackground(color: UIColor.systemFill)

        return stackView
    }()

    let arrowImageView: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.right")
        imageView.contentMode = .center
        imageView.tintColor = Constants.imageTintColor
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    lazy var lowDockAvailabilityStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [lowDockAvailabilityImageView, lowDockAvailabilityLabel])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.isHidden = true

        return stackView
    }()

    let lowDockAvailabilityImageView: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.contentMode = .center
        imageView.tintColor = Constants.imageTintColor
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    let lowDockAvailabilityLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.text = "LOW_DOCK_AVAILABILITY_WARNING".localize(file: "RoutePlanner")
        label.textAlignment = .left

        return label
    }()

    lazy var freeRacksOnDestinationVerticalStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [currentHourLabel, currentDocksLabel])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.vertical

        return stackView
    }()

    lazy var currentDocksLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.text = "..."
        label.adjustsFontForContentSizeCategory = true
//        label.textAlignment = .center
        return label
    }()

    lazy var currentHourLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.text = "START_TIME_COMMUTE".localize(file: "RoutePlanner")
        label.tintColor = .systemGray
        label.textAlignment = .center
        label.font = UIFont.preferredFont(for: .body, weight: .bold)
//        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)

        return label
    }()

    lazy var accuracyOfPredictionLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.text = "LOADING_PREDICTIONS".localize(file: "RoutePlanner")
//        label.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
        
        return label
    }()
    
    // MARK: Selected station
    lazy var selectedStationGrouperGrouperStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [selectedStationGrouperStackView, dockOperationsStackView, statisticsAndLowDockStackView])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.addBackground(color: .systemGroupedBackground)

        return stackView
    }()
    
    lazy var selectedStationGrouperStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [selectedStationImageView, selectedStationDetailsStackView])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.addBackground(color: .systemGroupedBackground)

        return stackView
    }()

    let selectedStationImageView: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin")
        imageView.contentMode = .center
        imageView.tintColor = Constants.imageTintColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layoutIfNeeded()

        return imageView
    }()

    lazy var dockOperationsStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [refillGrouperStackView, dischargeGrouperStackView])
        stackView.applyProtocolUIAppearance()
        stackView.alignment = UIStackView.Alignment.leading
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.isHidden = true
        stackView.addBackground(color: UIColor.secondarySystemFill)

        return stackView
    }()

    lazy var dischargeGrouperStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [dischargeImageView, dischargeLabel])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.isHidden = true
        return stackView
    }()

    let dischargeImageView: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.down")
        imageView.contentMode = .center
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    let dischargeLabel: UILabel = {
        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.text = "Next refill time"
        label.textAlignment = .left


        return label
    }()

    lazy var refillGrouperStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [refillImageView, refillLabel])
        stackView.applyProtocolUIAppearance()
        stackView.isHidden = true
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.alignment = .leading
        return stackView
    }()

    let refillImageView: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.up")
        imageView.contentMode = .center
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    let refillLabel: UILabel = {
        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.text = "DISCHARGE".localize(file: "RoutePlanner")
        label.textAlignment = .natural

        return label
    }()

    lazy var labelsDestinationStationVerticalStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [selectedStationGrouperStackView])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.vertical
        return stackView

    }()

    lazy var selectedStationDetailsStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [destinationStationLabel, accuracyOfPredictionLabel])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.alignment = .leading

        return stackView

    }()

    private lazy var destinationStationLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.text = "Station Name"
        label.font = UIFont.preferredFont(for: .body, weight: .heavy)
        label.textAlignment = .left
//        label.font = UIFont.preferredFont(forTextStyle: .title1)

        return label
    }()

    lazy var predictedDocksAtDestinationVerticalStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [predictedDocksAtDestinationUnitsLabel, predictedDocksAtDestinationLabel])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.vertical

        return stackView
    }()

    lazy var predictedDocksAtDestinationLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.font = Constants.labelFont
        label.accessibilityIdentifier = "DESTINATION_BIKES"
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = "..."

        return label
    }()

    lazy var predictedDocksAtDestinationUnitsLabel: UILabel = {
        
        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.textAlignment = .center
        label.text = "END_TIME_COMMUTE".localize(file: "RoutePlanner")
        label.tintColor = .systemGray
        label.font = UIFont.preferredFont(for: .body, weight: .bold)
        
        return label
    }()

    lazy var closestStationStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [alternativeStationComments, closestStationWrapperStackView])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.alignment = .leading
        return stackView
    }()

    lazy var closestStationWrapperStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [alternativeStationIcon, closestStationInnerStackView])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.horizontal

        return stackView
    }()

    lazy var closestStationInnerStackView: UIStackView = {

        let stackView = NBStackView(arrangedSubviews: [alternativeStationNameLabel, closestAnnotationCommentsLabel])
        stackView.applyProtocolUIAppearance()
        
        stackView.axis = NSLayoutConstraint.Axis.vertical
        return stackView
    }()

    lazy var alternativeStationNameLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.textAlignment = .center
        label.text = "Station Name"
        label.tintColor = .systemGray
        label.textAlignment = .left

        return label
    }()

    lazy var alternativeStationIcon: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "hand.point.right.fill")?.withAlignmentRectInsets(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: -10))
        imageView.contentMode = .center
        imageView.tintColor = .systemGray
        return imageView
    }()

    lazy var alternativeStationComments: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.tintColor = .systemGray
        label.text = "CLOSEST_ANNOTATION_HEADER".localize(file: "RoutePlanner")
        return label
    }()

    lazy var closestAnnotationCommentsLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.textAlignment = .left
        label.tintColor = .systemGray
        return label
    }()

    // MARK: Most used stations

    lazy var mostUsedTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false

        return tableView
    }()

    init(viewModel: InsightsViewModel, compositeDisposable: CompositeDisposable) {

        self.viewModel = viewModel
        self.compositeDisposable = compositeDisposable
        self.filteredData = []

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var keyCommands: [UIKeyCommand]? {
           return [
               UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .command, action: #selector(dismiss(animated:completion:)
                   ), discoverabilityTitle: "CLOSE_INSIGHTS_KEYBOARD".localize(file: "RoutePlanner"))
           ]
       }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc private func viewHoverChanged(_ gesture: UIHoverGestureRecognizer, _ sender: UIButton) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction], animations: {
            switch gesture.state {
            case .began, .changed:
                sender.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1)
            case .ended:
                sender.layer.transform = CATransform3DIdentity
            default: break
            }
        }, completion: nil)
    }

    override func loadView() {

        super.loadView()

        view = UIView()
        view.backgroundColor = .systemBackground

        scrollView.addSubview(verticalStackView)
        view.addSubview(scrollView)
        view.addSubview(pullTabToDismissView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: Constants.spacing),
            scrollView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.spacing),
            scrollView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.spacing),
            scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.spacing)
        ])

        NSLayoutConstraint.activate([
            verticalStackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: self.view.frame.width - 2 * Constants.spacing)
        ])
        
        NSLayoutConstraint.activate([
            viewControllerLabel.leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor, constant: 2 * Constants.spacing)
        ])

        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Constants.spacing),
            verticalStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0),
            verticalStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0),
            verticalStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20.0)
        ])

        NSLayoutConstraint.activate([
            pullTabToDismissView.heightAnchor.constraint(equalToConstant: 6),
            pullTabToDismissView.widthAnchor.constraint(equalToConstant: 60),
            pullTabToDismissView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            pullTabToDismissView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: Constants.spacing)
        ])

        NSLayoutConstraint.activate([
            selectedStationImageView.widthAnchor.constraint(equalToConstant: 50.0),
            selectedStationImageView.heightAnchor.constraint(equalTo: selectedStationDetailsStackView.heightAnchor, constant: Constants.spacing)
        ])

        NSLayoutConstraint.activate([
            currentHourLabel.widthAnchor.constraint(equalToConstant: 100.0),
            predictedDocksAtDestinationUnitsLabel.widthAnchor.constraint(equalToConstant: 100.0)
        ])

        NSLayoutConstraint.activate([
            currentDocksLabel.centerXAnchor.constraint(equalTo: currentHourLabel.centerXAnchor),
            predictedDocksAtDestinationLabel.centerXAnchor.constraint(equalTo: predictedDocksAtDestinationUnitsLabel.centerXAnchor)
        ])

        NSLayoutConstraint.activate([
            lowDockAvailabilityLabel.centerYAnchor.constraint(equalTo: lowDockAvailabilityImageView.centerYAnchor),
            lowDockAvailabilityImageView.widthAnchor.constraint(equalToConstant: 80.0),
            lowDockAvailabilityLabel.leadingAnchor.constraint(equalTo: lowDockAvailabilityImageView.trailingAnchor),
            lowDockAvailabilityImageView.heightAnchor.constraint(equalTo: lowDockAvailabilityLabel.heightAnchor, constant: Constants.spacing)
        ])

        // MARK: UITableView constraints
        NSLayoutConstraint.activate([
            mostUsedTableView.leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor, constant: Constants.spacing),
            mostUsedTableView.trailingAnchor.constraint(equalTo: verticalStackView.trailingAnchor, constant: -Constants.spacing),
            mostUsedTableView.heightAnchor.constraint(equalToConstant: 80.0)
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
