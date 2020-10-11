//
//  LogInViewModel.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 12/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation


protocol LogInViewModelDataManager: class {
    func logIn(with userCredentials: UserCredentials, completion: @escaping(Result<LogInResponse>) -> Void)
    func forgotPassword(username: String, completion: @escaping(Result<Void>) -> Void)
}

protocol LogInViewModelDelegate: class {
    func receivedError(with errorString: String)
}

protocol LogInVieWModelCoordinatorDelegate: class {
    func dismissViewController()
}

class LogInViewModel {
    
    let dataManager: LogInViewModelDataManager
    
    weak var delegate: LogInViewModelDelegate?
    weak var coordinatorDelegate: LogInVieWModelCoordinatorDelegate?
    
    init(dataManager: LogInViewModelDataManager) {
        self.dataManager = dataManager
    }
    
    func logIn(with credentials: UserCredentials) {
     
        dataManager.logIn(with: credentials, completion: { [weak self] loginResult in
            
            guard let self = self else { fatalError() }
            
            switch loginResult {
                
            case .success:
                self.coordinatorDelegate?.dismissViewController()
            case .error(let error):
                self.delegate?.receivedError(with: error.localizedDescription)
            }
        })
    }
    
    func forgotPassword(username: String) {
        dataManager.forgotPassword(username: username, completion: { forgotResult in
            switch forgotResult {
                
            case .success:
                self.delegate?.receivedError(with: NSLocalizedString("FINISH_FORGOT_PASSWORD", comment: ""))
            case .error(let error):
                self.delegate?.receivedError(with: error.localizedDescription)
            }
        })
    }
    
    deinit {
        
    }

}
