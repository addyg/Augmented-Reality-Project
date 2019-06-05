//
//  ViewController.swift
//  Nasty Pumpkins
//
//  Created by Aditya Gupta on 2019-05-30.
//  Copyright © 2019 Aditya Gupta. All rights reserved.
//

import UIKit
import ARKit

enum BitMaskCategory: Int {
    case rock = 2
    case target = 5
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    //Variable power to add impulse to stone throws
    var power: Float = 50
    var Target: SCNNode?
    override func viewDidLoad() {
        super.viewDidLoad()
        //Standard options, to be added to all games
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.sceneView.autoenablesDefaultLighting = true
        
        //Recognize the phone tap gesture
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(gestureRecognizer)
        self.sceneView.scene.physicsWorld.contactDelegate = self
        
    }
    //Standard
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //After recognizing tap, now adding functionality to it
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        guard let pointOfView = sceneView.pointOfView else {return}
        //Standard position of objects intake
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let position = orientation + location
        
        //making a rock to throw at pumpkins
        //rock is a sphere
        let rock = SCNNode(geometry: SCNSphere(radius: 0.2))
        rock.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "rock1")
        //make rock initial starting point as cameras/users loci
        rock.position = position
        //body type is dynamic as rock is to be thrown, unlike pumpinks which are kept static
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: rock, options: nil))
        
        //let rocks take a parabolic throw curve, thus affected by gravity
        body.isAffectedByGravity = true
        rock.physicsBody = body
        rock.physicsBody?.applyForce(SCNVector3(orientation.x*power, orientation.y*power, orientation.z*power), asImpulse: true)
        rock.physicsBody?.categoryBitMask = BitMaskCategory.rock.rawValue
        rock.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        self.sceneView.scene.rootNode.addChildNode(rock)
        //rock.runAction(
            //SCNAction.sequence([SCNAction.wait(duration: 2.0),
                                //SCNAction.removeFromParentNode()])
        //)
    }
    
    //Make 5 pumpkins at different distances
    @IBAction func addTargets(_ sender: Any) {
        self.addPumpkin(x: randomNumbers(firstNum: -10, secondNum: 20), y: randomNumbers(firstNum: -1, secondNum: 1), z: randomNumbers(firstNum: -20, secondNum: -10))
        self.addPumpkin(x: randomNumbers(firstNum: -10, secondNum: 20), y: randomNumbers(firstNum: -1, secondNum: 1), z: randomNumbers(firstNum: -40, secondNum: -25))
        self.addPumpkin(x: randomNumbers(firstNum: -10, secondNum: 20), y: randomNumbers(firstNum: -1, secondNum: 1), z: -100)
        self.addPumpkin(x: randomNumbers(firstNum: -10, secondNum: 20), y: randomNumbers(firstNum: -1, secondNum: 1), z: randomNumbers(firstNum: -70, secondNum: -60))
        self.addPumpkin(x: randomNumbers(firstNum: -10, secondNum: 20), y: randomNumbers(firstNum: -1, secondNum: 1), z: randomNumbers(firstNum: -55, secondNum: -45))
        
    }
    
    func randomNumbers(firstNum: Float, secondNum: Float) -> Float {
        return Float(arc4random()) / Float(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func addPumpkin(x: Float, y: Float, z: Float) {
        //Pumpkin is a 3D scnekit item
        let pumpkinScene = SCNScene(named: "Media.scnassets/Halloween_Pumpkin.scn")
        let pumpkinNode = (pumpkinScene?.rootNode.childNode(withName: "Halloween_Pumpkin", recursively: false))!
//        var intersects = true
        
//        while (intersects){
        
        pumpkinNode.position = SCNVector3(x,y,z)
            
//            intersects = false
            
//            self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
//                if (node.presentation.position.x == pumpkinNode.presentation.position.x
//                    && node.presentation.position.y == pumpkinNode.presentation.position.y
//                    && node.presentation.position.z == pumpkinNode.presentation.position.z) {
//                    intersects = true
//                    print(intersects)
//                }
//                print("Added")
////                if (currentSprite.intersectsNode(sprite)){
////                    intersects = true
////                    break
////                }
            
//            }
//        }
        pumpkinNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: pumpkinNode, options: nil))
        pumpkinNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        pumpkinNode.physicsBody?.contactTestBitMask = BitMaskCategory.rock.rawValue
        self.sceneView.scene.rootNode.addChildNode(pumpkinNode)
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            self.Target = nodeA
        } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            self.Target = nodeB
        }
        
        //Add animation = bokeh to pumkin being hit, then delte pumpkin child node
        let bokeh = SCNParticleSystem(named: "Media.scnassets/bokeh.scnp", inDirectory: nil)
        bokeh?.loops = false
        bokeh?.particleLifeSpan = 6
        bokeh?.emitterShape = Target?.geometry
        let bokehNode = SCNNode()
        bokehNode.addParticleSystem(bokeh!)
        bokehNode.position = contact.contactPoint
        self.sceneView.scene.rootNode.addChildNode(bokehNode)
        Target?.removeFromParentNode()
        
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
