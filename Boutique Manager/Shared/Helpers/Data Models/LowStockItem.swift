//
//  LowStockItem.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//


//
//  LowStockItem.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import Foundation

struct LowStockItem {
    let name: String
    let category: String
    let remaining: Int
    let threshold: Int

    var fillRatio: CGFloat {
        CGFloat(remaining) / CGFloat(threshold)
    }
}