//
//  ViewController.swift
//  neomap1
//
//  Created by Ananya Jajoo on 12/28/20.
//

import UIKit
import RealityKit
import ARKit
import Vision
import Firebase

class ARViewController: UIViewController, ARSessionDelegate, UNUserNotificationCenterDelegate {
    var username:String!
    var email:String!
    var imageTaken: UIImage!
    var latitude: Double!
    var longitude: Double!
    
    var earth: Entity!
    // define screen resolution
    //  define screen size
    let screenSize: CGRect = UIScreen.main.bounds
    
    // define notification control signals
    var toReact: Bool! = false
    var hasReacted: Bool! = false
    
    // define firebase database instance
    let db = Firestore.firestore()
    var counter = 0
    
    
    var configuration = ARWorldTrackingConfiguration()
    var posterAnchor: Poster.Scene!
    
    var likeCounts: Int! = 0
    var disLikeCounts: Int! = 0
    var giftCounts: Int! = 0
    
    @IBOutlet var arView: ARView!
    
    // define some entities used in the scene
    var likeEntity: Entity!
    var giftEntity: Entity!
    var dislikeEntity: Entity!
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput")
    //private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    
    
    //private var evidenceBuffer = [HandGestureProcessor.PointsPair]()
    //private var lastDrawPoint: CGPoint?
    private var isFirstSegment = true
    //private var lastObservationTimestamp = Date()
    
    private var gestureProcessor = HandGestureProcessor()
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print("Session failed. Changing worldAlignment property.")
        print(error.localizedDescription)

        if let arError = error as? ARError {
            switch arError.errorCode {
            case 102:
                configuration.worldAlignment = .gravity
                restartSessionWithoutDelete()
            default:
                restartSessionWithoutDelete()
            }
        }
    }
    
    func restartSessionWithoutDelete() {
        // Restart session with a different worldAlignment - prevents bug from crashing app
        self.arView.session.pause()

        self.arView.session.run(configuration, options: [
            .resetTracking,
            .removeExistingAnchors])
    }
    
    
    // function for handling tapping actions
    @objc
    func handleTap(recognizer: UITapGestureRecognizer) {
        
    }
    
    func setupARView() {
        arView.automaticallyConfigureSession = false
        //let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        //configuration.environmentTexturing = .automatic
        //arView.session.run(configuration)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handPoseRequest.maximumHandCount = 1
        
        posterAnchor = try! Poster.loadScene()
        
        print(email ?? "null email")
        arView.scene.anchors.append(posterAnchor)
        
        let imageAnchor = AnchorEntity(plane: .horizontal)

        var simpleMaterial = SimpleMaterial()
        
        var documentsUrl: URL {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        
        do {
            let fileName = "placeholder.jpg"
            let fileURL = documentsUrl.appendingPathComponent(fileName)
            if let imageData = imageTaken.jpegData(compressionQuality: 1.0) {
                try? imageData.write(to: fileURL, options: .atomic)
                print(fileName)
                simpleMaterial.baseColor = try! .texture(.load(contentsOf: fileURL))
            }
        } catch {
            print("Unable to Write Data to Disk (\(error))")
        }
        
        likeEntity = posterAnchor.findEntity(named: "like")
        giftEntity = posterAnchor.findEntity(named: "gift")
        dislikeEntity = posterAnchor.findEntity(named: "dislike")
        
        let myMesh: MeshResource = .generatePlane(width: 0.2, depth: 0.2, cornerRadius: 0.01)

        let component = ModelComponent(mesh: myMesh,
                                  materials: [simpleMaterial])
        

        imageAnchor.components.set(component)
        
        arView.scene.addAnchor(posterAnchor)
        arView.scene.addAnchor(imageAnchor)
        
        
        // set the initial position of the
        imageAnchor.transform.translation = [0, 0.5, -0.5]
        
        // rotate the image 90 degrees so it faces the user
        imageAnchor.transform.rotation = simd_quatf(angle: .pi/2, axis: SIMD3(x: 1, y: 0, z: 0))

        
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        arView.session.delegate = self
        setupARView()
        
        self.togglePeopleOcclusion()
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    fileprivate func togglePeopleOcclusion() {
        guard let config = arView.session.configuration as? ARWorldTrackingConfiguration else {
            fatalError("Unexpectedly failed to get the configuration.")
        }
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) else {
            fatalError("People occlusion is not supported on this device.")
        }
        switch config.frameSemantics {
        case [.personSegmentationWithDepth]:
            config.frameSemantics.remove(.personSegmentationWithDepth)
        
        default:
            config.frameSemantics.insert(.personSegmentationWithDepth)
            
        }
        arView.session.run(config)
    }
    
    
    @IBAction func returnToPortfolio(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "returnToPortfolio", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let secondViewController = segue.destination as? PortfolioViewController {
            print(email!)
            secondViewController.email = email
            secondViewController.username = username
            //secondViewController.location = location
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        var thumbTip: CGPoint?
        var indexTip: CGPoint?
        var ringTip: CGPoint?
        
        let width = screenSize.width
        let height = screenSize.height
        
        counter += 1
        
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .up, options: [:])
        do {
            if counter % 10 == 0 {
                try? handler.perform([handPoseRequest])
                guard let observation = handPoseRequest.results?.first else {return}
                
                let thumbPoints = try! observation.recognizedPoints(forGroupKey: .handLandmarkRegionKeyThumb)
                let indexFingerPoints = try observation.recognizedPoints(forGroupKey: .handLandmarkRegionKeyIndexFinger)
                let ringFingerPoints = try observation.recognizedPoints(forGroupKey: .handLandmarkRegionKeyRingFinger)
                // Look for tip points.
                guard let thumbTipPoint = thumbPoints[.handLandmarkKeyThumbTIP], let indexTipPoint = indexFingerPoints[.handLandmarkKeyIndexTIP], let ringTipPoint = ringFingerPoints[.handLandmarkKeyRingTIP] else {
                    return
                }
                // Ignore low confidence points.
                guard thumbTipPoint.confidence > 0.3 && indexTipPoint.confidence > 0.3 else {
                    return
                }
                
                let middleFingerAndThumbTipDistance = abs(thumbTipPoint.location.x - indexTipPoint.location.x) + abs(thumbTipPoint.location.y - indexTipPoint.location.y)
                
                // print out the manhattan distance between thumb and index tips
                // print("difference: \(middleFingerAndThumbTipDistance)")
                
                if middleFingerAndThumbTipDistance < 0.05 && !toReact {
                    print("action detected")
                    
                    Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { timer in
                        self.toReact = true
                    }
                    // show up all the commenting signs
                    posterAnchor.notifications.showLikeSign.post()
                    
                }
                
                let likePosition = SIMD3<Float>(
                    likeEntity.position.x,
                    likeEntity.position.y,
                    likeEntity.position.z
                )
                
                let giftPosition = SIMD3<Float>(
                    giftEntity.position.x,
                    giftEntity.position.y,
                    giftEntity.position.z
                )
                
                let dislikePosition = SIMD3<Float>(
                    dislikeEntity.position.x,
                    dislikeEntity.position.y,
                    dislikeEntity.position.z
                )
                
                
                let thumbX = thumbTipPoint.location.x
                let indexX = indexTipPoint.location.x
                // user ready to add their reactions
                if toReact && middleFingerAndThumbTipDistance > 0.05{
                    
                    
                    if thumbX < indexX - 0.05{
                        likeCounts += 1
                    } else if thumbX > indexX + 0.05 {
                        disLikeCounts += 1
                    }
                    if likeCounts == 5 {
                        likeCounts = 0
                        // perform like actions
                        print("like")
                    }
                    if disLikeCounts == 5 {
                        disLikeCounts = 0
                        // perform dislike actions
                        print("dislike")
                    }
                    
                    
                } else if toReact {
                    giftCounts += 1
                    if giftCounts == 5 {
                        giftCounts = 0
                        print("gift")
                    }
                }
                
                thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
                indexTip = CGPoint(x: indexTipPoint.location.x, y: 1 - indexTipPoint.location.y)
                ringTip = CGPoint(x: ringTipPoint.location.x, y: 1 - ringTipPoint.location.y)
            }
        } catch {

        }
    }
    
}
