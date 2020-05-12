//
//  LogInViewController.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 12/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift
import ReactiveCocoa

extension LogInViewController: LogInViewModelDelegate {
    func receivedError(with errorString: String) {
        
        
        let alert = UIAlertController(title: "header", message: errorString, preferredStyle: UIAlertController.Style.alert)

        let alertAction = UIAlertAction(title: "ACCEPT_ALERT".localize(file: "Home"), style: UIAlertAction.Style.default, handler: nil)

        alert.addAction(alertAction)

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

class LogInViewController: UIViewController {
 
    let compositeDisposable: CompositeDisposable
    let viewModel: LogInViewModel
    
    lazy var stackView: UIStackView = {
        let stackView = NBStackView(arrangedSubviews: [usernameTextField, passwordTextField, submitCredentialsButton])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.vertical
        return stackView
    }()
    
    lazy var usernameTextField: UITextField = {
        let textField = NBTextField()
        textField.applyProtocolUIAppearance()
        textField.placeholder = "Username"
        textField.text = ""
        textField.textContentType = .username
        return textField
    }()
    
    lazy var passwordTextField: UITextField = {
        let textField = NBTextField()
        textField.applyProtocolUIAppearance()
        textField.placeholder = "Password"
        textField.text = ""
        textField.textContentType = .password
        return textField
    }()
    
    lazy var submitCredentialsButton: UIButton = {
        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.setTitle("Submit Credentials", for: .normal)
        return button
    }()
    
    init(compositeDisposable: CompositeDisposable, viewModel: LogInViewModel) {
        self.compositeDisposable = compositeDisposable
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpBindings()
    }
    
    func setUpBindings() {
        compositeDisposable += submitCredentialsButton.reactive.controlEvents(.touchUpInside).observe({ [weak self] _ in
            
            guard let userName = self?.usernameTextField.text, let password = self?.passwordTextField.text else { return }
            
            let userCredentials = UserCredentials(mobile: userName, pin: password)
            
            self?.viewModel.logIn(with: userCredentials)
        })
    }
    
    override func loadView() {
        
        view = UIView()
        view.backgroundColor = .white
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            stackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
//            stackView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -16.0)
        ])
        
        NSLayoutConstraint.activate([
            usernameTextField.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 48.0),
            usernameTextField.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -48.0),
            passwordTextField.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 48.0),
            passwordTextField.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -48.0)
        ])
    }
}
