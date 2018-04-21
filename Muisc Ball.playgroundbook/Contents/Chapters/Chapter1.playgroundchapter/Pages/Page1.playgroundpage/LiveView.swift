//
//  LiveView.swift
//
//  Copyright © 2018年 com.danielios. All rights reserved.
//

import PlaygroundSupport
import UIKit

let page = PlaygroundPage.current
let viewController = ViewController.makeFromStoryboard()
page.liveView = viewController
