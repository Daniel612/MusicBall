//
//  ViewController+ObjectSelection.swift
//  Update the UI when choosing object
//
//  Created by daniel on 2018/3/18.
//  Copyright © 2018年 com.danielios. All rights reserved.
//

import UIKit
import SceneKit

extension ViewController: VirtualObjectManagerDelegate {
    
    // MARK: - VirtualObjectManager delegate callbacks (update the ui)
    
    func virtualObjectManager(_ manager: VirtualObjectManager, willLoad object: VirtualObject) {
        DispatchQueue.main.async {
            // Show progress indicator
            self.spinner = UIActivityIndicatorView()
            self.spinner!.center = self.toggleModeButton.center
            self.spinner!.bounds.size = CGSize(width: self.toggleModeButton.bounds.width - 5, height: self.toggleModeButton.bounds.height - 5)
            self.toggleModeButton.setImage(#imageLiteral(resourceName: "loading"), for: [])
            self.sceneView.addSubview(self.spinner!)
            self.spinner!.startAnimating()
            
            self.isLoadingObject = true
        }
    }
    
    func virtualObjectManager(_ manager: VirtualObjectManager, didLoad object: VirtualObject) {
        DispatchQueue.main.async {
            self.isLoadingObject = false
            
            // Remove progress indicator
            self.spinner?.removeFromSuperview()
            self.toggleModeButton.setImage(#imageLiteral(resourceName: "down"), for: [])
        }
    }
    
    func virtualObjectManager(_ manager: VirtualObjectManager, couldNotPlace object: VirtualObject) {
        textManager.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
    }
    
}
