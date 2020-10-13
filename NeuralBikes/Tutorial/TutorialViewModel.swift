//
//  TutorialViewModel.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 05/07/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import Combine

protocol TutorialViewModelCoordinatorDelegate: class {
    func didTapFinishTutorial()
}

protocol TutorialViewModelDataManager {
    func didReadTutorial()
}

class TutorialViewModel: ObservableObject {
    
    weak var coordinatorDelegate: TutorialViewModelCoordinatorDelegate?
    
    func didTapFinishTutorial() {
        
        coordinatorDelegate?.didTapFinishTutorial()
    }
}
