//
//  SSBSwipe.h
//
//  Swift에 노출되는 최소한의 C 표면.
//  비공개 IOKit/HID 직렬화를 건드리는 코드는 전부 이 선 안쪽에 남는다.
//
//  Copyright (C) 2026 numunun
//  Derived from SensibleSideButtons, Copyright (C) 2018 Alexei Baboulevitch.
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version. See the LICENSE file at the root of this repository.
//

#ifndef SSB_SWIPE_H
#define SSB_SWIPE_H

#include <stdint.h>
#include <stdbool.h>

typedef enum {
    SSBSwipeDirectionUp    = 1,
    SSBSwipeDirectionDown  = 2,
    SSBSwipeDirectionLeft  = 4,
    SSBSwipeDirectionRight = 8,
} SSBSwipeDirection;

/// 지정한 방향으로 세 손가락 스와이프를 합성해서 시스템에 보낸다.
///
/// 이벤트를 연달아 두 개 보낸다. "제스처 시작" 단계와 "스와이프, 방향, 종료"
/// 단계. 실제 트랙패드 스와이프에서 멀티터치 드라이버가 내보내는 순서를
/// 그대로 흉내낸 것이고, 앱들이 이걸 스크롤이 아니라 내비게이션으로
/// 취급하는 이유가 여기에 있다.
///
/// 이벤트를 만들지 못하면 false를 반환한다. true는 보냈다는 뜻일 뿐,
/// 최상위 앱이 실제로 반응했는지는 알려주지 않는다.
bool ssb_post_swipe(SSBSwipeDirection direction);

#endif /* SSB_SWIPE_H */