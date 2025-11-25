import 'dart:io';

import 'package:auto_wallpager/config.dart';
import 'package:auto_wallpager/lib.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

var client = ComfyClient('192.168.1.107:8188', Config(), Dio());
void main() {
  test('calculate', () async {
    await client.getImages().then((m) {
      m.forEach((key, value) {
        print('$key: ${value.length}');
        File('$key.png').writeAsBytesSync(value[0]);
      });
    });
  }, timeout: Timeout(Duration(minutes: 5)));
}
