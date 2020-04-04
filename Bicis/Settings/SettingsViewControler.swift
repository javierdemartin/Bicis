//
//  CityViewControler.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/12/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import CoreLocation
import StoreKit

extension SettingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return citiesList.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return citiesList[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        viewModel.changedCityInPickerView(city: citiesList[row])
        self.viewModel.city = availableCities[citiesList[row]]
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .bold)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = citiesList[row]

        return pickerLabel!
    }
}

class SettingsViewController: UIViewController {

    var citiesList = Array(availableCities.keys)

    let compositeDisposable: CompositeDisposable

    let viewModel: SettingsViewModel

    let pullTabToDismissView: UIView = {

        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray
        view.layer.cornerRadius = 2.5
        return view
    }()

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

    lazy var verticalStackView: UIStackView = {

//        let stackView = UIStackView(arrangedSubviews: [pullTabToDismissView, locationServicesStackView, stringVersion, requestFeedBackButton, logInPrivacyTextView, cityPicker, locationServicesExplanationTextView, restorePurchasesButton])
        let stackView = UIStackView(arrangedSubviews: [pullTabToDismissView, locationServicesStackView, stringVersion, requestFeedBackButton, logInPrivacyTextView, cityPicker, locationServicesExplanationTextView])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    lazy var imageIcon: UIImageView = {

        let image = UIImage(named: "AppIcon60x60")
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        imageView.layer.cornerRadius = 9.0
        imageView.isUserInteractionEnabled = true
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var stringVersion: UILabel = {

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .bold)
        label.numberOfLines = 0

        return label
    }()

    lazy var titleLabel: UILabel = {

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .heavy)
        label.numberOfLines = 0
        label.text = "TITLE_LABEL_HEADER".localize(file: "Settings")

        return label
    }()

    lazy var logInPrivacyTextView: UITextView = {

        let textView = UITextView(frame: .zero, textContainer: nil)
        textView.backgroundColor = .clear
        textView.isSelectable = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .bold)
        textView.text = "HOW_TO_USE".localize(file: "Settings")

        return textView
    }()

    lazy var locationServicesStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [self.imageIcon, locationServicesStatusImage])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.alignment = .bottom
        stackView.spacing = -10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var cityPicker: UIPickerView = {

        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.delegate = self
        picker.dataSource = self
        picker.sizeToFit()

        return picker
    }()

    lazy var requestLocationServicesButton: UIButton = {

        let button = UIButton()
        button.setTitleColor(.black, for: .normal)
        button.setTitle("REQUEST_LOCATION_SERVICES_BUTTON".localize(file: "Settings"), for:
            .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var restorePurchasesButton: UIButton = {

        let button = UIButton()
        button.setTitleColor(.black, for: .normal)
        button.setTitle("RESTORE_PURCHASES_BUTTON".localize(file: "Settings"), for:
            .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 4

        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var requestFeedBackButton: UIButton = {

        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.setTitle("FEEDBACK_BUTTON".localize(file: "Settings"), for: .normal)
        button.layer.cornerRadius = 4
        button.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: .bold)
        button.backgroundColor = UIColor.systemBlue
        button.sizeToFit()

        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var locationServicesStatusImage: UIImageView = {

        let image = UIImage(systemName: "location.slash.fill")
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        imageView.layer.cornerRadius = 9.0
        imageView.isUserInteractionEnabled = true
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var locationServicesExplanationTextView: UITextView = {

        let textView = UITextView(frame: .zero, textContainer: nil)
        textView.backgroundColor = .clear
        textView.isSelectable = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .bold)
        textView.text = "LOCATION_SERVICES_PRIVACY".localize(file: "Settings")

        return textView
    }()

    init(viewModel: SettingsViewModel, compositeDisposable: CompositeDisposable) {

        self.viewModel = viewModel
        self.compositeDisposable = compositeDisposable

        super.init(nibName: nil, bundle: nil)

        LocationServices.sharedInstance.delegate = self
        LocationServices.sharedInstance.startUpdatingLocation()
    }

    @objc func askForReview(_ sender: UITapGestureRecognizer) {
        SKStoreReviewController.requestReview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {

        super.loadView()

        view = UIView()
        view.backgroundColor = .systemBackground

        scrollView.addSubview(verticalStackView)
        view.addSubview(scrollView)

        let askForReviewTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(askForReview(_:)))
        imageIcon.addGestureRecognizer(askForReviewTapRecognizer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 16.0),
            scrollView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            scrollView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -16.0)
        ])

        NSLayoutConstraint.activate([
            verticalStackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: self.view.frame.width - 32.0)
        ])

        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0),
            verticalStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0),
            verticalStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0),
            verticalStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20.0)
        ])

        NSLayoutConstraint.activate([
            pullTabToDismissView.heightAnchor.constraint(equalToConstant: 5),
            pullTabToDismissView.widthAnchor.constraint(equalToConstant: 40),
            pullTabToDismissView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        ])

        NSLayoutConstraint.activate([
            cityPicker.leadingAnchor.constraint(equalTo: self.verticalStackView.leadingAnchor, constant: 16.0),
            cityPicker.trailingAnchor.constraint(equalTo: self.verticalStackView.trailingAnchor, constant: -16.0)
        ])

        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }

        guard let bundleString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else { return }

        stringVersion.text = "\(versionString)" + " (" + "\(bundleString)" + ")"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.prepareViewForAppearance()

        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                locationServicesStatusImage.image = UIImage(systemName: "location.slash.fill")
            case .authorizedAlways, .authorizedWhenInUse:
                locationServicesStatusImage.image = UIImage(systemName: "location.fill")
            @unknown default:
                break
            }
        } else {
            print("Location services are not enabled")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBindings()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.dismissingSettingsViewController()

    }

    fileprivate func setupBindings() {

        compositeDisposable += requestLocationServicesButton.reactive.controlEvents(.touchUpInside).observe({ (_) in
            print("\(#file) \(#function)")
        })

        compositeDisposable += requestFeedBackButton.reactive.controlEvents(.touchUpInside).observe({ [weak self] (_) in
            self?.viewModel.sendFeedBackEmail()
        })

        viewModel.availableCitiesModel.bind { cities in
            self.citiesList = cities
        }

        compositeDisposable += restorePurchasesButton.reactive.controlEvents(.touchUpInside).observe({ [weak self] (_) in
            self?.dismiss(animated: true, completion: {
                self?.viewModel.presentRestorePurchasesViewControllerFromCoordinatorDelegate()
            })
        })
    }

    deinit {
        compositeDisposable.dispose()
    }
}

extension SettingsViewController: LocationServicesDelegate {

    func tracingLocation(_ currentLocation: CLLocation) {
        locationServicesStatusImage.image = UIImage(systemName: "location.fill")
    }

    func tracingLocationDidFailWithError(_ error: NSError) {
        print(error)
    }
}

extension SettingsViewController: SettingsViewModelDelegate {
    func selectCityInPickerView(city: String) {
        guard let firstIndex = citiesList.firstIndex(of: city) else { return }

        self.cityPicker.selectRow(firstIndex, inComponent: 0, animated: true)
        self.pickerView(self.cityPicker, didSelectRow: firstIndex, inComponent: 0)
    }

    func updateCitiesPicker(sortedCities: [String]) {
        cityPicker.reloadAllComponents()
    }

    func updateLocationServicesStatusLabel(isGranted: Bool) {

        if isGranted {
            locationServicesStatusImage.image = UIImage(systemName: "location.fill")
        } else {
            locationServicesStatusImage.image = UIImage(systemName: "location.slash.fill")
        }
    }

    func errorSubmittingCode(with errorString: String) {
        let alert = UIAlertController(title: "ALERT_HEADER", message: errorString, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "CONFIRM_ALERT", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func presentAlertViewWithError(title: String, body: String) {

        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }
}
