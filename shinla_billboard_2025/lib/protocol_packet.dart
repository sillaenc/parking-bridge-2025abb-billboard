import 'dart:convert';
import 'package:cp949_codec/cp949_codec.dart';

/// DABIT ASCII 프로토콜 규격에 맞는 패킷 생성 유틸리티
class ProtocolPacket {
  /// 실시간 메시지 패킷 생성 (sss.md 규격)
  /// address: 1자리(0: 싱글, 1~F: 멀티), errorCheck: 0/1, type: 0(실시간), data: 속성/문자열
  static String buildRealtime({
    required String address, // 1자리
    int errorCheck = 0, // 0(기본)
    String type = '0', // 0(실시간)
    String? data, // 속성 및 표시 문자열 전체
  }) {
    final buffer = StringBuffer();
    buffer.write('![');
    buffer.write(address);
    buffer.write(errorCheck.toString());
    buffer.write(type);
    if (data != null && data.isNotEmpty) {
      buffer.write(data);
    }
    buffer.write('!]');
    return buffer.toString();
  }

  /// 페이지 메시지 패킷 생성 (sss.md 규격)
  /// address: 1자리(0: 싱글, 1~F: 멀티), errorCheck: 0/1, type: 1(페이지), data: 속성/문자열
  static String buildPage({
    required String address, // 1자리
    int errorCheck = 0, // 0(기본)
    String type = '1', // 1(페이지)
    String? data, // 속성 및 표시 문자열 전체
  }) {
    final buffer = StringBuffer();
    buffer.write('![');
    buffer.write(address);
    buffer.write(errorCheck.toString());
    buffer.write(type);
    if (data != null && data.isNotEmpty) {
      buffer.write(data);
    }
    buffer.write('!]');
    return buffer.toString();
  }

  /// 화면 크기 설정 패킷 생성: ![00402060!] (주소 3자리 + 40 + height 2자리 + width 2자리 + layout 1자리 + 종료)
  static String buildScreenSize({
    required String id, // 3자리 주소
    required int height, // 세로 모듈 개수 (XX)
    required int width, // 가로 모듈 개수 (YY)
    int layout = 0, // 배열방식 Z (기본 0: 가로형)
  }) {
    final buffer = StringBuffer();
    buffer.write('![');
    buffer.write(id); // 3자리 주소
    buffer.write('00'); // 명령어
    buffer.write(height.toString().padLeft(2, '0'));
    buffer.write(width.toString().padLeft(2, '0'));
    buffer.write(layout.toString());
    buffer.write('!]');
    return buffer.toString();
  }

  /// 특수 명령 패킷 생성 (명령어, 데이터 등 자유롭게)
  static String buildSpecial({
    required String address, // 1자리
    required String command, // 2자리 명령어
    String extra = '', // 추가필드(필요시)
    String? data, // 데이터(필요시)
  }) {
    final buffer = StringBuffer();
    buffer.write('![');
    buffer.write(address);
    buffer.write(command);
    if (extra.isNotEmpty) buffer.write(extra);
    if (data != null && data.isNotEmpty) buffer.write(data);
    buffer.write('!]');
    return buffer.toString();
  }

  /// 패킷을 CP949(EUC-KR 호환)로 인코딩하여 전광판에 전송할 수 있도록 변환
  static Future<List<int>> encodeEucKr(String packet) async {
    return cp949.encode(packet);
  }
}
