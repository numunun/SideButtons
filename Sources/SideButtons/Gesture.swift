//
//  Gesture.swift
//
//  Copyright (C) 2026 numunun
//  Derived from SensibleSideButtons, Copyright (C) 2018 Alexei Baboulevitch.
//  Licensed under the GNU General Public License, version 2 or later.
//

import CTouchEvents

enum SwipeDirection {
    case left
    case right

    var raw: SSBSwipeDirection {
        switch self {
        case .left:  return SSBSwipeDirectionLeft
        case .right: return SSBSwipeDirectionRight
        }
    }
}

enum Gesture {
    @discardableResult
    static func swipe(_ direction: SwipeDirection) -> Bool {
        ssb_post_swipe(direction.raw)
    }
}