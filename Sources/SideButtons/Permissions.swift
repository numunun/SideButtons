//
//  Permissions.swift
//
//  Copyright (C) 2026 numunun
//  Licensed under the GNU General Public License, version 2 or later.
//

import AppKit
import ApplicationServices

enum Permissions {

    /// 이 프로세스가 전역 입력 이벤트를 관찰하고 보낼 수 있는지 여부.
    ///
    /// - Parameter prompting: true면 권한이 없을 때 macOS가 "이 컴퓨터를
    ///   제어하도록 허용하시겠습니까" 알림을 띄운다. 사용자의 행동에 대한
    ///   응답으로만 true를 넘겨야 한다. 타이머로 호출하면 알림이 무한히 뜬다.
    static func isTrusted(prompting: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompting]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// 시스템 설정의 손쉬운 사용 창을 바로 연다.
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}