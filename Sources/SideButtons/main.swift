//
//  main.swift
//
//  Copyright (C) 2026 numunun
//  Derived from SensibleSideButtons, Copyright (C) 2018 Alexei Baboulevitch.
//  Licensed under the GNU General Public License, version 2 or later.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settings: Settings!
    private var tap: EventTap!
    private var menu: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings = Settings()
        tap = EventTap(settings: settings)
        settings.onChange = { [weak self] in
            guard let self else { return }
            self.tap.refresh(from: self.settings)
        }

        menu = MenuBarController(settings: settings, tap: tap)
        tap.onTapRevived = { [weak self] in
            NSLog("시스템이 이벤트 탭을 껐습니다. 다시 켰습니다.")
            self?.menu.refresh()
        }

        // 첫 실행 시 권한이 실제로 필요할 때만 알림을 띄운다.
        if !Permissions.isTrusted(prompting: true) {
            menu.refresh()
            return
        }

        if settings.wasEnabled {
            let ok = tap.start()
            settings.setWasEnabled(ok)
        }
        menu.refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        tap?.stop()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// accessory: Dock 아이콘도 상단 메뉴도 없음. Info.plist의 LSUIElement와
// 같은 효과이고, 여기서도 설정해두면 `swift run`이 번들과 똑같이 동작한다.
app.setActivationPolicy(.accessory)
app.run()