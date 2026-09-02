//
//  main.swift (SwipeTest)
//
//  스와이프 하나 쏘고 종료한다. 이게 카나리아 역할이다. 미래의 macOS가
//  비공개 제스처 포맷을 깨면 여기서 제일 먼저 깨지고, 이벤트 탭도
//  메뉴 바도 권한 로직도 끼어있지 않으니 원인이 명확하다.
//
//  사용법:  swift run SwipeTest left
//           swift run SwipeTest right
//
//  Copyright (C) 2026 numunun
//  Derived from SensibleSideButtons, Copyright (C) 2018 Alexei Baboulevitch.
//  Licensed under the GNU General Public License, version 2 or later.
//

import CTouchEvents
import Foundation

let argument = CommandLine.arguments.dropFirst().first ?? "left"

let direction: SSBSwipeDirection
switch argument.lowercased() {
case "left", "back":
    direction = SSBSwipeDirectionLeft
case "right", "forward":
    direction = SSBSwipeDirectionRight
default:
    FileHandle.standardError.write(Data("usage: SwipeTest [left|right]\n".utf8))
    exit(1)
}

// 히스토리가 있는 창(브라우저 등)으로 포커스를 옮길 시간을 준다.
print("3초 뒤 \(argument) 스와이프를 보냅니다. 뒤로/앞으로 갈 수 있는 창을 클릭하세요.")
Thread.sleep(forTimeInterval: 3)

let posted = ssb_post_swipe(direction)
print(posted ? "이벤트를 보냈습니다." : "이벤트 생성에 실패했습니다.")

// 이벤트는 비동기로 소비된다. 바로 종료하면 유실될 수 있다.
Thread.sleep(forTimeInterval: 0.1)