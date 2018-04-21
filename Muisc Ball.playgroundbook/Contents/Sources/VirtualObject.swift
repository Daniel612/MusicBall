/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Wrapper SceneKit node for virtual objects placed into the AR scene.
*/

import Foundation
import SceneKit
import ARKit

class VirtualObject: SCNNode {
    
    static let defaultColor = UIColor.lightGray
    
    var isModelLoaded: Bool = false
    
    var color: UIColor = VirtualObject.defaultColor
    
    var texture: UIImage? {
        didSet {
            updateMaterials()
        }
    }
    
    var audio: SCNAudioSource?
    
    // Use average of recent virtual object distances to avoid rapid changes in object scale.
    var recentVirtualObjectDistances = [Float]()
    
    override init() {
        super.init()
    }
    
    convenience init(texture: UIImage, audio: SCNAudioSource) {
        self.init()
        self.texture = texture
        self.audio = audio
        self.audio?.isPositional = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadModel() {
        var node = SCNNode()
        var shadow = SCNNode()
        node = VirtualObject.shphere()
        shadow = VirtualObject.shadowPlane()
        // Place node coordinates from center to bottom
        node.pivot = SCNMatrix4MakeTranslation(0, -0.05, 0)
        addChildNode(node)
        addChildNode(shadow)
        isModelLoaded = true
        updateMaterials()
    }
    
    private func updateMaterials() {
        
        guard
            let node = childNodes.first,
            let geometry = node.geometry
            else { return }
        
        // Set the color of each face.
        for material in geometry.materials {
            material.diffuse.contents = color
        }
        
        guard let image = texture else { return }
        
        // Set the image.
        // Wrap the image around the sphere.
        geometry.firstMaterial?.diffuse.contents = image
    }
    
    private static func shphere() -> SCNNode {
        let geometry = SCNSphere(radius: 0.05)
        
        geometry.isGeodesic = true
        geometry.segmentCount = 96
        
        let material = geometry.firstMaterial
        
        // Declare that you intend to work in PBR shading mode
        material?.lightingModel = SCNMaterial.LightingModel.physicallyBased
        
        material?.diffuse.contents = defaultColor
        material?.roughness.contents = UIImage(named: "scuffed-plastic-roughness.png")
        material?.metalness.contents = UIImage(named: "scuffed-plastic-metal.png")
        material?.normal.contents = UIImage(named: "scuffed-plastic-normal.png")
        return SCNNode(geometry: geometry)
    }
    
    private static func shadowPlane() -> SCNNode {
        let geometry = SCNPlane(width: 0.1, height: 0.1)
        geometry.firstMaterial?.diffuse.contents = UIImage(named: "shadow.png")
        let shadowPlane = SCNNode(geometry: geometry)
        shadowPlane.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        return shadowPlane
    }
}

extension VirtualObject {
    
    static func isNodePartOfVirtualObject(_ node: SCNNode) -> VirtualObject? {
        // If it is virtual object, just return
        if let virtualObjectRoot = node as? VirtualObject {
            return virtualObjectRoot
        }
        // if parent's node is not null
        if node.parent != nil {
            return isNodePartOfVirtualObject(node.parent!)
        }
        
        return nil
    }
    
}
