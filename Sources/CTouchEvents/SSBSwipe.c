//
//  SSBSwipe.c
//
//  Copyright (C) 2026 numunun
//  Derived from SensibleSideButtons, Copyright (C) 2018 Alexei Baboulevitch.
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version. See the LICENSE file at the root of this repository.
//

#include "SSBSwipe.h"
#include "TouchEvents.h"

#include <CoreFoundation/CoreFoundation.h>

// 원본 구현이 쓰던 phase 값: 1 == 시작, 4 == 종료.
static const int32_t kPhaseBegan = 1;
static const int32_t kPhaseEnded = 4;

static CFDictionaryRef ssb_create_info(int32_t phase, const int32_t *direction) {
    CFMutableDictionaryRef info = CFDictionaryCreateMutable(
        kCFAllocatorDefault, 3,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);
    if (!info) { return NULL; }

    int32_t subtype = kTLInfoSubtypeSwipe;
    CFNumberRef subtypeNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &subtype);
    CFDictionarySetValue(info, kTLInfoKeyGestureSubtype, subtypeNum);
    CFRelease(subtypeNum);

    CFNumberRef phaseNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &phase);
    CFDictionarySetValue(info, kTLInfoKeyGesturePhase, phaseNum);
    CFRelease(phaseNum);

    if (direction) {
        CFNumberRef dirNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, direction);
        CFDictionarySetValue(info, kTLInfoKeySwipeDirection, dirNum);
        CFRelease(dirNum);
    }

    return info;
}

bool ssb_post_swipe(SSBSwipeDirection direction) {
    int32_t dir = (int32_t)direction;

    CFArrayRef noTouches = CFArrayCreate(kCFAllocatorDefault, NULL, 0, &kCFTypeArrayCallBacks);
    CFDictionaryRef beganInfo = ssb_create_info(kPhaseBegan, NULL);
    CFDictionaryRef endedInfo = ssb_create_info(kPhaseEnded, &dir);

    bool ok = false;

    if (noTouches && beganInfo && endedInfo) {
        CGEventRef began = tl_CGEventCreateFromGesture(beganInfo, noTouches);
        CGEventRef ended = tl_CGEventCreateFromGesture(endedInfo, noTouches);

        if (began && ended) {
            CGEventPost(kCGHIDEventTap, began);
            CGEventPost(kCGHIDEventTap, ended);
            ok = true;
        }

        if (began) { CFRelease(began); }
        if (ended) { CFRelease(ended); }
    }

    if (noTouches)  { CFRelease(noTouches); }
    if (beganInfo)  { CFRelease(beganInfo); }
    if (endedInfo)  { CFRelease(endedInfo); }

    return ok;
}