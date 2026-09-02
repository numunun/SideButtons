#!/bin/bash
#
# SwiftPM 빌드 결과물로 SideButtons.app을 조립한다.
# Xcode Command Line Tools만 있으면 된다.
#
#   ./scripts/bundle.sh                                  # 빌드만
#   ./scripts/bundle.sh --install                        # 빌드 후 /Applications에 설치
#   ./scripts/bundle.sh --identity "SideButtons Dev"     # 서명 신원 지정
#   ./scripts/bundle.sh --identity "SideButtons Dev" --install
#
# 번들은 .build/ 안에 만든다. 프로젝트 폴더에 .app을 남기면 /Applications의
# 사본과 번들 ID가 겹쳐서 접근성 목록에 두 줄이 뜨고, 어느 쪽이 실행될지
# 보장할 수 없게 된다.
#
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="SideButtons"
IDENTITY="-"
INSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --identity)
      if [ $# -lt 2 ]; then echo "--identity 에 값이 필요합니다" >&2; exit 1; fi
      IDENTITY="$2"; shift 2 ;;
    --install)
      INSTALL=1; shift ;;
    *)
      echo "알 수 없는 인자: $1" >&2
      echo "사용법: $0 [--identity <이름>] [--install]" >&2
      exit 1 ;;
  esac
done

STAGE=".build/bundle"
BUNDLE="${STAGE}/${APP_NAME}.app"
INSTALLED="/Applications/${APP_NAME}.app"

echo "==> 릴리스 바이너리 빌드"
swift build -c release --product "${APP_NAME}"
BINARY="$(swift build -c release --product "${APP_NAME}" --show-bin-path)/${APP_NAME}"

echo "==> ${BUNDLE} 조립"
rm -rf "${BUNDLE}"
mkdir -p "${BUNDLE}/Contents/MacOS" "${BUNDLE}/Contents/Resources"
cp "${BINARY}" "${BUNDLE}/Contents/MacOS/${APP_NAME}"
cp Resources/Info.plist "${BUNDLE}/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
  cp Resources/AppIcon.icns "${BUNDLE}/Contents/Resources/"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" \
    "${BUNDLE}/Contents/Info.plist" 2>/dev/null || true
fi

echo "==> 서명 신원: ${IDENTITY}"
codesign --force --options runtime --timestamp=none \
  --sign "${IDENTITY}" "${BUNDLE}"
codesign --verify --strict --verbose=2 "${BUNDLE}"

echo "==> 아키텍처:"
lipo -archs "${BUNDLE}/Contents/MacOS/${APP_NAME}"

if [ "${INSTALL}" -eq 1 ]; then
  echo "==> 실행 중인 인스턴스 종료"
  pkill -f "${APP_NAME}" 2>/dev/null || true
  sleep 1

  echo "==> ${INSTALLED} 에 설치"
  rm -rf "${INSTALLED}"
  # cp 대신 ditto: 확장 속성과 서명을 온전히 보존한다.
  ditto "${BUNDLE}" "${INSTALLED}"
  echo "설치 완료: ${INSTALLED}"
else
  echo
  echo "완료: ${BUNDLE}"
  echo "설치하려면 --install 을 붙여서 다시 실행."
fi