//
//  DemoItem.swift
//  PagenatedView
//
//  Created by YuHan Hsiao on 2020/4/19.
//  Copyright © 2020 Hsiao, Wayne. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class DemoItem: NSObject, Identifiable {
    
    var display: String
    var id = UUID()
    var action: () -> Void
    
    init(display: String, _ action: @escaping () -> Void) {
        self.display = display
        self.action = action
    }
}
