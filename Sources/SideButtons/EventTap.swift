//
//  EventTap.swift
//
//  Copyright (C) 2026 numunun
//  Derived from SensibleSideButtons, Copyright (C) 2018 Alexei Baboulevitch.
//  Licensed under the GNU General Public License, version 2 or later.
//

import CoreGraphics
import Foundation

/// M4/M5 마우스 버튼을 가로채서 스와이프 제스처로 바꾼다.
///
/// 마우스 버튼 번호: 0이 왼쪽, 1이 오른쪽, 2가 가운데, 3과 4가 사이드
/// 버튼 두 개다. macOS는 이 둘을 otherMouseDown/otherMouseUp으로 전달한
/// 다음 사실상 무시하는데, 그게 이 앱이 존재하는 이유다.
final class EventTap {

    /// 기본 배치에서 "뒤로" 사이드 버튼의 번호.
    private static let backButton: Int64 = 3
    /// 기본 배치에서 "앞으로" 사이드 버튼의 번호.
    private static let forwardButton: Int64 = 4

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // 입력 hot path에서 읽는 캐시된 설정값. Settings.swift 참고.
    private var triggerOnMouseDown: Bool
    private var swapButtons: Bool

    /// macOS가 탭을 중단시켜서 되살렸을 때 호출된다.
    var onTapRevived: (() -> Void)?

    var isRunning: Bool {
        guard let tap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }

    init(settings: Settings) {
        self.triggerOnMouseDown = settings.triggerOnMouseDown
        self.swapButtons = settings.swapButtons
    }

    func refresh(from settings: Settings) {
        triggerOnMouseDown = settings.triggerOnMouseDown
        swapButtons = settings.swapButtons
    }

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }

        let mask = (1 << CGEventType.otherMouseDown.rawValue)
                 | (1 << CGEventType.otherMouseUp.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: EventTap.callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            // 거의 항상 접근성 권한이 없다는 뜻이다.
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.runLoopSource = source
        return true
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        if let tap {
            CFMachPortInvalidate(tap)
        }
        tap = nil
        runLoopSource = nil
    }

    deinit {
        stop()
    }

    // MARK: - Hot path

    // CGEventTapCallBack은 순수 C 함수 포인터라서, 이 클로저는 아무것도
    // 캡처하면 안 된다. self는 userInfo 포인터를 통해 돌아온다.
    private static let callback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else { return Unmanaged.passUnretained(event) }
        let tap = Unmanaged<EventTap>.fromOpaque(userInfo).takeUnretainedValue()
        return tap.handle(type: type, event: event)
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // macOS는 반환이 너무 느린 탭이나 특정 사용자 입력이 발생한 탭을
        // 비활성화한다. 이 분기가 없으면 앱이 멀쩡히 돌다가 시스템 부하가
        // 심해진 뒤 조용히 먹통이 된다. 원본에서 가장 많이 보고된 버그다.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            onTapRevived?()
            return nil
        }

        let button = event.getIntegerValueField(.mouseEventButtonNumber)
        let backButton = swapButtons ? Self.forwardButton : Self.backButton
        let forwardButton = swapButtons ? Self.backButton : Self.forwardButton

        guard button == backButton || button == forwardButton else {
            return Unmanaged.passUnretained(event)
        }

        let isDown = (type == .otherMouseDown)
        if isDown == triggerOnMouseDown {
            Gesture.swipe(button == backButton ? .left : .right)
        }

        // down과 up을 둘 다 삼켜서 클릭이 아래 앱에 전달되지 않게 한다.
        // 한쪽만 통과시키면 앱이 버튼이 눌린 상태라고 영원히 착각한다.
        return nil
    }
}