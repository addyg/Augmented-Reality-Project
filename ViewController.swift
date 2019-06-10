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
    
    
    var currentTime: Float = 0.0
    var maxTime: Float = 10.0
    
    
    //Max game time default 30sec
    var gameInt = 30
    //Timer function to set game time limit
    var gameTimer = Timer()
    
    //Oreintation Button toggle
    var buttonIsOn: Bool = false
    
    //toggle to turn on/off the timer
    //var timerToggle: Bool = false
    
    //Time label to show time remianing
    @IBOutlet var timeLabel: UILabel!
    
    @IBOutlet var timeLeft: UIProgressView!
    
    
    //Button press to go back to main page
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    //Button press to show 3D Orientation and feature points
    @IBAction func orientation(_ sender: Any) {

        if buttonIsOn{
            self.sceneView.debugOptions = []
            buttonIsOn = false
        } else{
            self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
            buttonIsOn = true
        }
    }
    
    //Add sceneView
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    //Variable power to add impulse to stone throws
    var power: Float = 50
    var Target: SCNNode?
    
    
    //Standard function
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        
        //Recognize the phone tap gesture
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(gestureRecognizer)
        self.sceneView.scene.physicsWorld.contactDelegate = self
        
        //To show 30sec in the timer label and homepage
        gameInt = 30
        timeLabel.text = " "+String(gameInt)+"    "
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
        
        
    }
    
    //Button to make 5 pumpkins at different (or random) distances
    @IBAction func addTargets(_ sender: UIButton) {
        
        sender.isHidden = true
        
        var n:Int = 0
        
        while(n<=5){
            
            let randX = Float.random(in: -10...10)
            let randY = Float.random(in: -10...10)
            let randZ = Float.random(in: 20...150)
            
            self.addPumpkin(x: randX, y: randY, z: -randZ)
            
            n += 1
        }
        
        self.addWall(x: 0, y: 0, z: -2)
        
        //Starting timer
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.game), userInfo: nil, repeats: true)

    }
    
    func addWall(x: Float, y: Float, z: Float) {
        
        let wall = SCNNode(geometry: SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0.05))
        wall.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        wall.position = SCNVector3(x,y,z)
        
        let wallBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: wall, options: nil))
        wall.physicsBody = wallBody
        
        self.sceneView.scene.rootNode.addChildNode(wall)
        
    }
    
    
    func addPumpkin(x: Float, y: Float, z: Float) {
        //Pumpkin is a 3D scnekit item
        let pumpkinScene = SCNScene(named: "Media.scnassets/Halloween_Pumpkin.scn")
        let pumpkinNode = (pumpkinScene?.rootNode.childNode(withName: "Halloween_Pumpkin", recursively: false))!
        pumpkinNode.position = SCNVector3(x,y,z)
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
    
        //Function for timer in the game
    @objc func game(){
        

        if gameInt <= 0{
            gameTimer.invalidate()
            return
        }else{
            gameInt -= 1
            timeLabel.text = " "+String(gameInt)+"    "
        }
        
        }
        
    
}

//Function to define "+" sign to add POV and Orentation = Location
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}


