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
    
    let dataManager: TutorialViewModelDataManager
        
    @Published var tutorial = [Tutorial]()
    
    weak var coordinatorDelegate: TutorialViewModelCoordinatorDelegate?
    
    init(dataManager: TutorialViewModelDataManager) {
        
        self.dataManager = dataManager
        
        if let path = Bundle.main.path(forResource: "Tutorial", ofType: "json") {
            do {
                
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                
                let tutorial = try JSONDecoder().decode([Tutorial].self, from: data)

                dump(tutorial)
                print("HE")
                
                self.tutorial = tutorial
                
            } catch {
                // handle error
                print(error)
            }
            
        }
    }
    
    func didTapFinishTutorial() {
        
        coordinatorDelegate?.didTapFinishTutorial()
    }
}
