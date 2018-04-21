/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Configures the scene.
*/

import Foundation
import ARKit

// MARK: - AR scene view extensions

extension ARSCNView {
	
	func setup() {
		antialiasingMode = .multisampling4X
		automaticallyUpdatesLighting = false
        autoenablesDefaultLighting = false
		
		preferredFramesPerSecond = 60
        contentScaleFactor = 1.3
		
        // Adjust camera's parameter
		if let camera = pointOfView?.camera {
			camera.wantsHDR = true
			camera.wantsExposureAdaptation = true
			camera.exposureOffset = 1   // Determine screen's brightness
			camera.minimumExposure = -1
			camera.maximumExposure = 3
            camera.motionBlurIntensity = 1
		}
	}
}

// MARK: - Scene extensions

extension SCNScene {
	func enableEnvironmentMapWithIntensity(_ intensity: CGFloat, queue: DispatchQueue) {
		queue.async {
			if self.lightingEnvironment.contents == nil {
				if let environmentMap = UIImage(named: "environment_blur.exr") {
					self.lightingEnvironment.contents = environmentMap
				}
//                if let environment = UIImage(named: "environment.jpg") {
//                    self.background.contents = environment
//                }
			}
			self.lightingEnvironment.intensity = intensity
		}
	}
}
