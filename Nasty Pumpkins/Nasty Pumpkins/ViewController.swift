//
//  ViewController.swift
//  Nasty Pumpkins
//
//  Created by Aditya Gupta on 6/10/19.
//  Copyright © 2019 Aditya Gupta. All rights reserved.
//

import UIKit
import ARKit

enum BitMaskCategory: Int {
    case rock = 2
    case target = 5
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {
    
    //Max and current sones/objects
    var currentStones: Float = 0.0
    var maxStones: Float = 15.0
    var centroidList: [SCNVector3] = []
    var eulerList: [SCNVector3] = []
    var boundaryList: [ObjectBoundaries] = []
    var transform : simd_float4x4 = matrix_identity_float4x4
    //variable to toggle oreientation button
    var buttonIsOn: Bool = false

    //No. of stones progress bar
    @IBOutlet weak var timeLeft: UIProgressView!

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
    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    //Variable power to add impulse to stone throws
    var power: Float = 50
    var Target: SCNNode?
    
    
    //Standard function
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.session.run(configuration)
        self.sceneView.session.setWorldOrigin(relativeTransform: transform)
        self.sceneView.autoenablesDefaultLighting = true
        print("####### Recieved Arrays ######")
        print(boundaryList.count)
        print(eulerList.count)
        print(centroidList.count)
        
        //Recognize the phone tap gesture
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(gestureRecognizer)
        self.sceneView.scene.physicsWorld.contactDelegate = self
        
        
        timeLeft.layer.cornerRadius = 2
        timeLeft.clipsToBounds = true
        timeLeft.layer.sublayers![1].cornerRadius = 2
        timeLeft.subviews[1].clipsToBounds = true
        
        
        //Defining circular progress bar
        let circularProgress = CircularProgress(frame: CGRect(x: 10.0, y: 30.0, width: 100.0, height: 100.0))
        circularProgress.progressColor = UIColor.orange
        //(red: 52.0/255.0, green: 141.0/255.0, blue: 252.0/255.0, alpha: 1.0)
        circularProgress.trackColor = UIColor.white
        //(red: 52.0/255.0, green: 141.0/255.0, blue: 252.0/255.0, alpha: 0.6)
        circularProgress.tag = 101
        circularProgress.center = self.view.center
        self.view.addSubview(circularProgress)
        
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
        
        
        //Counting stones
        perform(#selector(updateProgress), with: nil, afterDelay: 1.0 )
        
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
        
        //Make placeholder wall
        var index = 0
        for _ in centroidList{
            print("in for loop")
            self.addWall(x: centroidList[index].x, y: centroidList[index].x, z: centroidList[index].x, width: boundaryList[index].width, height: boundaryList[index].height, eulerangle: eulerList[index])
            index+=1
        }
        
        
        //Call horizontal progress bar
        timeLeft.setProgress(currentStones, animated: true)
        //perform(#selector(updateProgress), with: nil, afterDelay: 1.0 )
        
        //Call circular progress bar
        self.perform(#selector(animateProgress), with: nil, afterDelay: 1)
        
    }
    
    
    func addWall(x: Float, y: Float, z: Float, width: Float, height: Float, eulerangle: SCNVector3) {
        print("in add wall")
        let wall = SCNNode(geometry: SCNPlane(width: CGFloat(width), height: CGFloat(height)))
        wall.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        wall.position = SCNVector3(x,y,z)
        wall.eulerAngles = eulerangle
        
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


    //Function for timer progress bar in the game
    @objc func updateProgress(){
        
        if currentStones < maxStones{
            currentStones = currentStones + 1.0
            timeLeft.progress = currentStones/maxStones
        }else{
            dismiss(animated: true, completion: nil)
        }
            
        //currentStones = currentStones + 1.0
        //timeLeft.progress = currentStones/maxStones
        
        /*
        if currentStones < maxStones{
            perform(#selector(updateProgress), with: nil, afterDelay: 1.0 )
        }else{
            currentStones = 0.0
            
            return
        }*/
    }
    
    //Circular Progress bar - call touch class
    @objc func animateProgress() {
        let cp = self.view.viewWithTag(101) as! CircularProgress
        //Define time duration allowed
        cp.setProgressWithAnimation(duration: 15.0, value: 1.0)
    }
    
}

//Function to define "+" sign to add POV and Orentation = Location
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}





/*
 
 Extra - Old Code

 
 /*
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
 */
 
 
 
 //Max game time default 30sec
 //var gameInt = 30
 //Timer function to set game time limit
 //var gameTimer = Timer()
 
 //Oreintation Button toggle
 
 //toggle to turn on/off the timer
 //var timerToggle: Bool = false
 
 //Time label to show time remianing
 //@IBOutlet var timeLabel: UILabel!
 
 
 //@IBOutlet var progressBar: CircularProgressBar!
 
 */
