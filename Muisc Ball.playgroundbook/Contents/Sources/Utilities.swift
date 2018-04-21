//
//  Utilities.swift
//
//  Created by Daniel on 2018/3/7.
//  Copyright © 2018年 com.danielios. All rights reserved.
//

import SceneKit
import UIKit

//func createPlaneNode(center: vector_float3, extent: vector_float3) -> SCNNode {
//    let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
//
//    let planeMaterial = SCNMaterial()
//    planeMaterial.diffuse.contents = UIColor.blue.withAlphaComponent(0.4)
//    plane.materials = [planeMaterial]
//    let planeNode = SCNNode(geometry: plane)
//    planeNode.position = SCNVector3Make(center.x, 0, center.z)
//    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
//
//    return planeNode
//}
//
//func updatePlaneNode(_ node: SCNNode, center: vector_float3, extent: vector_float3) {
//    let geometry = node.geometry as! SCNPlane
//
//    geometry.width = CGFloat(extent.x)
//    geometry.height = CGFloat(extent.z)
//    node.position = SCNVector3Make(center.x, 0, center.z)
//}

// MARK: - UIButton extensions
extension UIView {
    func rotate(degree: Double) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnimation.toValue = degree
        rotateAnimation.duration = 1
        rotateAnimation.isCumulative = true
        layer.add(rotateAnimation, forKey: "rotate")
    }
    
    func stopRotate() {
        layer.removeAnimation(forKey: "rotate")
    }
    
    func moveIn(distance: CGFloat) -> CABasicAnimation {
        let moveAnimation = CABasicAnimation(keyPath: "layer.position.y")
        moveAnimation.toValue = self.bounds.height + distance
        moveAnimation.duration = 0.3
        moveAnimation.timingFunction = CAMediaTimingFunction(name: "kCAMediaTimingFunctionEaseOut")
        layer.add(moveAnimation, forKey: "moveIn")
        return moveAnimation
    }
    
    func moveOut(distance: CGFloat) -> CABasicAnimation {
        let moveAnimation = CABasicAnimation(keyPath: "layer.position.y")
        moveAnimation.toValue = -(self.bounds.height + distance)
        moveAnimation.duration = 0.3
        moveAnimation.timingFunction = CAMediaTimingFunction(name: "kCAMediaTimingFunctionEaseOut")
        layer.add(moveAnimation, forKey: "moveOut")
        return moveAnimation
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    
    init(_ size: CGSize) {
        self.x = size.width
        self.y = size.height
    }
    
    init(_ vector: SCNVector3) {
        self.x = CGFloat(vector.x)
        self.y = CGFloat(vector.y)
    }
    
    func distanceTo(_ point: CGPoint) -> CGFloat {
        return (self - point).length()
    }
    
    func length() -> CGFloat {
        return sqrt(self.x * self.x + self.y * self.y)
    }
    
    func midpoint(_ point: CGPoint) -> CGPoint {
        return (self + point) / 2
    }
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }
    
    static func -= (left: inout CGPoint, right: CGPoint) {
        left = left - right
    }
    
    static func / (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x / right, y: left.y / right)
    }
    
    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }
    
    static func /= (left: inout CGPoint, right: CGFloat) {
        left = left / right
    }
    
    static func *= (left: inout CGPoint, right: CGFloat) {
        left = left * right
    }
}

// MARK: - CGSize extensions

extension CGSize {
    init(_ point: CGPoint) {
        self.width = point.x
        self.height = point.y
    }
    
    static func + (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width + right.width, height: left.height + right.height)
    }
    
    static func - (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width - right.width, height: left.height - right.height)
    }
    
    static func += (left: inout CGSize, right: CGSize) {
        left = left + right
    }
    
    static func -= (left: inout CGSize, right: CGSize) {
        left = left - right
    }
    
    static func / (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width / right, height: left.height / right)
    }
    
    static func * (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width * right, height: left.height * right)
    }
    
    static func /= (left: inout CGSize, right: CGFloat) {
        left = left / right
    }
    
    static func *= (left: inout CGSize, right: CGFloat) {
        left = left * right
    }
}

// MARK: - CGRect extensions

extension CGRect {
    /// Midpoint coordinates
    var mid: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

// MARK: - SCNNode extension

extension SCNNode {
    
    func setUniformScale(_ scale: Float) {
        self.simdScale = float3(scale, scale, scale)
    }
    /// Adjust the rendering order
    func renderOnTop(_ enable: Bool) {
        self.renderingOrder = enable ? 2 : 0
        if let geom = self.geometry {
            for material in geom.materials {
                material.readsFromDepthBuffer = enable ? false : true
            }
        }
        for child in self.childNodes {
            child.renderOnTop(enable)
        }
    }
}

// MARK: - float4x4 extensions

extension float4x4 {
    /// Treats matrix as a (right-hand column-major convention) transform matrix
    /// and factors out the translation component of the transform.
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

// MARK: - SCNVector3 extensions

extension SCNVector3 {
    
    init(_ vec: vector_float3) {
        self.x = vec.x
        self.y = vec.y
        self.z = vec.z
    }
    
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    
    mutating func setLength(_ length: Float) {
        self.normalize()
        self *= length
    }
    
    mutating func setMaximumLength(_ maxLength: Float) {
        if self.length() <= maxLength {
            return
        } else {
            self.normalize()
            self *= maxLength
        }
    }
    
    mutating func normalize() {
        self = self.normalized()
    }
    
    func normalized() -> SCNVector3 {
        if self.length() == 0 {
            return self
        }
        
        return self / self.length()
    }
    
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    func dot(_ vec: SCNVector3) -> Float {
        return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
    }
    
    func cross(_ vec: SCNVector3) -> SCNVector3 {
        return SCNVector3(self.y * vec.z - self.z * vec.y, self.z * vec.x - self.x * vec.z, self.x * vec.y - self.y * vec.x)
    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func *= (left: inout SCNVector3, right: Float) {
    left = left * right
}

// MARK: - Collection extensions
extension Array where Iterator.Element == Float {
    /// The average of floating-point arrays
    var average: Float? {
        guard !self.isEmpty else {
            return nil
        }
        
        let sum = self.reduce(Float(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension Array where Iterator.Element == float3 {
    /// The average of three-point floating-point vector
    var average: float3? {
        guard !self.isEmpty else {
            return nil
        }
        
        let sum = self.reduce(float3(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension RangeReplaceableCollection where IndexDistance == Int {
    /// Keep the number of elements in the collection
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

/// Intersection of rays and horizontal plane
func rayIntersectionWithHorizontalPlane(rayOrigin: float3, direction: float3, planeY: Float) -> float3? {
    
    let direction = simd_normalize(direction)
    
    // Special case handling: Check if the ray is horizontal as well.
    if direction.y == 0 {
        if rayOrigin.y == planeY {
            // The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
            // Therefore we simply return the ray origin.
            return rayOrigin
        } else {
            // The ray is parallel to the plane and never intersects.
            return nil
        }
    }
    
    // The distance from the ray's origin to the intersection point on the plane is:
    //   (pointOnPlane - rayOrigin) dot planeNormal
    //  --------------------------------------------
    //          direction dot planeNormal
    
    // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
    let dist = (planeY - rayOrigin.y) / direction.y
    
    // Do not return intersections behind the ray's origin.
    if dist < 0 {
        return nil
    }
    
    // Return the intersection point.
    return rayOrigin + (direction * dist)
}
