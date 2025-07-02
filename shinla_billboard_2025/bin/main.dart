import 'dart:io';
import 'dart:convert';
import 'package:shinla_billboard_2025/settings_manager.dart';
import 'package:shinla_billboard_2025/protocol_packet.dart';
import 'package:shinla_billboard_2025/packet_sender.dart';

/// 프로그램 진입점: 설정 로딩, 화면 크기 설정 후 주기적 fetch, 패킷 생성/전송 전체 흐름
Future<void> main() async {
  try {
    // 설정 파일 로드
    final settings = await SettingsManager.load('assets/setting.json');
    print(
      '[LOG] 설정 파일 로드 완료: IP=[32m[1m${settings.ip}[0m, PORT=${settings.port}, api_url=${settings.apiUrl}, floor=${settings.floor}, width=${settings.width}, height=${settings.height}',
    );

    // 1. 화면 크기 설정 패킷 전송 (width/height)
    // 전광판 명령어 규격에 따라 id는 '004'로 고정(또는 필요시 설정에서 지정)
    // final screenSizePacket = ProtocolPacket.buildScreenSize(
    //   id: '004',
    //   width: settings.width,
    //   height: settings.height,
    // );
    // print('[LOG] 화면 크기 설정 패킷: $screenSizePacket');
    // await PacketSender.sendAndCheckAck(
    //   ip: settings.ip,
    //   port: settings.port,
    //   packet: screenSizePacket,
    // );
    print('[LOG] 화면 크기 설정 패킷 전송 완료');

    // lot_type별로 어떤 LED에 매핑되는지 맵 생성
    final ledToLotTypes = <int, List<LotTypeConfig>>{};
    for (final cfg in settings.lotTypes) {
      ledToLotTypes.putIfAbsent(cfg.led, () => []).add(cfg);
    }
    print('[LOG] lot_types 매핑: $ledToLotTypes');

    while (true) {
      try {
        // API에서 lot_type/count 데이터 fetch (POST, body: {"floor": settings.floor})
        final client = HttpClient();
        final req = await client.postUrl(Uri.parse(settings.apiUrl));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({"floor": settings.floor}));
        final result = await req.close();
        final body = await result.transform(utf8.decoder).join();
        print('[LOG] api_url 응답: $body');
        final List<dynamic> lotData = jsonDecode(body);

        // lot_type별 count 맵 생성 (lot_type을 문자열로 처리)
        final lotTypeToCount = <String, int>{};
        for (final item in lotData) {
          final lotType = item['lot_type'].toString();
          final count = item['count'];
          lotTypeToCount[lotType] = count;
        }
        print('[LOG] lot_type별 count: $lotTypeToCount');

        // lot_type 파트 중 B/F로 시작하는 경우 floor를 해당 값으로 하여 API를 추가 호출해 count 전체 합을 구하는 함수
        Future<int> getSumCount(String lotType) async {
          // lot_type에 +가 있으면 분리
          if (lotType.contains('+')) {
            int sum = 0;
            for (final part in lotType.split('+')) {
              final trimmed = part.trim();
              // B, F로 시작하면 floor를 해당 값으로 하여 API 추가 호출
              if (trimmed.startsWith('B') || trimmed.startsWith('F')) {
                try {
                  final client = HttpClient();
                  final req = await client.postUrl(Uri.parse(settings.apiUrl));
                  req.headers.contentType = ContentType.json;
                  req.write(jsonEncode({"floor": trimmed}));
                  final result = await req.close();
                  final body = await result.transform(utf8.decoder).join();
                  final List<dynamic> floorData = jsonDecode(body);
                  final floorSum = floorData.fold<int>(
                    0,
                    (prev, item) => prev + (item['count'] as int? ?? 0),
                  );
                  sum += floorSum;
                  print('[LOG] floor=$trimmed 전체 count 합: $floorSum');
                } catch (e) {
                  print('[ERROR] floor=$trimmed API 추가 호출 오류: $e');
                }
              } else {
                // 기존 lotTypeToCount 사용
                sum += lotTypeToCount[trimmed] ?? 0;
              }
            }
            return sum;
          } else {
            // 단일 lot_type
            if (lotType.startsWith('B') || lotType.startsWith('F')) {
              try {
                final client = HttpClient();
                final req = await client.postUrl(Uri.parse(settings.apiUrl));
                req.headers.contentType = ContentType.json;
                req.write(jsonEncode({"floor": lotType}));
                final result = await req.close();
                final body = await result.transform(utf8.decoder).join();
                final List<dynamic> floorData = jsonDecode(body);
                final floorSum = floorData.fold<int>(
                  0,
                  (prev, item) => prev + (item['count'] as int? ?? 0),
                );
                print('[LOG] floor=$lotType 전체 count 합: $floorSum');
                return floorSum;
              } catch (e) {
                print('[ERROR] floor=$lotType API 추가 호출 오류: $e');
                return 0;
              }
            } else {
              return lotTypeToCount[lotType] ?? 0;
            }
          }
        }

        // 기존 pagePacket 생성 코드 (주석처리)
        // final pagePacket = '![000/P0000/X0416/Y0108/${font}/S0000/${color} ${text}!]';

        // lot_types의 각 항목을 순회하여 [!000/C2 111/C2 222/C2 111/C2 111]! 형태로 패킷 생성
        final buffer = StringBuffer();
        buffer.write('![000');
        for (final cfg in settings.lotTypes) {
          // lot_type이 합연산이면 분리/합산, floor 자리면 floor count 사용 (비동기 처리)
          final count = await getSumCount(cfg.lotType);
          final countStr = count.toString().padLeft(settings.digit, '0');
          final color = cfg.color;
          final text = cfg.format.replaceAll('%d', countStr).trim();
          buffer.write('/$color $text');
        }
        buffer.write('!]');
        final pagePacket = buffer.toString();
        // 패킷 전송 전, 사람이 읽을 수 있는 ASCII 코드(원문) 로그 추가
        print('[LOG] 전송 패킷(ASCII): $pagePacket');
        final encoded = await ProtocolPacket.encodeEucKr(pagePacket);
        print(
          '패킷(HEX): \x1b[36m${encoded.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}\x1b[0m',
        );
        await PacketSender.sendAndCheckAck(
          ip: settings.ip,
          port: settings.port,
          packet: pagePacket,
        );
        print('[LOG] 페이지 패킷 전송 완료');
      } catch (e) {
        print('[ERROR] 데이터 fetch/전송 오류: $e');
      }
      await Future.delayed(Duration(seconds: settings.fetchInterval));
    }
  } catch (e, st) {
    print('[FATAL] 오류 발생: $e');
    print(st);
  }
}
