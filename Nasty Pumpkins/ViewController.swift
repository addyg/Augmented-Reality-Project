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
    case plane = 0
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    //Variable power to add impulse to stone throws
    var power: Float = 50
    var Target: SCNNode?
    var rock: SCNNode?
    
    var plane_pos = SCNVector3()
    
    var count  = 0
    var check  = 0
    var x = Float(0)
    var y = Float(0)
    var z = Float(0)
    
    var jf_towards_pov = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Standard options, to be added to all games
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        
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
        rock.runAction(
            SCNAction.sequence([SCNAction.wait(duration: 2.0),
                                SCNAction.removeFromParentNode()])
        )
    }
    
    func randomNumbers(firstNum: Float, secondNum: Float) -> Float {
        return Float(arc4random()) / Float(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func addPumpkin(x: Float, y: Float, z: Float) {
        //Pumpkin is a 3D scnekit item
        let pumpkinScene = SCNScene(named: "Media.scnassets/Halloween_Pumpkin.scn")
        let pumpkinNode = (pumpkinScene?.rootNode.childNode(withName: "Halloween_Pumpkin", recursively: false))!
        
        pumpkinNode.position = SCNVector3(x,y-5,z-randomNumbers(firstNum: 30, secondNum: 20))

        let phy_body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: pumpkinNode, options: nil))
//        phy_body.isAffectedByGravity = true
//        pumpkinNode.physicsBody?.applyForce(SCNVector3(orientation.x*power*5, orientation.y*power*5, orientation.z*power*5), asImpulse: true)
        
        pumpkinNode.physicsBody = phy_body
        pumpkinNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        pumpkinNode.physicsBody?.contactTestBitMask = BitMaskCategory.rock.rawValue
        self.sceneView.scene.rootNode.addChildNode(pumpkinNode)
        
        let number = Int.random(in: 0 ... 1)
        if number == 0 {
            twoDimensionalMovement(node: pumpkinNode)
        } else {
            projectileMovement(node: pumpkinNode)
        }
    }
    
    func projectileMovement(node: SCNNode) {
        guard let pointOfView = self.sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let position = orientation + location
        
        let hover = SCNAction.move(to: location, duration: 3)

        node.runAction(hover)
        node.runAction(
            SCNAction.sequence([SCNAction.wait(duration: 3.0),
                                SCNAction.removeFromParentNode()])
        )
        
        if(SCNVector3EqualToVector3(node.position, position)) {
            let bokeh = SCNParticleSystem(named: "Media.scnassets/bokeh.scnp", inDirectory: nil)
            bokeh?.loops = false
            bokeh?.particleLifeSpan = 6
            bokeh?.emitterShape = node.geometry
            let bokehNode = SCNNode()
            bokehNode.addParticleSystem(bokeh!)
            bokehNode.position = position
            self.sceneView.scene.rootNode.addChildNode(bokehNode)
    //        Target?.removeFromParentNode()
        }
//        self.addPumpkin(x: plane_pos.x, y: plane_pos.y, z: plane_pos.z)
    }

    
    func twoDimensionalMovement(node: SCNNode) {
        let hover_x = CGFloat(randomNumbers(firstNum: -5, secondNum: 5))
        let hover_y = CGFloat(randomNumbers(firstNum: -5, secondNum: 5))
        let hoverUp = SCNAction.moveBy(x: hover_x, y: hover_y, z: 0, duration: 1)
        let hoverDown = SCNAction.moveBy(x: -(hover_x), y: -(hover_y), z: 0, duration: 1)
        let hoverSequence = SCNAction.sequence([hoverUp, hoverDown])
        let repeatForever = SCNAction.repeatForever(hoverSequence)
        
        node.runAction(repeatForever)

    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if (nodeA.physicsBody?.categoryBitMask == BitMaskCategory.plane.rawValue || nodeB.physicsBody?.categoryBitMask == BitMaskCategory.plane.rawValue) {
            return
        } else {
            if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
                self.Target = nodeA
                self.rock = nodeB
            } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
                self.Target = nodeB
                self.rock = nodeA
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
            rock?.removeFromParentNode()
            self.addPumpkin(x: plane_pos.x, y: plane_pos.y, z: plane_pos.z)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //1. Check Our Frame Is Valid & That We Have Received Our Raw Feature Points
        guard let currentFrame = self.sceneView.session.currentFrame,
        let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }

        guard let pointOfView = self.sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        if (check<1)
        {
            let div = Float(featurePointsArray.count)
            if (featurePointsArray.count>60)
            {
                print("yes")
                featurePointsArray.forEach { (pointLocation) in
                    x = x + pointLocation.x
                    y = y + pointLocation.y
                    z = z + pointLocation.z
                }
                x = x/div
                z = z/div
                y = y/div

                let lavaNode = SCNNode(geometry: SCNPlane(width: 1, height: 1))
                let occlusionMaterial = SCNMaterial()
                occlusionMaterial.colorBufferWriteMask = []

                lavaNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                lavaNode.position = SCNVector3(x-location.x,y-location.y,z-location.z)
                plane_pos = lavaNode.position
                lavaNode.eulerAngles = SCNVector3(0,0,0)
//                lavaNode.geometry?.materials = [occlusionMaterial]

                lavaNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: lavaNode, options: nil))
                lavaNode.physicsBody?.categoryBitMask = BitMaskCategory.plane.rawValue
                lavaNode.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
                lavaNode.renderingOrder = -1

                self.sceneView.scene.rootNode.addChildNode(lavaNode)
                self.addPumpkin(x: lavaNode.position.x, y: lavaNode.position.y, z: lavaNode.position.z)
                self.addPumpkin(x: lavaNode.position.x, y: lavaNode.position.y, z: lavaNode.position.z)
                self.addPumpkin(x: lavaNode.position.x, y: lavaNode.position.y, z: lavaNode.position.z)

                check=1
            }
        }

    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}


//    func addPlane() {
//        guard let pointOfView = self.sceneView.pointOfView else {return}
//        let transform = pointOfView.transform
//        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
//        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
//        let position = orientation + location
//
//        let lavaNode = SCNNode(geometry: SCNPlane(width: 4, height: 4))
//        lavaNode.position = SCNVector3(0-position.x, 1-position.y, -170-position.z)
//        lavaNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
//                        //lavaNode.geometry?.firstMaterial?.isDoubleSided = true
//        plane_pos = lavaNode.position
//        lavaNode.eulerAngles = SCNVector3(0,0,0)
//        print (lavaNode.position)
//
//        lavaNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: lavaNode, options: nil))
//        self.sceneView.scene.rootNode.addChildNode(lavaNode)
//
//        lavaNode.physicsBody?.categoryBitMask = BitMaskCategory.plane.rawValue
////        lavaNode.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
//    }
