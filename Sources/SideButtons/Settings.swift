//
//  Settings.swift
//
//  Copyright (C) 2026 numunun
//  Licensed under the GNU General Public License, version 2 or later.
//

import Foundation

/// 저장되는 설정값.
///
/// 이벤트 탭 콜백은 사이드 버튼을 누를 때마다 triggerOnMouseDown과
/// swapButtons를 읽는다. 거기서 UserDefaults를 조회하면 안 된다 -- 탭
/// 콜백은 입력 경로 위에서 돌고, 오래 걸리면 macOS가 탭을 아예 꺼버린다.
/// 그래서 값을 평범한 저장 프로퍼티에 복사해두고, 사용자가 실제로 토글할
/// 때만 디스크에 기록한다.
final class Settings {
    private enum Key {
        static let wasEnabled = "SBFWasEnabled"
        static let mouseDown = "SBFMouseDown"
        static let swapButtons = "SBFSwapButtons"
    }

    private let defaults: UserDefaults

    private(set) var wasEnabled: Bool
    private(set) var triggerOnMouseDown: Bool
    private(set) var swapButtons: Bool

    /// 값이 바뀔 때마다 호출된다. 탭이 캐시된 복사본을 갱신하는 용도.
    var onChange: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.wasEnabled: true,
            Key.mouseDown: true,
            Key.swapButtons: false,
        ])
        self.wasEnabled = defaults.bool(forKey: Key.wasEnabled)
        self.triggerOnMouseDown = defaults.bool(forKey: Key.mouseDown)
        self.swapButtons = defaults.bool(forKey: Key.swapButtons)
    }

    func setWasEnabled(_ value: Bool) {
        wasEnabled = value
        defaults.set(value, forKey: Key.wasEnabled)
        onChange?()
    }

    func toggleTriggerOnMouseDown() {
        triggerOnMouseDown.toggle()
        defaults.set(triggerOnMouseDown, forKey: Key.mouseDown)
        onChange?()
    }

    func toggleSwapButtons() {
        swapButtons.toggle()
        defaults.set(swapButtons, forKey: Key.swapButtons)
        onChange?()
    }
}