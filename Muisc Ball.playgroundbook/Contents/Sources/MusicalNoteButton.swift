//
//  MusicalNoteButton.swift
//
//  Created by daniel on 2018/3/20.
//  Copyright © 2018年 com.danielios. All rights reserved.
//

import UIKit

struct MusicalNoteDefinition: Codable {
    let buttonName: String?
    let thumbImageName: String
    let textureImageName: String
    let audioFileName: String
    
    init(buttonName: String?, thumbImageName: String, textureImageName: String, audioFileName: String) {
        self.buttonName = buttonName
        self.thumbImageName = thumbImageName
        self.textureImageName = textureImageName
        self.audioFileName = audioFileName
    }
}

class MusicalNoteButton: UIButton {
    
    let sideLength: CGFloat = 44
    let definition: MusicalNoteDefinition
    
    init(definition: MusicalNoteDefinition) {
        self.definition = definition
        super.init(frame: CGRect(x: 0, y: 0, width: sideLength, height: sideLength))
        
        self.setTitle(definition.buttonName, for: .normal)
        self.setBackgroundImage(UIImage(named: definition.thumbImageName), for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

