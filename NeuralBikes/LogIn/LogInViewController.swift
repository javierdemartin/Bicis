//
//  LogInViewController.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 12/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import Combine
import UIKit

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
 
    let viewModel: LogInViewModel
    
    lazy var stackView: UIStackView = {
        let stackView = NBStackView(arrangedSubviews: [titleLabel, usernameTextField, passwordTextField, submitCredentialsButton, forgotPasswordButton, explanationTextView])
        stackView.applyProtocolUIAppearance()
        stackView.axis = NSLayoutConstraint.Axis.vertical
        return stackView
    }()
    
    lazy var titleLabel: UILabel = {
       
        let label = NBLabel()
        label.applyProtocolUIAppearance()
        label.font = UIFont.systemFont(ofSize: 23, weight: .heavy)
        label.text = "LOG_IN_TITLE_LABEL".localize(file: "LogIn")
        return label
    }()
    
    lazy var usernameTextField: UITextField = {
        let textField = NBTextField()
        textField.applyProtocolUIAppearance()
        textField.placeholder = "USERNAME_PLACEHOLDER".localize(file: "LogIn")
        textField.text = ""
        textField.textContentType = .username
        return textField
    }()
    
    lazy var explanationTextView: UITextView = {
       
        let textView = NBTextView(frame: .zero, textContainer: nil)
        textView.applyProtocolUIAppearance()
        textView.text = "LOG_IN_EXPLANATION".localize(file: "LogIn")
        return textView
    }()
    
    lazy var passwordTextField: UITextField = {
        let textField = NBTextField()
        textField.applyProtocolUIAppearance()
        textField.placeholder = "PASSWORD_PLACEHOLDER".localize(file: "LogIn")
        textField.text = ""
        textField.textContentType = .password
        return textField
    }()
    
    lazy var submitCredentialsButton: UIButton = {
        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.setTitle("SUBMIT_CREDENTIALS_BUTTON".localize(file: "LogIn"), for: .normal)
        return button
    }()
    
    lazy var forgotPasswordButton: UIButton = {
       
        let button = NBButton()
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitle("FORGOT_PASSWORD_BUTTON".localize(file: "LogIn"), for: .normal)
        
        return button
    }()
    
    init(viewModel: LogInViewModel) {
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
    
    
    var cancellableBag = Set<AnyCancellable>()
    
    func setUpBindings() {
        
        submitCredentialsButton.publisher(for: .touchUpInside).sink { _ in
            guard let userName = self.usernameTextField.text, let password = self.passwordTextField.text else { return }
            
            let userCredentials = UserCredentials(mobile: userName, pin: password)
            
            self.viewModel.logIn(with: userCredentials)
        }.store(in: &cancellableBag)
        
        forgotPasswordButton.publisher(for: .touchUpInside).sink { _ in
            
            guard let userName = self.usernameTextField.text else { return }
            
            self.viewModel.forgotPassword(username: userName)
        }.store(in: &cancellableBag)
    }
    
    override func loadView() {
        
        view = UIView()
        view.backgroundColor = .white
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            stackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])
        
        NSLayoutConstraint.activate([
            usernameTextField.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 48.0),
            usernameTextField.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -48.0),
            passwordTextField.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 48.0),
            passwordTextField.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -48.0)
        ])
    }
}
