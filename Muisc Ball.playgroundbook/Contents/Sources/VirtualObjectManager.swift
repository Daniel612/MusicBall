/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A type which controls the manipulation of virtual objects.
*/

import Foundation
import ARKit

class VirtualObjectManager {
	
	weak var delegate: VirtualObjectManagerDelegate?
	
	var virtualObjects = [VirtualObject]()
    
    // Use this property to place last object
	var lastUsedObject: VirtualObject?
    
    // Use this property to determine whether play audio
    var lastPlayedObject: VirtualObject?
    
    /// The queue with updates to the virtual objects are made on.
    var updateQueue: DispatchQueue
    
    init(updateQueue: DispatchQueue) {
        self.updateQueue = updateQueue
    }
	
	// MARK: - Resetting objects

	func removeAllVirtualObjects() {
		for object in virtualObjects {
			unloadVirtualObject(object)
		}
		virtualObjects.removeAll()
	}
	
//    func removeVirtualObject(at index: Int) {
//        let definition = VirtualObjectManager.availableObjects[index]
//        guard let object = virtualObjects.first(where: { $0.definition == definition })
//            else { return }
//
//        unloadVirtualObject(object)
//        if let pos = virtualObjects.index(of: object) {
//            virtualObjects.remove(at: pos)
//        }
//    }
	
	private func unloadVirtualObject(_ object: VirtualObject) {
		updateQueue.async {
			object.removeFromParentNode()
            // If the last used object is that you want to remove
			if self.lastUsedObject == object {
				self.lastUsedObject = nil
				if self.virtualObjects.count > 1 {
                    // Set the first object in the queue to last used
					self.lastUsedObject = self.virtualObjects[0]
				}
			}
		}
	}
	
	// MARK: - Loading object
    
	/// Load Virtual Object
    /// - parameter object: the virtual object to load
    /// - parameter position: the position to place
    /// - parameter cameraTransform: camera's transform matrix
	func loadVirtualObject(_ object: VirtualObject, to position: float3, cameraTransform: matrix_float4x4) {
		self.virtualObjects.append(object)  // add to list
		self.delegate?.virtualObjectManager(self, willLoad: object) // update view or do something by viewController
		
		// Load the content asynchronously.
        DispatchQueue.global(qos: .userInitiated).async {
            object.loadModel()
            
            // Immediately place the object in 3D space.
            self.updateQueue.async {
                self.setNewVirtualObjectPosition(object, to: position, cameraTransform: cameraTransform)
                self.lastUsedObject = object
                
                self.delegate?.virtualObjectManager(self, didLoad: object)
            }
        }
	}
    
    // MARK: - Animation
    
    func showVirtualObject(_ object: VirtualObject, from value1: Float, to value2: Float) {
        
        let scaleAnimaiton = CAKeyframeAnimation(keyPath: "scale")
        scaleAnimaiton.keyTimes = [0.0, 0.5, 0.7, 0.8, 0.875, 0.95, 1.0]
        scaleAnimaiton.values = [
            SCNVector3(value1, value1, value1),
            SCNVector3(1.1, 1.1, 1.1),
            SCNVector3(0.92, 0.92, 0.92),
            SCNVector3(1.05, 1.05, 1.05),
            SCNVector3(0.97, 0.97, 0.97),
            SCNVector3(1.02, 1.02, 1.02),
            SCNVector3(value2, value2, value2)
        ]
        scaleAnimaiton.duration = 0.3
        scaleAnimaiton.repeatCount = 1
        let scaleSCNAnimation = SCNAnimation(caAnimation: scaleAnimaiton)
        let scaleSCNAnimationPlayer = SCNAnimationPlayer(animation: scaleSCNAnimation)
        object.addAnimationPlayer(scaleSCNAnimationPlayer, forKey: "scalePlayer")
        
        DispatchQueue.main.async {
            let moveAction = SCNAction.move(by: SCNVector3(0, -0.05, 0), duration: 0.5)
            object.runAction(moveAction)
        }
        
        DispatchQueue.main.async {
            scaleSCNAnimationPlayer.play()
        }
    }
    
    func easeVirtualObject(_ object: VirtualObject, from value1: Float, to value2: Float) {
        let scaleAnimaiton = CAKeyframeAnimation(keyPath: "scale")
        scaleAnimaiton.keyTimes = [0.0, 0.5, 0.7, 0.8, 0.875, 0.95, 1.0]
        scaleAnimaiton.values = [
            SCNVector3(value1, value1, value1),
            SCNVector3(0.7, 0.7, 0.7),
            SCNVector3(1.1, 1.1, 1.1),
            SCNVector3(0.9, 0.9, 0.9),
            SCNVector3(1.05, 1.05, 1.05),
            SCNVector3(0.98, 0.98, 0.98),
            SCNVector3(value2, value2, value2)
        ]
        scaleAnimaiton.duration = 0.5
        scaleAnimaiton.repeatCount = 1
        let scaleSCNAnimation = SCNAnimation(caAnimation: scaleAnimaiton)
        let scaleSCNAnimationPlayer = SCNAnimationPlayer(animation: scaleSCNAnimation)
        object.addAnimationPlayer(scaleSCNAnimationPlayer, forKey: "easeObject")
        
        scaleSCNAnimationPlayer.play()
    }
    
    // MARK: - Distance
    
    func closeToVirtualObejct(pointOfView: SCNNode) {
        
        var closestObject: VirtualObject?
        
        // Correct the user position such that it is a few centimeters in front of the camera.
        let inFrontOfCameraNode = SCNNode()
        inFrontOfCameraNode.position.z = -0.015
        inFrontOfCameraNode.name = "inFrontOfCameraNode"
        pointOfView.presentation.addChildNode(inFrontOfCameraNode)
        let userPosition = inFrontOfCameraNode.worldPosition
        inFrontOfCameraNode.removeFromParentNode()
        
        for object in virtualObjects {
            let length = (userPosition - object.worldPosition).length()
            if length < 0.25 {
                closestObject = object
            }
        }
        
        if closestObject != lastPlayedObject {
            let concurrentQueue = DispatchQueue(label: "com.danielios.concurrentQueue", qos: .userInteractive, attributes: .concurrent)
            concurrentQueue.async {
                if closestObject != nil {
                    let play = SCNAction.playAudio((closestObject?.audio)!, waitForCompletion: true)
                    self.easeVirtualObject(closestObject!, from: 1, to: 1)
                    closestObject?.runAction(play)
                }
                print("现在播放音乐\(String(describing: closestObject?.audio))")
                self.lastPlayedObject = closestObject
            }
        }
    }
	
	// MARK: - React to gestures
	
    private var currentGesture: Gesture?

    func reactToTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in sceneView: ARSCNView) {
        if virtualObjects.isEmpty {
            return
        }

        if currentGesture == nil {
            currentGesture = Gesture.startGestureFromTouches(touches, sceneView, lastUsedObject, self)
            if let newObject = currentGesture?.lastUsedObject {
                lastUsedObject = newObject
            }
        } else {
            currentGesture = currentGesture!.updateGestureFromTouches(touches, .touchBegan)
            if let newObject = currentGesture?.lastUsedObject {
                lastUsedObject = newObject
            }
        }
    }

    func reactToTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObjects.isEmpty {
            return
        }

        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchMoved)
        if let newObject = currentGesture?.lastUsedObject {
            lastUsedObject = newObject
        }

        if let gesture = currentGesture, let object = gesture.lastUsedObject {
            delegate?.virtualObjectManager(self, transformDidChangeFor: object)
        }
    }

    func reactToTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObjects.isEmpty {
            return
        }
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchEnded)
        if let newObject = currentGesture?.lastUsedObject {
            lastUsedObject = newObject
        }

        if let gesture = currentGesture, let object = gesture.lastUsedObject {
            delegate?.virtualObjectManager(self, transformDidChangeFor: object)
        }
    }

    func reactToTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObjects.isEmpty {
            return
        }
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchCancelled)
    }
	
	// MARK: - Update object position
	
	func translate(_ object: VirtualObject, in sceneView: ARSCNView, basedOn screenPos: CGPoint, instantly: Bool, infinitePlane: Bool) {
		DispatchQueue.main.async {
			let result = self.worldPositionFromScreenPosition(screenPos, in: sceneView, objectPos: object.simdPosition, infinitePlane: infinitePlane)
			
			guard let newPosition = result.position else {
				self.delegate?.virtualObjectManager(self, couldNotPlace: object)
				return
			}
			
			guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
				return
			}
			
			self.updateQueue.async {
				self.setPosition(for: object,
									  position: newPosition,
				                      instantly: instantly,
				                      filterPosition: !result.hitAPlane,
				                      cameraTransform: cameraTransform)
			}
		}
	}
	
    /// Set Position
    /// - parameter object: the object to place
    /// - parameter position: position
    /// - parameter instantly: whether implement instantly
    /// - parameter filterPostion: whether filter position
    /// - parameter cameraTransform: camera's transform matrix
	func setPosition(for object: VirtualObject, position: float3, instantly: Bool, filterPosition: Bool, cameraTransform: matrix_float4x4) {
		if instantly {
			setNewVirtualObjectPosition(object, to: position, cameraTransform: cameraTransform)
		} else {
			updateVirtualObjectPosition(object, to: position, filterPosition: filterPosition, cameraTransform: cameraTransform)
		}
	}
	
	private func setNewVirtualObjectPosition(_ object: VirtualObject, to pos: float3, cameraTransform: matrix_float4x4) {
		let cameraWorldPos = cameraTransform.translation
		var cameraToPosition = pos - cameraWorldPos
		
		// Limit the distance of the object from the camera to a maximum of 10 meters.
        if simd_length(cameraToPosition) > 10 {
            cameraToPosition = simd_normalize(cameraToPosition)
            cameraToPosition *= 10
        }

		object.simdPosition = cameraWorldPos + cameraToPosition
		object.recentVirtualObjectDistances.removeAll()
	}
	
	private func updateVirtualObjectPosition(_ object: VirtualObject, to pos: float3, filterPosition: Bool, cameraTransform: matrix_float4x4) {
		let cameraWorldPos = cameraTransform.translation
		var cameraToPosition = pos - cameraWorldPos
		
		// Limit the distance of the object from the camera to a maximum of 10 meters.
        if simd_length(cameraToPosition) > 10 {
            cameraToPosition = simd_normalize(cameraToPosition)
            cameraToPosition *= 10
        }

		// Compute the average distance of the object from the camera over the last ten
		// updates. If filterPosition is true, compute a new position for the object
		// with this average. Notice that the distance is applied to the vector from
		// the camera to the content, so it only affects the percieved distance of the
		// object - the averaging does _not_ make the content "lag".
		let hitTestResultDistance = simd_length(cameraToPosition)
		
		object.recentVirtualObjectDistances.append(hitTestResultDistance)
		object.recentVirtualObjectDistances.keepLast(10)
		
		if filterPosition, let averageDistance = object.recentVirtualObjectDistances.average {
			let averagedDistancePos = cameraWorldPos + simd_normalize(cameraToPosition) * averageDistance
			object.simdPosition = averagedDistancePos
		} else {
			object.simdPosition = cameraWorldPos + cameraToPosition
		}
	}
	
	func checkIfObjectShouldMoveOntoPlane(anchor: ARPlaneAnchor, planeAnchorNode: SCNNode) {
		for object in virtualObjects {
			// Get the object's position in the plane's coordinate system.
			let objectPos = planeAnchorNode.convertPosition(object.position, from: object.parent)
			
			if objectPos.y == 0 {
				return; // The object is already on the plane - nothing to do here.
			}
			
			// Add 10% tolerance to the corners of the plane.
			let tolerance: Float = 0.1
			
			let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
			let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
			let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
			let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance
			
            // The position of the object is within an acceptable range.
			if objectPos.x < minX || objectPos.x > maxX || objectPos.z < minZ || objectPos.z > maxZ {
				return
			}
			
			// Move the object onto the plane if it is near it (within 5 centimeters).
			let verticalAllowance: Float = 0.05
			let epsilon: Float = 0.001 // Do not bother updating if the different is less than a mm.
			let distanceToPlane = abs(objectPos.y)
			if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
				delegate?.virtualObjectManager(self, didMoveObjectOntoNearbyPlane: object)
				
                // Transition animation
				SCNTransaction.begin()
				SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
				SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
				object.position.y = anchor.transform.columns.3.y
				SCNTransaction.commit()
			}
		}
	}
	
    /// Return space information from matrix transformation
	func transform(for object: VirtualObject, cameraTransform: matrix_float4x4) -> (distance: Float, rotation: Int, scale: Float) {
		let cameraPos = cameraTransform.translation
		let vectorToCamera = cameraPos - object.simdPosition
		
		let distanceToUser = simd_length(vectorToCamera)
		
		var angleDegrees = Int((object.eulerAngles.y * 180) / .pi) % 360
		if angleDegrees < 0 {
			angleDegrees += 360
		}
		
		return (distanceToUser, angleDegrees, object.scale.x)
	}
	
    /// Screen position corresponds to world position
	func worldPositionFromScreenPosition(_ position: CGPoint,
	                                     in sceneView: ARSCNView,
	                                     objectPos: float3?,
	                                     infinitePlane: Bool = false) -> (position: float3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
		
//        let dragOnInfinitePlanesEnabled = UserDefaults.standard.bool(for: .dragOnInfinitePlanes)
        let dragOnInfinitePlanesEnabled = false
		
		// -------------------------------------------------------------------------------
		// 1. Always do a hit test against exisiting plane anchors first.
		//    (If any such anchors exist & only within their extents.)
		
		let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
		if let result = planeHitTestResults.first {
			
			let planeHitTestPosition = result.worldTransform.translation
			let planeAnchor = result.anchor
			
			// Return immediately - this is the best possible outcome.
			return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
		}
		
		// -------------------------------------------------------------------------------
		// 2. Collect more information about the environment by hit testing against
		//    the feature point cloud, but do not return the result yet.
		
		var featureHitTestPosition: float3?
		var highQualityFeatureHitTestResult = false
		
		let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
		
		if !highQualityfeatureHitTestResults.isEmpty {
			let result = highQualityfeatureHitTestResults[0]
			featureHitTestPosition = result.position
			highQualityFeatureHitTestResult = true
		}
		
		// -------------------------------------------------------------------------------
		// 3. If desired or necessary (no good feature hit test result): Hit test
		//    against an infinite, horizontal plane (ignoring the real world).
		
		if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
			
			if let pointOnPlane = objectPos {
				let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
				if pointOnInfinitePlane != nil {
					return (pointOnInfinitePlane, nil, true)
				}
			}
		}
		
		// -------------------------------------------------------------------------------
		// 4. If available, return the result of the hit test against high quality
		//    features if the hit tests against infinite planes were skipped or no
		//    infinite plane was hit.
		
		if highQualityFeatureHitTestResult {
			return (featureHitTestPosition, nil, false)
		}
		
		// -------------------------------------------------------------------------------
		// 5. As a last resort, perform a second, unfiltered hit test against features.
		//    If there are no features in the scene, the result returned here will be nil.
		
		let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
		if !unfilteredFeatureHitTestResults.isEmpty {
			let result = unfilteredFeatureHitTestResults[0]
			return (result.position, nil, false)
		}
		
		return (nil, nil, false)
	}
}

// MARK: - Delegate

protocol VirtualObjectManagerDelegate: class {
	func virtualObjectManager(_ manager: VirtualObjectManager, willLoad object: VirtualObject)
	func virtualObjectManager(_ manager: VirtualObjectManager, didLoad object: VirtualObject)
	func virtualObjectManager(_ manager: VirtualObjectManager, transformDidChangeFor object: VirtualObject)
	func virtualObjectManager(_ manager: VirtualObjectManager, didMoveObjectOntoNearbyPlane object: VirtualObject)
	func virtualObjectManager(_ manager: VirtualObjectManager, couldNotPlace object: VirtualObject)
}
// Optional protocol methods
extension VirtualObjectManagerDelegate {
    func virtualObjectManager(_ manager: VirtualObjectManager, transformDidChangeFor object: VirtualObject) {}
    func virtualObjectManager(_ manager: VirtualObjectManager, didMoveObjectOntoNearbyPlane object: VirtualObject) {}
}
