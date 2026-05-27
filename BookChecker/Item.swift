//
//  Item.swift
//  BookChecker
//
//  Created by nscabezon on 27/05/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
