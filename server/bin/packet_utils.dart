import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class PacketUtils {
  // JSON 파일로부터 로드한 프로토콜 템플릿 저장 변수
  static String packetTemplate = "";

  // asset/packet.json에서 템플릿을 읽어옴
  static Future<void> loadPacketTemplate() async {
    try {
      String content = await File('assets/packet.json').readAsString();
      Map<String, dynamic> jsonData = jsonDecode(content);
      packetTemplate = jsonData["packet"] ?? "";
      // 불필요한 백슬래시 제거: "\$" → "$"
      packetTemplate = packetTemplate.replaceAll(r'\$', r'$');
      print("Packet template loaded: $packetTemplate");
    } catch (e) {
      print("Error loading packet template: $e");
    }
  }

  static Uint8List buildPacketWithType(String command, int type) {
    List<int> dataBytes = utf16leEncode(command);
    int dataLength = dataBytes.length;
    List<int> packet = [];
    const int STX = 0x02;
    packet.add(STX);
    packet.add(type);
    // LENGTH(2바이트, little-endian)
    packet.add(dataLength & 0xFF);
    packet.add((dataLength >> 8) & 0xFF);
    packet.addAll(dataBytes);

    int checksum = (STX +
            type +
            (dataLength & 0xFF) +
            ((dataLength >> 8) & 0xFF) +
            dataBytes.fold<int>(0, (prev, b) => prev + b)) &
        0xFF;
    packet.add(checksum);
    packet.add(0x03);
    return Uint8List.fromList(packet);
  }

  static List<int> utf16leEncode(String input) {
    List<int> bytes = [];
    for (int codeUnit in input.codeUnits) {
      bytes.add(codeUnit & 0xFF);
      bytes.add((codeUnit >> 8) & 0xFF);
    }
    return bytes;
  }

  // 기존 하드코딩된 명령어 대신, JSON 템플릿을 사용하여 명령어 문자열 구성
  static String constructCommand(int line, String text, String colorCode) {
    if (packetTemplate.isEmpty) {
      // 템플릿 로드에 실패한 경우 기본 문자열 사용
      return "RST=1,LNE=$line,YSZ=1,EFF=090009000900,FIX=0,TXT=\$$colorCode\$F00\$A00$text,";
    }
    String result = packetTemplate
      .replaceAll("\$line", line.toString())
      .replaceAll("\$colorCode", colorCode)
      .replaceAll("\$text", text);
    return result;
  }

  static String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ");
  }
}