//
//  File.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 15/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import ReactiveSwift
import ReactiveCocoa
import SpriteKit

extension RestorePurchasesViewController: IAPHelperDelegate {
    func previouslyPurchased(status: Bool) {
        restorePurchasesButton.isEnabled = status
    }

    func didFail(with error: String) {
        let alertController = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }
}

extension RestorePurchasesViewController: RestorePurchasesViewModelDelegate {
    func celebratePurchase() {

        restorePurchasesButton.isEnabled = false
        restorePurchasesButton.tintColor = .systemGray
        unlockFeaturesLabel.isEnabled = false
        unlockFeaturesLabel.tintColor = .systemGray

        DispatchQueue.main.async {
            self.purchaseStatusLabel.text = "HAS_PURCHASED".localize(file: "RestorePurchases")
        }

        FeedbackGenerator.sharedInstance.generator.impactOccurred()
        createParticles()

        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: {
            self.particleEmitter.removeFromSuperlayer()
        })
    }

    func updatePriceForIap(price: NSDecimalNumber) {
        DispatchQueue.main.async {
            self.unlockFeaturesLabel.titleLabel?.text = "UNLOCK_FEATURE_POST_LOAD".localize(file: "RestorePurchases").replacingOccurrences(of: "%price", with: "\(price)")
            self.unlockFeaturesLabel.sizeToFit()
        }
    }
}

class RestorePurchasesViewController: UIViewController {

    let compositeDisposable: CompositeDisposable
    let viewModel: RestorePurchasesViewModel
    let cViewModel: RestorePurchasesViewModel

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

    lazy var whyYouShouldGiveMeMoneyTextView: UITextView = {

        let textView = NBTextView(frame: .zero, textContainer: nil)
        textView.applyProtocolUIAppearance()
        textView.text = "GIVE_ME_YOUR_MONEY".localize(file: "RestorePurchases")

        return textView
    }()

    lazy var verticalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [titleLabel, whyYouShouldGiveMeMoneyTextView, donationsHorizontalStackView, restorePurchasesButton, purchaseStatusLabel])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.spacing = 32.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    lazy var donationsHorizontalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [unlockFeaturesLabel])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalSpacing

        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    lazy var titleLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.text = "RESTORE_PURCHASES_TITLE".localize(file: "RestorePurchases")
        label.textAlignment = .left
        label.font = UIFont.preferredFont(for: .title1, weight: .heavy)

        return label
    }()

    lazy var unlockFeaturesLabel: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.setTitle("UNLOCK_FEATURE_PRE_LOAD".localize(file: "RestorePurchases"), for: .normal)
        return button
    }()

    lazy var restorePurchasesButton: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.setTitle("RESTORE_PURCHASES".localize(file: "RestorePurchases"), for: .normal)
        return button
    }()

    lazy var purchaseStatusLabel: UILabel = {

        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.font = UIFont.preferredFont(for: .body, weight: .bold)
        label.text = "HAS_NOT_PURCHASED".localize(file: "RestorePurchases")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0

        return label
    }()

    let pullTabToDismissView: UIView = {

        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray
        view.layer.cornerRadius = 2.5
        return view
    }()

    let particles = GameScene()

    init(compositeDisposable: CompositeDisposable, viewModel: RestorePurchasesViewModel) {

        self.compositeDisposable = compositeDisposable
        self.viewModel = viewModel

        self.cViewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        self.viewModel.delegate = self
        StoreKitProducts.store.delegate = self
    }

    var activityIndicatorAlert: UIAlertController?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        view = UIView()
        view.backgroundColor = .systemBackground

        view.addSubview(pullTabToDismissView)
        scrollView.addSubview(verticalStackView)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            unlockFeaturesLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.spacing),
            unlockFeaturesLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Constants.spacing),
            restorePurchasesButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.spacing),
            restorePurchasesButton.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Constants.spacing)
        ])

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: Constants.spacing),
            scrollView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.spacing),
            scrollView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.spacing),
            scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.spacing)
        ])

        NSLayoutConstraint.activate([
            verticalStackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: self.view.frame.width - (2 * Constants.spacing))
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
            pullTabToDismissView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 16.0)
        ])

        NSLayoutConstraint.activate([
            purchaseStatusLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.spacing),
            purchaseStatusLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: Constants.spacing),
            whyYouShouldGiveMeMoneyTextView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.spacing),
            whyYouShouldGiveMeMoneyTextView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Constants.spacing)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpBindings()
    }

    func setUpBindings() {

        compositeDisposable += unlockFeaturesLabel.reactive.controlEvents(.touchUpInside).observeValues({ [weak self] (_) in
            FeedbackGenerator.sharedInstance.generator.impactOccurred()
            self?.viewModel.unlockDataInsights()
        })

        compositeDisposable += restorePurchasesButton.reactive.controlEvents(.touchUpInside).observe({ [weak self] (_) in

            FeedbackGenerator.sharedInstance.generator.impactOccurred()
            self?.viewModel.restorePurchases()
        })

        viewModel.hasPurchased.bind({ transaction in

            if transaction {
                self.viewModel.didSuccessfullyFinishStoreKitOperation()
                self.restorePurchasesButton.isEnabled = false
                self.unlockFeaturesLabel.isEnabled = false
            }
        })
    }

    deinit {
        compositeDisposable.dispose()
    }

    let particleEmitter = CAEmitterLayer()

    func createParticles() {

        particleEmitter.emitterPosition = CGPoint(x: view.center.x, y: -96)
        particleEmitter.emitterShape = .line
        particleEmitter.emitterSize = CGSize(width: view.frame.size.width, height: 1)

        let red = makeEmitterCell(color: UIColor.systemRed)
        let green = makeEmitterCell(color: UIColor.systemIndigo)
        let blue = makeEmitterCell(color: UIColor.systemOrange)

        particleEmitter.emitterCells = [red, green, blue]

         view.layer.insertSublayer(particleEmitter, at: 0)
    }

    func makeEmitterCell(color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 10
        cell.lifetime = 5.0
        cell.lifetimeRange = 0
        cell.color = color.cgColor
        cell.velocity = 200
        cell.velocityRange = 50
        cell.emissionLongitude = CGFloat.pi
        cell.emissionRange = CGFloat.pi / 4
        cell.spin = 2
        cell.spinRange = 3
        cell.scaleRange = 0.5
        cell.scaleSpeed = -0.05

        cell.contents = UIImage(named: "particle_confetti")?.cgImage
        return cell
    }
}
