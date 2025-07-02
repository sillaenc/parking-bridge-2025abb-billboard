# Billboard 서버 시스템 안내

이 프로젝트는 외부 설정 파일(assets 폴더)과 주기적 데이터 송수신 로직을 활용하여 전광판(빌보드) 정보를 관리하는 서버 애플리케이션입니다.

## 주요 동작 구조
- **설정 파일 로드**: `assets/setting.json`, `assets/listen_port.json`, `assets/backend.json`, `assets/packet.json` 등에서 각종 설정값을 읽어와 시스템에 반영합니다.
- **웹서버 구동**: `/checkSetting`, `/updateSetting`, `/setOverride`, `/isalive` 등 REST API를 제공합니다.
- **주기적 데이터 송수신**: 2초마다 백엔드에서 데이터를 받아 전광판에 맞는 패킷을 생성 및 송신합니다.
- **공휴일/5부제 처리**: 공휴일 및 5부제(홀짝제) 기능을 지원하며, 설정에 따라 동작이 달라집니다.

## assets 폴더 내 설정 파일 역할
- `setting.json`: 전광판 표시 내용, 라인별 텍스트, 색상 등 주요 설정값을 담고 있습니다.
- `listen_port.json`: 웹서버가 바인딩할 포트 번호를 지정합니다.
- `backend.json`: 백엔드 API 서버의 URL을 지정합니다.
- `packet.json`: 전광판 패킷 템플릿을 정의합니다.

## 공휴일 및 5부제 기능 안내
- **공휴일 정보**는 외부 API에서 받아와서, 해당 날짜가 공휴일이면 전광판에 "휴일" 표시 등 특수 처리를 할 수 있습니다.
- **5부제(홀짝제) 기능**은 요일/공휴일/override 값에 따라 표시 문구가 달라집니다.
- 공휴일 기능을 사용하려면 `bin/server.dart`의 아래 코드의 주석을 해제해야 합니다.

```dart
    // 4) 공휴일 업데이트
    // await holidayManager.updateHolidayInfo(settingsManager.settings);
```
- **공휴일 기능이 필요 없는 경우**(예: 5부제 미사용, 단순 카운트만 표시 등)에는 위 줄을 주석 처리한 상태로 두세요.
- **공휴일 기능이 필요한 경우**(예: 5부제, 휴일 표시 등)에는 위 줄의 주석을 해제하세요.

## 패키지 설치 및 서버 실행 방법

1. 의존성 패키지 설치:

```bash
dart pub get
```

2. 서버 실행:

```bash
dart run bin/server.dart
```
