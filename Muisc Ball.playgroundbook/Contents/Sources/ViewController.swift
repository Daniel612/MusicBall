//
// ViewController.swift
//
//  Created by daniel on 2018/3/14.
//  Copyright © 2018年 com.danielios. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import PlaygroundSupport

@objc(ViewController)
public class ViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    // MARK: - UI Elements
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var restartExperienceButton: UIButton!
    @IBOutlet weak var messagePanel: UIVisualEffectView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var toggleModeButton: UIButton!
    @IBOutlet weak var notesStackView: UIStackView!
    @IBOutlet weak var placeholderButton: UIButton!
    var spinner: UIActivityIndicatorView?
    
    // MARK: - Constraints
    
    @IBOutlet weak var restartExperienceButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messagePanelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var toggleModeButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var notesStackViewBottomConstraint: NSLayoutConstraint!
    
    
    // MARK: - ARKit Config Properties
    
    var screenCenter: CGPoint?
    
    let session = ARSession()
    
    let standardConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }()
    
    // MARK: - Virtual Object Manipulation Properties
    
    var virtualObjectManager: VirtualObjectManager!
    
    var isLoadingObject: Bool = false {
        didSet {
            DispatchQueue.main.async {
                for view in self.notesStackView.subviews {
                    let button = view as! MusicalNoteButton
                    button.isEnabled = !self.isLoadingObject
                }
                self.toggleModeButton.isEnabled = !self.isLoadingObject
                self.restartExperienceButton.isEnabled = !self.isLoadingObject
            }
        }
    }
    
    // MARK: - Properties
    
    /// Timer to control play audio
    var playTime: TimeInterval = 0
    
    // MAKR: - Other Properties
    
    /// The status of scene
    var isMaking: Bool = true
    /// Musical note definition array
    var musicalNotes: [MusicalNoteDefinition] = []
    /// The note button you chose last time
    var lastChoseNoteButton: UIButton?
    var restartExperienceButtonIsEnabled = true
    var textManager: TextManager!
    // Light intensity
    var environmentMapIntensity: CGFloat = 150
    
    // MARK: - Queues
    
    let serialQueue = DispatchQueue(label: "com.danielios.musicball.serialSceneKitQueue")
    
    // MARK: - Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        isMaking = true
        
        setupUIControls()
        setupScene()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Prevent the screen from being dimmed after a while.
//        UIApplication.shared.isIdleTimerDisabled = true
        
        if ARWorldTrackingConfiguration.isSupported {
            // Start the ARSession.
            resetTracking()
            // Debug Options
//            sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
//            sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        } else {
            // This device does not support 6DOF world tracking.
            let sessionErrorMsg = "This app requires world tracking. World tracking is only available on iOS devices with A9 processor or newer. " +
            "Please quit the application."
            displayErrorMessage(title: "Unsupported platform", message: sessionErrorMsg, allowRestart: false)
        }
    }
    
    override public func updateViewConstraints() {
        resetConstraintsForViewSize()
        super.updateViewConstraints()
    }
    
    override public func viewDidLayoutSubviews() {
        resetConstraintsForViewSize()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: - Setup
    
    private func setupScene() {
        
        // Synchronize updates via the `serialQueue`.
        virtualObjectManager = VirtualObjectManager(updateQueue: serialQueue)
        virtualObjectManager.delegate = self
        
        // Setup
        sceneView.setup()
        sceneView.delegate = self
        sceneView.session = session
        
        // Custom intensity
        sceneView.scene.enableEnvironmentMapWithIntensity(environmentMapIntensity, queue: serialQueue)
        
        setupFocusSquare()
        
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }
    }
    
    private func setupUIControls() {
        textManager = TextManager(viewController: self)
        
        // Set appearance of message output panel
        messagePanel.isHidden = true
        messageLabel.text = ""
        
        placeholderButton.removeFromSuperview()
        setupMusicialNoteButtons(toSuperView: notesStackView)
    }
    
    /// Make buttons by note definition
    private func setupMusicialNoteButtons(toSuperView superView: UIStackView) {
        if let jsonData = noteJsonString.data(using: .utf8) {
            musicalNotes = try! JSONDecoder().decode([MusicalNoteDefinition].self, from: jsonData)
        }
        
        for definition in musicalNotes {
            let button = MusicalNoteButton(definition: definition)
            button.addTarget(self, action: #selector(chooseNote(_:)), for: .touchUpInside)
            superView.addArrangedSubview(button)
        }
        // Choose the first button when user launch the scene first.
//        chooseNote(superView.subviews.first as! MusicalNoteButton)
    }
    
    /// Setup constraint
    private func resetConstraintsForViewSize() {
        restartExperienceButtonTopConstraint.constant = liveViewSafeAreaGuide.layoutFrame.minY + 20
        messagePanelTopConstraint.constant = liveViewSafeAreaGuide.layoutFrame.minY + 20
        toggleModeButtonTopConstraint.constant = liveViewSafeAreaGuide.layoutFrame.minY + 20
        notesStackViewBottomConstraint.constant = liveViewSafeAreaGuide.layoutFrame.minY + 20
        view.setNeedsUpdateConstraints()
    }
    
    // MARK: - Gesture Recognizer
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesBegan(touches, with: event, in: self.sceneView)
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesMoved(touches, with: event)
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesEnded(touches, with: event)
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesCancelled(touches, with: event)
    }
    
    // MARK: - Planes
    
    var planes = [ARPlaneAnchor: Plane]()
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        
        let plane = Plane(anchor)
        planes[anchor] = plane
        node.addChildNode(plane)
        
        // Text handle module
        textManager.cancelScheduledMessage(forType: .planeEstimation)
        textManager.showMessage("SURFACE DETECTED")
        
        if virtualObjectManager.virtualObjects.isEmpty {
            textManager.scheduleMessage("TAP Button TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .contentPlacement)
        }
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
    
    func resetTracking() {
        session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        
        textManager.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT",
                                    inSeconds: 7.5,
                                    messageType: .planeEstimation)
    }
    
    // MARK: - Focus Square
    
    var focusSquare: FocusSquare?
    
    func setupFocusSquare() {
        // Remove old and create new focusSquare
        serialQueue.async {
            self.focusSquare?.isHidden = true
            self.focusSquare?.removeFromParentNode()
            self.focusSquare = FocusSquare()
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare!)
        }
        
        textManager.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
    }
    
    func updateFocusSquare() {
        guard let screenCenter = screenCenter else { return }
        
        DispatchQueue.main.async {
            // Hide or unhide depend on the mode of the scene.
            if self.isMaking {
                self.focusSquare?.unhide()
                self.standardConfiguration.planeDetection = .horizontal
            } else {
                self.focusSquare?.hide()
                // Disable plane detect and update
                self.standardConfiguration.planeDetection = .init(rawValue: 0)
            }
            // Run again to change
            self.sceneView.session.run(self.standardConfiguration)
            let (worldPos, planeAnchor, _) = self.virtualObjectManager.worldPositionFromScreenPosition(screenCenter,
                                                                                                       in: self.sceneView,
                                                                                                       objectPos: self.focusSquare?.simdPosition)
            if let worldPos = worldPos {
                self.serialQueue.async {
                    self.focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
                }
                self.textManager.cancelScheduledMessage(forType: .focusSquare)
            }
        }
    }
    
    // MARK: - Light
    
    func insertSpotLight(position: SCNVector3) {
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.spotInnerAngle = 45
        spotLight.spotOuterAngle = 45
        
        let spotNode = SCNNode()
        spotNode.light = spotLight
        spotNode.position = position
        
        // By default the stop light points directly down the negative
        // z-axis, we want to shine it down so rotate 90deg around the
        // x-axis to point it down
        spotNode.eulerAngles = SCNVector3Make(-.pi / 4, 0, 0)
        self.sceneView.scene.rootNode.addChildNode(spotNode)
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
        // Blur the background.
        textManager.blurBackground()
        
        if allowRestart {
            // Present an alert informing about the error that has occurred.
            let restartAction = UIAlertAction(title: "Reset", style: .default) { _ in
                self.textManager.unblurBackground()
                self.restartExperience(self)
            }
            textManager.showAlert(title: title, message: message, actions: [restartAction])
        } else {
            textManager.showAlert(title: title, message: message, actions: [])
        }
    }
    
    // MARK: Static
    
    public static func makeFromStoryboard() -> ViewController {
        let bundle = Bundle(for: ViewController.self)
        let storyboard = UIStoryboard(name: "Main", bundle: bundle)
        return storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
    }
}
