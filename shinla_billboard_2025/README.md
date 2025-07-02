# Shinla Billboard 2025

신라이앤씨 입구 종합 안내판(1x8, 3BPP) 제어용 TCP/IP 메시지 송신 프로그램

## 주요 기능
- 설정 파일 기반 다중 전광판(LED) 메시지 관리 (예: 4개 LED, 각 1줄)
- DABIT Protocol 기반 패킷 생성 및 전송
- 색상 코드, 표시 시간, 반복 횟수 등 자유 설정
- TCP/IP로 실시간 메시지 송신

## 설정 예시 (assets/setting.json)
```json
{
  "IP": "192.168.0.100",
  "PORT": "5000",
  "leds": [
    [ { "color": "C2", "text": "어서오세요" }, { "color": "C1", "text": "52 가 1234" } ],
    [ { "color": "C2", "text": "환영합니다" } ],
    [ { "color": "C3", "text": "공지사항" } ],
    [ { "color": "C4", "text": "비상구" } ]
  ],
  "repeat": 1,
  "duration": 10
}
```
## 실행 전 필수 내용
```
dart pub get
```

## 실행 방법
```bash
dart run bin/main.dart
```

## 참고
- 색상 코드는 DABIT Protocol Manual_ASCII.pdf 참조
- 메시지/LED 개수는 설정 파일로 자유롭게 변경 가능
