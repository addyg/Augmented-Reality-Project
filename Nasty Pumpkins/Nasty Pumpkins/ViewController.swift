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
//    var centroidList: [SCNVector3] = []
//    var eulerList: [SCNVector3] = []
//    var boundaryList: [ObjectBoundaries] = []
//    var transform : simd_float4x4 = matrix_identity_float4x4
    //variable to toggle oreientation button
    var buttonIsOn: Bool = false
    var gameison: Bool = false
    @IBOutlet weak var homeButton: UIButton!
    //No. of stones progress bar
    @IBOutlet weak var timeLeft: UIProgressView!

    @IBOutlet weak var target: UIButton!
    @IBOutlet weak var view3d: UIButton!
    @IBOutlet weak var label: UIButton!
    @IBOutlet weak var showAllModelledObjButton: UIButton!
    
    //Button press to go back to main page
    @IBOutlet weak var startButtonObject: UIButton!
    @IBOutlet weak var stopButtonObject: UIButton!
    
    @IBOutlet weak var startgame: UIButton!
    // Added for shape optimization
    var objectCount = -1
    var lastEulerAngleDetetedForObject: SCNVector3 = SCNVector3(0,0,0)
    var dist_x: [Float] = []
    var dist_y: [Float] = []
    var dist_z: [Float] = []
    var param_array = Set<vector_float3>()
    var realWorldObjectArray: [Set<vector_float3>] = []
    var realWorldObjectCentroidArray: [SCNVector3] = []
    var realWorldObjectEulerArray: [SCNVector3] = []
    var realWorldObjectMaxBoundriesArray: [ObjectBoundaries] = []
    var transformcordinate : simd_float4x4 = matrix_identity_float4x4
    var scanningComplete = true
    ///////////////////////////////////////////////////////////////////
    
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
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true

        /////////////// game play is hidden intitally
        timeLeft.isHidden = true
        homeButton.isHidden = true
        view3d.isHidden  = true
        label.isHidden = true
        target.isHidden = true
        /////////////////////////////
        //Recognize the phone tap gesture
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(gestureRecognizer)
        self.sceneView.scene.physicsWorld.contactDelegate = self
        
        
        timeLeft.layer.cornerRadius = 2
        timeLeft.clipsToBounds = true
        timeLeft.layer.sublayers![1].cornerRadius = 2
        timeLeft.subviews[1].clipsToBounds = true
        
        // Below rendering is done in startgame button
        //Defining circular progress bar
//        let circularProgress = CircularProgress(frame: CGRect(x: 10.0, y: 30.0, width: 100.0, height: 100.0))
//        circularProgress.progressColor = UIColor.orange
//        //(red: 52.0/255.0, green: 141.0/255.0, blue: 252.0/255.0, alpha: 1.0)
//        circularProgress.trackColor = UIColor.white
//        //(red: 52.0/255.0, green: 141.0/255.0, blue: 252.0/255.0, alpha: 0.6)
//        circularProgress.tag = 101
//        circularProgress.center = self.view.center
//        self.view.addSubview(circularProgress)
        
    }
    
    
    //Standard
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //After recognizing tap, now adding functionality to it
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if gameison{
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
//        var index = 0
//        for _ in self.realWorldObjectCentroidArray{
//            print("in for loop")
//            self.addWall(x: self.realWorldObjectCentroidArray[index].x, y: self.realWorldObjectCentroidArray[index].x, z: self.realWorldObjectCentroidArray[index].x, width: self.realWorldObjectMaxBoundriesArray[index].width, height: realWorldObjectMaxBoundriesArray[index].height, eulerangle: realWorldObjectEulerArray[index])
//            index+=1
//        }
        
        
        //Call horizontal progress bar
        timeLeft.setProgress(currentStones, animated: true)
        //perform(#selector(updateProgress), with: nil, afterDelay: 1.0 )
        
        //Call circular progress bar
        self.perform(#selector(animateProgress), with: nil, afterDelay: 1)
        
    }
    
    
    func addWall(x: Float, y: Float, z: Float, width: Float, height: Float, eulerangle: SCNVector3) {
        print("in add wall")
        let wall = SCNNode(geometry: SCNPlane(width: 2*CGFloat(width), height: 2*CGFloat(height)))
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
    //////////////////?????????????????/////////////////////////
    ///////////////// Code Integration /////////////////////////
    /////////////////////????????????????//////////////////////
    
    @IBAction func startGame(_ sender: Any) {
        showAllModelledObjButton.isHidden = true
        startButtonObject.isHidden = true
        stopButtonObject.isHidden = true
        timeLeft.isHidden = false
        homeButton.isHidden = false
        view3d.isHidden  = false
        label.isHidden = false
        target.isHidden = false
        let circularProgress = CircularProgress(frame: CGRect(x: 10.0, y: 30.0, width: 100.0, height: 100.0))
        circularProgress.progressColor = UIColor.orange
        //(red: 52.0/255.0, green: 141.0/255.0, blue: 252.0/255.0, alpha: 1.0)
        circularProgress.trackColor = UIColor.white
        //(red: 52.0/255.0, green: 141.0/255.0, blue: 252.0/255.0, alpha: 0.6)
        circularProgress.tag = 101
        circularProgress.center = self.view.center
        self.view.addSubview(circularProgress)
        gameison = true
        startgame.isHidden=true
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        //If scanning is not on. Return from here
        if(self.isScanningComplete()){
            // TODO: Show a message to tell the user to press the start tapping option
            return
        }
        
        let currentPoint = touch.location(in: sceneView)
        // Get all feature points in the current frame
        
        let fp = self.sceneView.session.currentFrame?.rawFeaturePoints
        guard let count = fp?.points.count else{return}
        // Create a material
        let material = createMaterial()
        // Loop over them and check if any exist near our touch location
        // If a point exists in our range, let's draw a sphere at that feature point
        for index in 0..<count {
            let point = SCNVector3.init((fp?.points[index].x)!, (fp?.points[index].y)!, (fp?.points[index].z)!)
            let projection = self.sceneView.projectPoint(point)
            let xRange:ClosedRange<Float> = Float(currentPoint.x)-100.0...Float(currentPoint.x)+100.0
            let yRange:ClosedRange<Float> = Float(currentPoint.y)-100.0...Float(currentPoint.y)+100.0
            if (xRange ~= projection.x && yRange ~= projection.y) {
                let ballShape = SCNSphere(radius: 0.001)
                ballShape.materials = [material]
                let ballnode = SCNNode(geometry: ballShape)
                ballnode.position = point
                self.sceneView.scene.rootNode.addChildNode(ballnode)
                // We'll also save it for later use in our [SCNVector]
                //                let p_oints = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                //                points.append(p_oints)
                self.param_array.insert(vector_float3(point))
                self.lastEulerAngleDetetedForObject = self.getDyamicEulerAngles()
            }
        }
    }
    
    func getDyamicEulerAngles() -> SCNVector3 {
        guard let pointOfView = self.sceneView.pointOfView else {return SCNVector3(0,0,0)}
        let transform = pointOfView.eulerAngles
        return SCNVector3(transform.x, transform.y, transform.z)
    }
    
    func createMaterial() -> SCNMaterial {
        let clearMaterial = SCNMaterial()
        clearMaterial.diffuse.contents = UIColor(red:0.12, green:0.61, blue:1.00, alpha:1.0)
        clearMaterial.locksAmbientWithDiffuse = true
        clearMaterial.transparency = 0.2
        return clearMaterial
    }
    
    func showAllModelledObjects() {
        if(self.isCentroidCalculationRequired()){
            self.calculateCentroidForAllRealWorldObjects()
            print("All Centroids and Boundaries Calculated")
            print(self.realWorldObjectCentroidArray)
        }
        //Now proceed to show the object
        var count = 0;
        //Objects are scanned  scanned now. Lets Store its 3D ARCloud Model
        for _ in self.realWorldObjectArray{
            self.placePlaneInFrontOfObjects(index: count)
            count += 1
        }
    }
    
    //Used For Occlusion. NOt being used now
    func placeInvisiblePlane(point: SCNVector3,width:Double, height:Double, z: Double, index: Int) {
        let maskMaterial = SCNMaterial()
        maskMaterial.diffuse.contents = UIColor.white
        maskMaterial.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        maskMaterial.isDoubleSided = true
        let wallNode = SCNNode(geometry: SCNPlane(width: CGFloat(width), height: CGFloat(height)))
        //wallNode.geometry?.firstMaterial = maskMaterial
        wallNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        //wallNode.renderingOrder = -1
        wallNode.position = SCNVector3( point.x,point.y + 0.09,Float(z))
        wallNode.eulerAngles = self.realWorldObjectEulerArray[index]
        //wallNode.position = SCNVector3(0,0,0)
        self.sceneView.scene.rootNode.addChildNode ( wallNode )
    }
    
    func placeSphere( point: SCNVector3, width:Float, height: Float ) {
        let spehere = SCNNode(geometry: SCNSphere(radius: 0.05))
        spehere.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        spehere.position = SCNVector3( point.x ,point.y, point.z-0.5)
        self.sceneView.scene.rootNode.addChildNode( spehere )
    }
    
    func isCentroidCalculationRequired() -> Bool {
        if(realWorldObjectArray.count == realWorldObjectCentroidArray.count){
            return false
        }
        return true
    }
    
    func calculateCentroidForAllRealWorldObjects() {
        var count = 0
        for temp_param_array in self.realWorldObjectArray{
            if(count >= realWorldObjectCentroidArray.count ){
                let centroidAndBoundaries = self.calculateCentroidOfPoints(points: temp_param_array)
                
                realWorldObjectCentroidArray.append( centroidAndBoundaries.0)
                
                realWorldObjectMaxBoundriesArray.append(centroidAndBoundaries.1)
                
            }
            count += 1
        }
    }
    
    func calculateCentroidOfPoints(points :Set<vector_float3>) -> (SCNVector3, ObjectBoundaries){
        var xSum: Float = 0.0;
        var ySum: Float = 0.0;
        var zSum: Float = 0.0;
        let pointCount = Float(points.count)
        for point in points {
            var vectorFloatPoint = vector_float3( point )
            xSum += vectorFloatPoint.x
            ySum += vectorFloatPoint.y
            zSum += vectorFloatPoint.z
        }
        
        let xC = xSum / pointCount
        let yC = ySum / pointCount
        let zC = zSum / pointCount
        
        for point in points {
            dist_x.append(abs(point.x-xC))
            dist_y.append(abs(point.y-yC))
            dist_z.append(abs(point.z-zC))
        }
        
        dist_x = dist_x.sorted(by: >)
        dist_y = dist_y.sorted(by: >)
        dist_z = dist_z.sorted(by: >)
        
        let maxX = dist_x[0]
        let maxY = dist_y[0]
        let maxZ = dist_z[0]
        
        let objectBoundaries = ObjectBoundaries(maxX: maxX, maxY: maxY, maxZ: maxZ)
        
        return (SCNVector3(xC,yC,zC), objectBoundaries )
    }
    
    //We will Place the plane based on the Euler Angles. TC
    func placePlaneInFrontOfObjects(index: Int) {
        let objectBoundaries = self.realWorldObjectMaxBoundriesArray[index]
        
        let height = self.getHeightBasedOnOrientation(objectBoundaries: objectBoundaries,eulerAngle: self.realWorldObjectEulerArray[index])
        let width = 2 * CGFloat(objectBoundaries.getMaxX())
        
        self.realWorldObjectMaxBoundriesArray[index].height = Float(height)
        self.realWorldObjectMaxBoundriesArray[index].width = Float(width)
        
        
        let planeOfReference = SCNNode(geometry: SCNPlane(width: 2 * CGFloat(objectBoundaries.getMaxX()), height: 2 * height))
        
        planeOfReference.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        planeOfReference.position = SCNVector3(self.realWorldObjectCentroidArray[index].x,self.realWorldObjectCentroidArray[index].y,self.realWorldObjectCentroidArray[index].z)
        planeOfReference.eulerAngles = self.realWorldObjectEulerArray[index]
        planeOfReference.geometry?.firstMaterial?.isDoubleSided = true
        self.sceneView.scene.rootNode.addChildNode(planeOfReference)
        let sphere = SCNNode(geometry: SCNSphere(radius: 0.03))
        sphere.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        sphere.position = SCNVector3(self.realWorldObjectCentroidArray[index].x,self.realWorldObjectCentroidArray[index].y,self.realWorldObjectCentroidArray[index].z)
        self.sceneView.scene.rootNode.addChildNode(sphere)
    }
    
    func getHeightBasedOnOrientation(objectBoundaries: ObjectBoundaries, eulerAngle: SCNVector3) -> CGFloat {
        
        //Get Orientation
        //If orientation is straight - OK x and y
        //else show x and z
        let xDegree = GLKMathRadiansToDegrees(eulerAngle.x)
        let normalisedX = 90 - abs(xDegree)
        
        if( normalisedX < abs(xDegree)){
            return CGFloat(objectBoundaries.getMaxZ())
        }
        else{
            return CGFloat(objectBoundaries.getMaxY())
        }
    }
    
    func getAllPlanesToRender(){
        
    }
    
    func isScanningComplete() -> Bool {
        return self.scanningComplete;
    }
    
    func _onScanningComplete() {
        self.scanningComplete = true
        //Add the scanned object to the realWorldObjectArray
        self.realWorldObjectArray.insert(self.param_array, at: self.objectCount)
        self.realWorldObjectEulerArray.insert( self.lastEulerAngleDetetedForObject , at: self.objectCount)
        self.param_array.removeAll()
    }
    
    func _onScanningStart() {
        self.scanningComplete = false
        self.objectCount += 1
    }
    
    @IBAction func onStartScanningClick(_ sender: Any) {
        print("Start Tap Button Clicked")
        self.startButtonObject.isEnabled = false
        self.stopButtonObject.isEnabled = true
        self.showAllModelledObjButton.isEnabled = false
        self._onScanningStart()
    }

    
    @IBAction func onStopScanningClick(_ sender: Any) {
        print("End Tap Button Clicked")
        if(isScanningComplete()){
            return
    }
    

        self.startButtonObject.isEnabled = true
        self.stopButtonObject.isEnabled = false
        self.showAllModelledObjButton.isEnabled = true
        self._onScanningComplete()
    }
    
    @IBAction func onShowAllModelledObjectsClick(_ sender: Any) {
        if(self.startButtonObject.isEnabled == false){
            self.destroyAllModelledObjects();
            self.startButtonObject.isEnabled = true
            return
        }
        
        self.showAllModelledObjects()
        self.startButtonObject.isEnabled = false
        self.stopButtonObject.isEnabled = false
    }
   
    func destroyAllModelledObjects(){
        
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
