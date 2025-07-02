import 'dart:convert';
import 'dart:io';

/// lot_type별 매핑 정보
class LotTypeConfig {
  /// lot_type을 문자열로 받아 복합 lot_type(B1+1 등) 지원
  final String lotType;
  final int led;
  final String color;
  final String format;
  final int fontSize;
  LotTypeConfig({
    required this.lotType,
    required this.led,
    required this.color,
    required this.format,
    required this.fontSize,
  });
  factory LotTypeConfig.fromJson(Map<String, dynamic> json) => LotTypeConfig(
    lotType: json['lot_type'].toString(),
    led: json['led'],
    color: json['color'],
    format: json['format'],
    fontSize: json['font_size'] ?? 3,
  );
}

/// 설정 정보를 담는 데이터 클래스
class Settings {
  final String ip;
  final int port;
  final String apiUrl;
  final int fetchInterval;
  final String floor;
  final int width;
  final int height;
  final List<LotTypeConfig> lotTypes;
  final int repeat;
  final int duration;
  final int digit;

  Settings({
    required this.ip,
    required this.port,
    required this.apiUrl,
    required this.fetchInterval,
    required this.floor,
    required this.width,
    required this.height,
    required this.lotTypes,
    required this.repeat,
    required this.duration,
    required this.digit,
  });
}

/// 설정 파일 로딩 및 파싱 담당
class SettingsManager {
  /// 설정 파일을 읽어 Settings 객체로 반환
  static Future<Settings> load(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      final jsonMap = jsonDecode(content);
      return Settings(
        ip: jsonMap['IP'] ?? '127.0.0.1',
        port: int.tryParse(jsonMap['PORT'].toString()) ?? 5000,
        apiUrl: jsonMap['api_url'] ?? '',
        fetchInterval: jsonMap['fetch_interval'] ?? 2,
        floor: jsonMap['floor'] ?? 'F1',
        width: jsonMap['width'] ?? 128,
        height: jsonMap['height'] ?? 16,
        lotTypes: (jsonMap['lot_types'] as List)
            .map<LotTypeConfig>((e) => LotTypeConfig.fromJson(e))
            .toList(),
        repeat: jsonMap['repeat'] ?? 1,
        duration: jsonMap['duration'] ?? 10,
        digit: jsonMap['digit'] ?? 3,
      );
    } catch (e) {
      print('설정 파일 로딩 오류: $e');
      rethrow;
    }
  }
}
