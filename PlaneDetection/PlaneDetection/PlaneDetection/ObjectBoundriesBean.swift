//
//  File.swift
//  PlaneDetection
//
//  Created by Behram  Buhariwala on 6/11/19.
//  Copyright © 2019 Behram  Buhariwala. All rights reserved.
//

import Foundation

class ObjectBoundaries {
    var maxX: Float
    var maxY: Float
    var maxZ: Float
    init(maxX: Float, maxY: Float, maxZ: Float) {
        self.maxX = maxX
        self.maxY = maxY
        self.maxZ = maxZ
    }
    
    func getMaxX() -> Float {
        return self.maxX
    }
    
    func getMaxY() -> Float {
        return self.maxY
    }
    
    func getMaxZ() -> Float {
        return self.maxZ
    }
}
