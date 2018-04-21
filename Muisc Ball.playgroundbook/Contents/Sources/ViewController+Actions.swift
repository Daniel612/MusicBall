//
//  ViewController+Actions.swift
//  Button trigger method
//
//  Created by daniel on 2018/3/16.
//  Copyright © 2018年 com.danielios. All rights reserved.
//

import UIKit
import SceneKit

extension ViewController {
    
    @IBAction func restartExperience(_ sender: Any) {
        guard restartExperienceButtonIsEnabled, !isLoadingObject else { return }
        
        DispatchQueue.main.async {
            
            self.restartExperienceButtonIsEnabled = false
            
            self.restartExperienceButton.rotate(degree: .pi * 2)
            
            self.textManager.cancelAllScheduledMessages()
            self.textManager.dismissPresentedAlert()
            self.textManager.showMessage("STARTING A NEW SESSION")
            
            self.virtualObjectManager.removeAllVirtualObjects()
            self.focusSquare?.isHidden = true
            
            self.resetTracking()
            
            // Show the focus square after a short delay to ensure all plane anchors have been deleted.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.setupFocusSquare()
                if !self.isMaking {
                    self.toggleMode(self.toggleModeButton)
                }
            })
            
            // Disable Restart button for a while in order to give the session enough time to restart.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                self.restartExperienceButtonIsEnabled = true
            })
            
            
        }
    }
    
    @IBAction func toggleMode(_ sender: Any) {
        if isMaking {
            self.notesStackView.isHidden = true
            self.toggleModeButton.setImage(UIImage(named: "music"), for: .normal)
            self.textManager.showMessage("Close to the balls to play music")
        } else {
            self.notesStackView.isHidden = false
            self.toggleModeButton.setImage(UIImage(named: "down"), for: .normal)
            self.textManager.showMessage("Tap note buttons to place the balls")
        }
        isMaking = !isMaking
    }
    
    // MARK: - Musical note buttons
    
    @objc func chooseNote(_ sender: Any) {
        // Abort if we are about to load another object to avoid concurrent modifications of the scene.
        if isLoadingObject { return }
        
        guard let button = sender as? MusicalNoteButton else {
            return
        }
        
        let borderWidth: CGFloat = 4.0
        
        if lastChoseNoteButton != nil {
            lastChoseNoteButton?.frame.insetBy(dx: borderWidth, dy: borderWidth)
            lastChoseNoteButton?.layer.borderWidth = 0
        }
        
        button.frame.insetBy(dx: -borderWidth, dy: -borderWidth)
        button.layer.borderWidth = borderWidth
        button.layer.borderColor = UIColor.white.cgColor
        lastChoseNoteButton = button
        
        // Create music ball
        
        guard let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }
        
        let texture = UIImage(named: button.definition.textureImageName)!
        let audio = SCNAudioSource(named: button.definition.audioFileName)!
        let object = VirtualObject(texture: texture, audio: audio)
        let position = focusSquare?.lastPosition ?? float3(0)
        
        // Before animation position
        let prePosition = float3(position.x, position.y + 0.05, position.z)
        
        virtualObjectManager.loadVirtualObject(object, to: prePosition, cameraTransform: cameraTransform)
        if object.parent == nil {
            serialQueue.async {
                self.sceneView.scene.rootNode.addChildNode(object)
                self.virtualObjectManager.showVirtualObject(object, from: 0.3, to: 1)
            }
        }
    }
}
