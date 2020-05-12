//
//  LogInViewModel.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 12/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import ReactiveSwift

protocol LogInViewModelDataManager: class {
    func logIn(with userCredentials: UserCredentials, completion: @escaping(Result<LogInResponse>) -> Void)
}

protocol LogInViewModelDelegate: class {
    func receivedError(with errorString: String)
}

protocol LogInVieWModelCoordinatorDelegate: class {
    func dismissViewController()
}

class LogInViewModel {
    
    let compositeDisposable: CompositeDisposable
    let dataManager: LogInViewModelDataManager
    
    weak var delegate: LogInViewModelDelegate?
    weak var coordinatorDelegate: LogInVieWModelCoordinatorDelegate?
    
    init(compositeDisposable: CompositeDisposable, dataManager: LogInViewModelDataManager) {
        self.compositeDisposable = compositeDisposable
        self.dataManager = dataManager
    }
    
    func logIn(with credentials: UserCredentials) {
     
        dataManager.logIn(with: credentials, completion: { loginResult in
            switch loginResult {
                
            case .success(let data):
                print(data)
                
                self.coordinatorDelegate?.dismissViewController()
            case .error(let error):
                print(error)
                self.delegate?.receivedError(with: error.localizedDescription)
            }
        })
    }

}
