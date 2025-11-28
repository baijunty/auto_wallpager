import 'dart:io';

import 'package:auto_wallpager/config.dart';
import 'package:auto_wallpager/lib.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

var client = ComfyClient('192.168.1.107:8188', Config(model: ''), Dio());
void main() {
  test('calculate', () async {
    await client.getImages().then((m) {
      for (var value in m) {
        print('${value.length}');
        File('temp.png').writeAsBytesSync(value);
      }
    });
  }, timeout: Timeout(Duration(minutes: 5)));
}
