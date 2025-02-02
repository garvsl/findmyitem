import UIKit
import SceneKit     // 3D graphics rendering and physics
import ARKit        // Augmented Reality framework for tracking and rendering
import Vision       // Apple's machine learning and image recognition framework
import MultipeerConnectivity // Handles peer-to-peer communication for AR experiences
import CoreLocation
import SwiftUI
@available(iOS 13.0, *)
class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    
    // store the current latitude and longitude
    // of the device specificially
    var distance : Float = 0.0
    var current_latitude : String = ""            // HINT : most likely string values
    var current_longitude : String = ""           // HINT : also most likely string based values
    
    // This should render
    var body : any View {
        VStack {
            Text("Distance")
        }
    }

    @IBOutlet weak var sceneView: ARSCNView! // The main AR view
        @IBOutlet weak var sendMapButton: UIButton! // Button to share AR World Map
        @IBOutlet weak var sessionInfoView: UIVisualEffectView! // Overlay for session status info
        @IBOutlet weak var sessionInfoLabel: UILabel! // Label displaying AR session status
        @IBOutlet weak var detectBtn: UIButton! // Button to detect objects
        @IBOutlet weak var restoreBtn: UIButton! // Button to restore saved AR world map
        @IBOutlet weak var saveBtn: UIButton! // Button to save AR world map
    
    public var isHost = false // Determines whether the user is the host in a shared AR session
    
    private var multipeerSession: MultipeerSession! // Handles communication between devices
    
    private var target: ARItem!     // Stores the target object to be tracked
    
    // Reference to the status view controller for displaying messages
    private lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()

    // Gesture recognizers for detecting tap interactions
    // NOTE : to popup the + icon, double tap
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var doubletapGestureRecognizer: UITapGestureRecognizer!

    // Stores the peer providing the AR world map
    public var mapProvider: MCPeerID?
    
    // Item list controller to display recognized items
    lazy var listViewController: ItemListCollectionViewController = {
        let listViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CollectionView") as! ItemListCollectionViewController
        return listViewController
    }()
    
    // host: saving & restore the currentWorldMap
    // File location to save and restore the AR world map
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    
    // TAG: - Vision classification
    // Vision-based object classification using CoreML
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Instantiate the model from its generated Swift class.
            let model = try VNCoreMLModel(for: Inceptionv3().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            
            // Crop input images to square area at center, matching the way the ML model was trained.
            // Ensures consistency with trained model
            request.imageCropAndScaleOption = .centerCrop
            
            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            // Avoids excessive GPU usage since ARKit uses it heavily
            request.usesCPUOnly = true
            
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    // Holds the latest camera frame for processing
    public var currentBuffer: CVPixelBuffer?
    
    // Queue for dispatching vision classification requests
    // Background queue for Vision tasks
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")
    
    
    // Classification results
    // Stores the name and confidence level of the recognized object
    private var identifierString = ""
    private var carbonFootprintData: (value: Double, unit: String)? = nil
    private var confidence: VNConfidence = 0.0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            // ask for location permission
            self.locationManager.requestAlwaysAuthorization()
            
            // for use in foreground
            self.locationManager.requestWhenInUseAuthorization()
            
            // Add top label initialization here
            self.addTopLabel()
            
            // Hide buttons if not the session host
            self.detectBtn.isHidden = !self.isHost
            self.restoreBtn.isHidden = !self.isHost
            self.saveBtn.isHidden = !self.isHost
            self.restoreBtn.isEnabled = self.retrieveWorldMapData(from: self.worldMapURL) != nil
            
            // Setup peer-to-peer session for AR collaboration
            self.multipeerSession = MultipeerSession(receivedDataHandler: self.receivedData)
            
            // Setup UI container
            self.setupContainerView()
            
            // Setup tap gesture recognizers
            self.setupGestureRecognizers()
        }

        // control flow placed outside of DispatchQueue.main.async
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
        }
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        DispatchQueue.main.async {
//            // ask for location permission
//            self.locationManager.requestAlwaysAuthorization()
//
//            // for use in foreground
//            self.locationManager.requestWhenInUseAuthorization()
//
//            // Hide buttons if not the session host
//            self.detectBtn.isHidden = !self.isHost
//            self.restoreBtn.isHidden = !self.isHost
//            self.saveBtn.isHidden = !self.isHost
//            self.restoreBtn.isEnabled = self.retrieveWorldMapData(from: self.worldMapURL) != nil
//
//            // // Setup peer-to-peer session for AR collaboration
//            self.multipeerSession = MultipeerSession(receivedDataHandler: self.receivedData)
//
//            // Setup UI container
//            self.setupContainerView()
//
//            // Setup tap gesture recognizers
//            self.setupGestureRecognizers()
//        }
//
//        // control flow placed outside of DispatchQueue.main.async
//        // since it may lead to UI unresponsiveness
//        //
//        // CLLocation.locationServicesEnabled() returns a boolean
//        if CLLocationManager.locationServicesEnabled() {
//            self.locationManager.delegate = self
//            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest       // want best location
//            self.locationManager.startUpdatingLocation()
//        }
//    }

    private func setupGestureRecognizers() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        doubletapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapped))
        doubletapGestureRecognizer.numberOfTapsRequired = 2
        tapGestureRecognizer.require(toFail: doubletapGestureRecognizer)    // Ensures double tap takes priority
        
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        sceneView.addGestureRecognizer(doubletapGestureRecognizer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.startARSession()
        }
    }
    
    // NOTE : this function will automatically run in the background while the application is active
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation :CLLocation = locations[0] as CLLocation

        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
        
        self.current_latitude = "\(userLocation.coordinate.latitude)"
        self.current_longitude = "\(userLocation.coordinate.longitude)"

//        let geocoder = CLGeocoder()
//        geocoder.reverseGeocodeLocation(userLocation) { (placemarks, error) in
//            if (error != nil){
//                print("error in reverseGeocode")
//            }
//            let placemark = placemarks! as [CLPlacemark]
//            if placemark.count>0{
//                let placemark = placemarks![0]
//                print(placemark.locality!)
//                print(placemark.administrativeArea!)
//                print(placemark.country!)
//
//                self.labelAdd.text = "\(placemark.locality!), \(placemark.administrativeArea!), \(placemark.country!)"
//            }
//        }

    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the AR session when leaving the screen
        sceneView.session.pause()
    }
    
    @IBAction func saveBtnHandler(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.saveCurrentWorldMap()
        }
    }
    
    @IBAction func restoreBtnHandler(_ sender: UIButton) {
        guard let worldMapData = retrieveWorldMapData(from: worldMapURL),
            let worldMap = unarchive(worldMapData: worldMapData) else { return }
        restore(worldMap: worldMap)
    }
    
    // MARK: - Item List View
    private var itemListHeightConstraint: NSLayoutConstraint!

    private func setupContainerView() {
        DispatchQueue.main.async {
            self.addChild(self.listViewController)
            self.listViewController.delegate = self
            
            self.listViewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.sceneView.addSubview(self.listViewController.view)
            self.sceneView.bringSubviewToFront(self.listViewController.view)
            
            self.itemListHeightConstraint = self.listViewController.view.heightAnchor.constraint(equalToConstant: 0)
            
            NSLayoutConstraint.activate([
                self.listViewController.view.bottomAnchor.constraint(equalTo: self.sceneView.bottomAnchor),
                self.listViewController.view.rightAnchor.constraint(equalTo: self.sceneView.rightAnchor),
                self.listViewController.view.leftAnchor.constraint(equalTo: self.sceneView.leftAnchor),
                self.itemListHeightConstraint
            ])
        }
    }
    
    // wrapped around DispatchQueue.main.async
    @objc func handleTapped(_ notification: UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.sceneView.removeGestureRecognizer(self.tapGestureRecognizer)
            self.itemListHeightConstraint.constant = 200
            
            UIView.animate(withDuration: 0.8) {
                self.view.layoutIfNeeded()
                self.detectBtn.isHidden = true
                self.listViewController.collectionView.reloadData()
            }
        }
    }

//    @objc func handleTapped(_ notification: UITapGestureRecognizer) {
//        sceneView.removeGestureRecognizer(tapGestureRecognizer)
//        itemListHeightConstraint.constant =  200
//
//        UIView.animate(withDuration: 0.8) {
//            self.view.layoutIfNeeded()
//            self.detectBtn.isHidden = true
//            self.listViewController.collectionView.reloadData()
//        }
//    }
    
    @objc func handleDoubleTapped(_ notification: UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.sceneView.addGestureRecognizer(self.tapGestureRecognizer)
            self.itemListHeightConstraint.constant = 0
            
            UIView.animate(withDuration: 0.8) {
                self.view.layoutIfNeeded()
                self.detectBtn.isHidden = false
            }
        }
    }
    
    @IBAction func shareSession(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.shareARWorldMap()
        }
//        shareARWorldMap()
    }
    
    @IBAction func detectObject(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.classifyCurrentImage()
        }

    }
    
    @IBAction func resetGuidence(_ sender: UIButton) {
        for node in sceneView.pointOfView!.childNodes {
            node.removeFromParentNode()
        }
    }
    
    private func shareARWorldMap() {
        if ItemModel.shared.getList().isEmpty { return }
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            
            DispatchQueue.main.async {
                self.multipeerSession.sendToAllPeers(data)
            }
        }
    }
    
    private func startARSession() {
        DispatchQueue.main.async {
            // Start the view's AR session with a configuration that uses the rear camera,
            // device position and orientation tracking, and plane detection.
            self.resetTrackingConfiguration()
            
            // Set a delegate to track the number of plane anchors for providing UI feedback.
            self.sceneView.delegate = self
            self.sceneView.session.delegate = self
            
            // Prevent the screen from being dimmed after a while
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    private func resetTrackingConfiguration(worldMap: ARWorldMap? = nil) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading       // Aligns AR session to real-world gravity and compass heading
        configuration.planeDetection = [.horizontal, .vertical]     // Enables surface detection
        configuration.initialWorldMap = worldMap        // Loads saved AR world if available
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        
        sceneView.session.run(configuration, options: options)
    }
    
    private func saveCurrentWorldMap() {
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            guard let worldMap = worldMap else { return }
            
            do {
                try self.archive(worldMap: worldMap)
            } catch {
                fatalError("Error saving world map: \(error.localizedDescription)")
            }
        }
    }
    
    
    // restores previous session based on items tagged
    private func restore(worldMap: ARWorldMap) {
        resetTrackingConfiguration(worldMap: worldMap)
        
        // Re-add stored items from the world map
        for anchor in worldMap.anchors {
            if let name = anchor.name, !name.isEmpty {
                ItemModel.shared.addItem(name: identifierString, anchor: anchor)
            }
        }
    }
    
    private func retrieveWorldMapData(from url: URL) -> Data? {
        do {
            return try Data(contentsOf: self.worldMapURL)
        } catch {
            print("Error retrieving world map data.")
            return nil
        }
    }
    
    // Archive and Unarchive WorldMap
    private func archive(worldMap: ARWorldMap) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: self.worldMapURL, options: [.atomic])
    }
    
    private func unarchive(worldMapData data: Data) -> ARWorldMap? {
        guard let unarchievedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data),
            let worldMap = unarchievedObject else { return nil }
        return worldMap
    }
    
    /// add ARAnchor onto current plane
//    public func placeObjectNode() {
//        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
//        guard let hitTestResult = sceneView.hitTest(screenCentre, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]).first else { return }
//
//        // Place an anchor for a virtual character.
//        let anchor = ARAnchor(name: identifierString, transform: hitTestResult.worldTransform)
//        sceneView.session.add(anchor: anchor)
//
//        print("adding item:", identifierString)
//        // add to item model
//        ItemModel.shared.addItem(name: identifierString, anchor: anchor)
//
//        // Send the anchor info to peers, so they can place the same content.
//        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
//            else { fatalError("can't encode anchor") }
//        self.multipeerSession.sendToAllPeers(data)
//
//    }
    
    public func placeObjectNode() {
        DispatchQueue.main.async {
            let screenCentre: CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
            guard let hitTestResult = self.sceneView.hitTest(screenCentre, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]).first else { return }
        
            let anchor = ARAnchor(name: self.identifierString, transform: hitTestResult.worldTransform)
            self.sceneView.session.add(anchor: anchor)
            
            ItemModel.shared.addItem(name: self.identifierString, anchor: anchor)
            
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                else { fatalError("can't encode anchor") }
            self.multipeerSession.sendToAllPeers(data)

            if let carbonData = self.carbonFootprintData {
                self.displayCarbonFootprint(text: "\(carbonData.value) \(carbonData.unit)", at: hitTestResult.worldTransform)
            }
        }
    }
    
    private func displayCarbonFootprint(text: String, at transform: simd_float4x4) {
        let textNode = createNewBubbleParentNode(text)
        let anchor = ARAnchor(transform: transform)

        sceneView.session.add(anchor: anchor)
        sceneView.scene.rootNode.addChildNode(textNode)

        // Position the text slightly above the object
        textNode.position = SCNVector3(transform.columns.3.x, transform.columns.3.y + 0.15, transform.columns.3.z)
        
        // Add a simple animation
        textNode.opacity = 0
        let fadeIn = SCNAction.fadeIn(duration: 0.5)
        let moveUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 0.5)
        let group = SCNAction.group([fadeIn, moveUp])
        textNode.runAction(group)
    }

    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if let name = anchor.name, !name.isEmpty {
            // Create 3D Text
            let textNode: SCNNode = createNewBubbleParentNode(name)
            return textNode
        }

        return nil
    }
    
    private func fetchCarbonFootprint(for item: String, completion: @escaping ((value: Double, unit: String)?) -> Void) {
        // Construct the API URL with the encoded item name
        guard let encodedItem = item.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(
                string: "https://server-1sqv.onrender.com/carbon?item=\(encodedItem)"
//                string: "https://localhost:3000/api/carbon?item=\(encodedItem)"
              ) else {
            print("Invalid URL")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        // Make the network request
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching carbon data: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let carbonFootprint = json["carbon_footprint"] as? Double,
                   let unit = json["unit_of_carbon"] as? String {
                    DispatchQueue.main.async {
                        completion((carbonFootprint, unit))  // ✅ Now safely updates UI
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        task.resume() // Start the network request
    }
    
    

}

// MARK: - Vision Task
@available(iOS 13.0, *)
extension ViewController {
    
    // Host can tag item when objection recognition is not working
    // retrieves name of item
    private func tagByUserInput() {
        let title = "UNIDENTIFIED"
        let msg = "Please enter the item"
        
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        
        let ok = UIAlertAction(title: "OK", style: .default) { (_) in
            if let textField = alert.textFields?.first, let value = textField.text {
                self.identifierString = value
                self.fetchCarbonFootprint(for: value) { carbonData in
                    DispatchQueue.main.async {
                        self.carbonFootprintData = carbonData
                        self.placeObjectNode()
                    }
                }
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(cancel)
        alert.addAction(ok)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // Run the Vision+ML classifier on the current image buffer.
    public func classifyCurrentImage() {
        guard let currentBuffer = self.currentBuffer else { return }
        
        // Most computer vision tasks are not rotation agnostic so it is important to pass in the orientation of the image with respect to device.
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer, orientation: orientation)
        
        visionQueue.async {
            do {
                try requestHandler.perform([self.classificationRequest])
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    // Handle completion of the Vision request and choose results to display.
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("❌ Unable to classify image. Error:", error?.localizedDescription ?? "Unknown error")
            return
        }
        
        print("✅ ML Model is running: Received classification results.")

        let classifications = results as! [VNClassificationObservation]

        if let bestResult = classifications.first(where: { result in result.confidence > 0.5 }),
           let label = bestResult.identifier.split(separator: ",").first {
            self.identifierString = String(label)
            self.confidence = bestResult.confidence
            
            print("✅ Identified object: \(self.identifierString) with confidence \(self.confidence * 100)%")

            self.fetchCarbonFootprint(for: self.identifierString) { carbonData in
                DispatchQueue.main.async {
                    self.carbonFootprintData = carbonData
                    self.displayClassifierResults()
                    self.placeObjectNode()
                }
            }
        } else {
            self.identifierString = ""
            self.confidence = 0
            DispatchQueue.main.async {
                self.tagByUserInput()
            }
        }
    }

    private func displayClassifierResults() {
        DispatchQueue.main.async {
            guard !self.identifierString.isEmpty else { return }

            var message = String(format: "✅ Detected %@ with %.1f%%", self.identifierString, self.confidence * 100)
            
            if let carbonData = self.carbonFootprintData {
                message += "\n🌱 Carbon Footprint: \(String(format: "%.2f", carbonData.value)) \(carbonData.unit)"
            }

            self.statusViewController.showMessage(message)
        }
    }

    
    
    // Show the classification results in the UI.
//    private func displayClassifierResults() {
//        guard !self.identifierString.isEmpty else { return } // No object was classified.
//        let message = String(format: "Detected \(self.identifierString) with %.2f", self.confidence * 100) + "% confidence"
//        statusViewController.showMessage(message)
//    }
}

// MARK: - ARSessionDelegate
@available(iOS 13.0, *)
extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.main.async {
            self.updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
        
            if case .normal = frame.camera.trackingState {
                self.detectBtn.isEnabled = true
            } else {
                self.detectBtn.isEnabled = false
            }
        }

        // This is fine on background thread
        self.currentBuffer = frame.capturedImage
    }
    
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//
//        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
//
//        if case .normal = frame.camera.trackingState {
//            detectBtn.isEnabled = true
//        } else {
//            detectBtn.isEnabled = false
//        }
//
//        // Retain the image buffer for Vision processing.
//        self.currentBuffer = frame.capturedImage
//
//    }
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
            if isHost {
                sendMapButton.isHidden = multipeerSession.connectedPeers.isEmpty
//                Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { (_) in
//                    self.shareARWorldMap()
//                }
            }
            
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        self.sessionInfoLabel.text = message
        self.sessionInfoView.isHidden = message.isEmpty
        
    }
}

@available(iOS 13.0, *)
extension ViewController {
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
        if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [ARWorldMap.classForKeyedArchiver()!], from: data),
            let worldMap = unarchived as? ARWorldMap {
            
            // Remember who provided the map for showing UI feedback.
            mapProvider = peer
            print("Received Data From Peer", peer.displayName)
            
            DispatchQueue.main.async {
                // Move all UI and session updates to main thread
                self.resetTrackingConfiguration(worldMap: worldMap)
                
                // re-add ItemModel
                for anchor in worldMap.anchors {
                    if let name = anchor.name, !name.isEmpty {
                        ItemModel.shared.addItem(name: self.identifierString, anchor: anchor)
                    }
                }
                
                if let frame = self.sceneView.session.currentFrame {
                    self.updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
                }
            }
        }
        else {
            print("unknown data received from \(peer)")
        }
    }
    /// - Tag: ReceiveData
//    func receivedData(_ data: Data, from peer: MCPeerID) {
//        if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [ARWorldMap.classForKeyedArchiver()!], from: data),
//            let worldMap = unarchived as? ARWorldMap {
//
//            // Remember who provided the map for showing UI feedback.
//            mapProvider = peer
//            print("Received Data From Peer", peer.displayName)
//
//            // Run the session with the received world map.
//            resetTrackingConfiguration(worldMap: worldMap)
//
//            // re-add ItemModel
//            for anchor in worldMap.anchors {
//                if let name = anchor.name, !name.isEmpty {
//                    ItemModel.shared.addItem(name: identifierString, anchor: anchor)
//                }
//            }
//
//        }
//        else {
//            print("unknown data recieved from \(peer)")
//        }
//    }
}

// MARK : - Handle Item List
// Extends the functionality of ViewController
@available(iOS 13.0, *)
extension ViewController: ItemListDragProtocol {
    private var topLabelView: TopLabelView {
            get {
                if let existing = view.subviews.first(where: { $0 is TopLabelView }) as? TopLabelView {
                    return existing
                }
                let new = TopLabelView(effect: nil)
                new.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(new)
                
                NSLayoutConstraint.activate([
                    new.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
                    new.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    new.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9),
                    new.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
                ])
                
                return new
            }
        }
        
        func addTopLabel() {
            _ = topLabelView // Initialize the label
            updateDirectionText(angle: 0)
        }
        
        func updateDirectionText(angle: Float) {
            // Convert angle to degrees
            let degrees = angle * 180 / .pi
            
            // Determine direction based on angle
            let direction: String
            if abs(degrees) > 170 {
                direction = "Go Straight"
            } else if degrees > 0 {
                direction = "Turn Left"
            } else {
                direction = "Turn Right"
            }
            
            // Update the label text
            DispatchQueue.main.async {
                self.topLabelView.setText("\(direction) (angle: \(Int(degrees))°)")
            }
        }
        
        // Add this to your showDirection method
        func getDirectionAngle(from pointOfView: SCNNode, to targetPoint: SCNVector3) -> Float {
            // Get camera's current position and orientation
            let cameraPosition = pointOfView.worldPosition
            let cameraForward = pointOfView.worldFront // This gets the direction camera is facing
            
            // Vector from camera to target
            let toTarget = SCNVector3(
                targetPoint.x - cameraPosition.x,
                0, // Ignore Y component for horizontal angle
                targetPoint.z - cameraPosition.z
            )
            
            // Calculate angles (in radians)
            let targetAngle = atan2(toTarget.x, toTarget.z)
            let cameraAngle = atan2(cameraForward.x, cameraForward.z)
            
            // Get relative angle between camera direction and target
            var relativeAngle = targetAngle - cameraAngle
            
            // Normalize angle to be between -π and π
            while relativeAngle > .pi {
                relativeAngle -= 2 * .pi
            }
            while relativeAngle < -.pi {
                relativeAngle += 2 * .pi
            }
            
            return relativeAngle
        }
    private func loadObject() -> SCNNode {
        // MARK: - AR session management
        let sceneURL = Bundle.main.url(forResource: "ArrowB", withExtension: "scn", subdirectory: "art.scnassets")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        return referenceNode
    }
    
    // https://github.com/hanleyweng/CoreML-in-ARKit
    private func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        let font = UIFont(name: "Futura", size: 0.15)
        bubble.font = font
        bubble.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    public func closeItemList() {
        itemListHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
            self.detectBtn.isHidden = false
        }
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    
    // TODO : add the distance of the function
    // Function that deals with positioning and coordinates
    public func showDirection(of object: ARItem) {

        guard let pointOfView = sceneView.pointOfView else { return }
        
        // remove previous instruction
        for node in pointOfView.childNodes {
            node.removeFromParentNode()
        }
        
        // Define the target position (where the item is located)
        let desNode = SCNNode()
        let targetPoint = SCNVector3.positionFromTransform(object.anchor.transform)
        
        // Add these two lines here
            let angle = getDirectionAngle(from: pointOfView, to: targetPoint)
            updateDirectionText(angle: angle)
        
        // NOTE : assert_eq!(desnode.worldPosition == targetPoint, 0.0)
        desNode.worldPosition = targetPoint
        
        print("destination node position info : desNode.position")
        
        // this works
        print("World Position of destination is : \(desNode.worldPosition.x)\n\n")
    
        let startPoint = SCNVector3(0, 0 , -1.0)
        
        // Define the starting point (user's current position in the AR world)
        // NOTE : to calculate the distance, calculate the difference of the two vectors
        // apply the distance formula to determine the distance
        //
        // NOTE : not entirely sure if this should be var or let
        
        // calculate the difference
        var x_coordinate_diff = targetPoint.x - startPoint.x
        var y_ccordinate_diff = targetPoint.y - startPoint.y
        var z_coordinate_diff = targetPoint.z - startPoint.z
        
        // distance formula
        var distance = ((x_coordinate_diff * x_coordinate_diff) + (y_ccordinate_diff * y_ccordinate_diff) + (z_coordinate_diff * z_coordinate_diff)).squareRoot()
        
        print("distance is : \(distance)")
        self.distance = distance
        
//        locationManager(self.locationManager)
        // Load the arrow object (this will be the guide for the user)
        // Assuming you have a method to load 3D objects (like arrows)
        let guideNode = loadObject()
        guideNode.scale = SCNVector3(0.7, 0.7, 0.7)         // helps adjust the size of the arrow
        guideNode.position = startPoint
        
        let lookAtConstraints = SCNLookAtConstraint(target: desNode)
        lookAtConstraints.isGimbalLockEnabled = true
        
        // Adjust the arrow's pivot so that it points in the correct direction
        guideNode.pivot = SCNMatrix4Rotate(guideNode.pivot, Float.pi, 0, 1, 1)
        
        // Apply the constraint to the guide node
        guideNode.constraints = [lookAtConstraints]
        
        // Add the guide node to the point of view (camera) to show it in the AR scene
        pointOfView.addChildNode(guideNode)
        
        // Create distance text node
        let distanceText = SCNText(string: String(format: "%.2f meters", distance), extrusionDepth: 0.1)
        distanceText.font = UIFont.systemFont(ofSize: 0.3)
        distanceText.firstMaterial?.diffuse.contents = UIColor.white
        let textNode = SCNNode(geometry: distanceText)
        
        // Position text above the arrow
        textNode.position = SCNVector3(0, 0.5, 0) // Adjust the y value (0.5) to position higher or lower
        textNode.scale = SCNVector3(0.1, 0.1, 0.1) // Make text smaller

        // Add billboard constraint to make text always face the camera
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = .all
        textNode.constraints = [billboardConstraint]

        // Add text as child of guide node so it moves with the arrow
        guideNode.addChildNode(textNode)

//        let lookAtConstraints = SCNLookAtConstraint(target: desNode)
//        lookAtConstraints.isGimbalLockEnabled = true
    }
    
}



class TopLabelView: UIVisualEffectView {
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(effect: UIVisualEffect?) {
        super.init(effect: UIBlurEffect(style: .dark))
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        contentView.addSubview(label)
        
        layer.cornerRadius = 10
        clipsToBounds = true
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func setText(_ text: String) {
        label.text = text
    }
}
