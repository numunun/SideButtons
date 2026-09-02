// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SideButtons",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        // 비공개 API 계층. SensibleSideButtons에서 그대로 가져왔고,
        // 그쪽은 다시 Calf Trail의 TouchSynthesis에서 가져온 코드다.
        // 여기에 얇은 shim을 하나 붙여서 Swift가 CoreFoundation 상수나
        // 손으로 짠 바이너리 직렬화를 건드릴 일이 없게 만든다.
        .target(
            name: "CTouchEvents",
            exclude: ["LICENSE-CalfTrail"],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("IOKit"),
            ]
        ),

        // 메뉴 바 앱 본체.
        .executableTarget(
            name: "SideButtons",
            dependencies: ["CTouchEvents"]
        ),

        // 단독 실행 테스트용: `swift run SwipeTest left`
        // 새 macOS 버전에서 제일 먼저 이걸 돌려본다. 제스처가 죽으면
        // 여기서도 죽는데, 중간에 낀 게 아무것도 없어서 원인이 명확하다.
        .executableTarget(
            name: "SwipeTest",
            dependencies: ["CTouchEvents"]
        ),
    ]
)