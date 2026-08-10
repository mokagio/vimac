//
//  Log.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 11/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Foundation
import os

private let subsystem = Bundle.main.bundleIdentifier ?? "vimac"

struct Log {
    static let accessibility = OSLog(subsystem: subsystem, category: "accessiblity")
    static let drawing = OSLog(subsystem: subsystem, category: "drawing")
}
