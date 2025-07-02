import 'dart:io';
import 'protocol_packet.dart';
// import 'package:charset_converter/charset_converter.dart';

/// TCP/IP로 패킷을 전송하는 유틸리티
class PacketSender {
  /// 지정 IP/PORT로 패킷 문자열을 전송 (EUC-KR 인코딩)
  static Future<void> send({
    required String ip,
    required int port,
    required String packet,
  }) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(seconds: 3),
      );
      // EUC-KR 인코딩 적용
      final encoded = await ProtocolPacket.encodeEucKr(packet);
      socket.add(encoded);
      await socket.flush();
      socket.listen((data) {
        print('Received: ${data}');
      });
      await Future.delayed(Duration(seconds: 2));
      await socket.close();
    } catch (e) {
      print('패킷 전송 오류: $e');
    }
  }

  /// 진단/상태/버전 요청 패킷 전송 및 응답 판별
  static Future<void> sendAndCheckAck({
    required String ip,
    required int port,
    required String packet,
  }) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(seconds: 3),
      );
      final encoded = await ProtocolPacket.encodeEucKr(packet);
      socket.add(encoded);
      await socket.flush();
      socket.listen((data) {
        final resp = String.fromCharCodes(data);
        print('전광판 응답: $resp');
        if (resp.contains('0010')) {
          print('정상 수신(ACK)');
        } else if (resp.contains('001F')) {
          print('에러/미수신(NACK)');
        } else {
          print('기타 응답: $resp');
        }
      });
      await Future.delayed(Duration(seconds: 2));
      await socket.close();
    } catch (e) {
      print('진단 패킷 전송 오류: $e');
    }
  }
}
