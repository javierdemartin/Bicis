//
//  ConfettiKit.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 06/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    let emitter = SKEmitterNode(fileNamed: "particle")
    let colors = [SKColor.white,SKColor.gray,SKColor.green,SKColor.red,SKColor.black]

    override func didMove(to view: SKView) {

        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)

        emitter!.position = CGPoint(x: 200, y:300)

        emitter!.particleColorSequence = nil
        emitter!.particleColorBlendFactor = 1.0

        self.addChild(emitter!)

        let action = SKAction.run({
            [unowned self] in
            let random = Int(arc4random_uniform(UInt32(self.colors.count)))

            self.emitter!.particleColor = self.colors[random];
            print(random)
        })

        let wait = SKAction.wait(forDuration: 0.1)

        self.run(SKAction.repeatForever( SKAction.sequence([action,wait])))

    }

}
