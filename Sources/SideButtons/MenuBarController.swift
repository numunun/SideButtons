//
//  MenuBarController.swift
//
//  Copyright (C) 2026 numunun
//  Derived from SensibleSideButtons, Copyright (C) 2018 Alexei Baboulevitch.
//  Licensed under the GNU General Public License, version 2 or later.
//

import AppKit
import ServiceManagement

/// UI 전부. 스토리보드도 에셋 카탈로그도 없다. 이게 Command Line Tools만으로
/// 이 프로젝트를 빌드할 수 있는 이유다.
final class MenuBarController: NSObject, NSMenuDelegate {

    private let statusItem: NSStatusItem
    private let settings: Settings
    private let tap: EventTap

    private let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "e")
    private let mouseDownItem = NSMenuItem(title: "Trigger on Mouse Down", action: #selector(toggleMouseDown), keyEquivalent: "")
    private let swapItem = NSMenuItem(title: "Swap Buttons", action: #selector(toggleSwap), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
    private let accessibilityItem = NSMenuItem(title: "Grant Accessibility Access…", action: #selector(openAccessibility), keyEquivalent: "")

    init(settings: Settings, tap: EventTap) {
        self.settings = settings
        self.tap = tap
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        buildMenu()
        refresh()
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self

        for item in [enabledItem, mouseDownItem, swapItem] {
            item.target = self
            menu.addItem(item)
        }
        menu.addItem(.separator())

        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())

        accessibilityItem.target = self
        menu.addItem(accessibilityItem)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - State

    func refresh() {
        let trusted = Permissions.isTrusted(prompting: false)
        let running = tap.isRunning

        enabledItem.state = running ? .on : .off
        mouseDownItem.state = settings.triggerOnMouseDown ? .on : .off
        swapItem.state = settings.swapButtons ? .on : .off

        for item in [enabledItem, mouseDownItem, swapItem] {
            item.isEnabled = trusted
        }
        accessibilityItem.isHidden = trusted

        if #available(macOS 13.0, *) {
            loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        }

        // SF Symbol을 쓰면 에셋 카탈로그가 필요 없고, 따라서 actool도
        // Xcode도 필요 없다.
        //
        // NSImage(systemSymbolName:)은 이름이 틀리면 예외를 던지지 않고
        // 조용히 nil을 반환한다. 그러면 이미지도 제목도 없는 버튼이 되어
        // 폭이 0으로 줄고, 메뉴 바에서 아이콘이 사라진 것처럼 보인다.
        // 그래서 폴백을 두 겹으로 깐다.
        let symbol = running ? "arrow.left.arrow.right" : "arrow.left.and.right.square"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Side Buttons")
            ?? NSImage(systemSymbolName: "arrow.left.arrow.right", accessibilityDescription: "Side Buttons")
        image?.isTemplate = true
        statusItem.button?.image = image

        // 심볼을 하나도 못 만든 최악의 경우에도 클릭할 무언가는 남긴다.
        if image == nil {
            statusItem.button?.title = running ? "⇄" : "⇹"
        } else {
            statusItem.button?.title = ""
        }

        // 활성/비활성을 투명도로도 구분한다. 흑백 템플릿 이미지에서는
        // 이쪽이 모양 차이보다 눈에 잘 들어온다.
        statusItem.button?.alphaValue = running ? 1.0 : 0.45
        statusItem.button?.toolTip = trusted
            ? nil
            : "접근성 권한이 필요합니다."
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        if tap.isRunning {
            tap.stop()
            settings.setWasEnabled(false)
        } else {
            let ok = tap.start()
            settings.setWasEnabled(ok)
            if !ok {
                _ = Permissions.isTrusted(prompting: true)
            }
        }
        refresh()
    }

    @objc private func toggleMouseDown() {
        settings.toggleTriggerOnMouseDown()
        refresh()
    }

    @objc private func toggleSwap() {
        settings.toggleSwapButtons()
        refresh()
    }

    @objc private func toggleLoginItem() {
        guard #available(macOS 13.0, *) else { return }
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            // 가장 흔한 원인: 아직 서명된 .app 번들이 아님.
            NSLog("Login item toggle failed: \(error.localizedDescription)")
        }
        refresh()
    }

    @objc private func openAccessibility() {
        Permissions.openAccessibilitySettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}