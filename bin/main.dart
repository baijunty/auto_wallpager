import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:auto_wallpager/config.dart';
import 'package:auto_wallpager/server.dart';
import 'package:dio/dio.dart';

void main(List<String> arguments) async {
  var parser = _createArgParser();
  try {
    var args = parser.parse(arguments);
    if (args['deamon']) {
      var file = File('config.json');
      // 验证IP地址格式
      var ip = args['ip'];
      if (!_isValidIp(ip)) {
        print('无效的IP地址: $ip');
        print(parser.usage);
        exit(1);
      }

      // 验证端口格式
      var port = args['port'];
      if (!_isValidPort(port)) {
        print('无效的端口号: $port');
        print(parser.usage);
        exit(1);
      }
      var url = '$ip:$port';
      var time = int.parse(args['time']);
      if (time <= 0) {
        print('时间间隔必须大于0');
        print(parser.usage);
        exit(1);
      }
      var config = Config(address: url, duration: time);
      if (!file.existsSync()) {
        file.writeAsStringSync(json.encode(config));
      } else {
        config = Config.fromJson(json.decode(file.readAsStringSync()));
      }
      runServer(TaskWrap(config));
    } else {
      await Dio().get('http://127.0.0.1:8987/nextPaper');
    }
  } catch (e) {
    print('参数错误$e');
    print(parser.usage);
  }
}

ArgParser _createArgParser() {
  final parser = ArgParser();
  parser.addOption('ip', abbr: 'i', defaultsTo: '127.0.0.1');
  parser.addOption('port', abbr: 'p', defaultsTo: '8188');
  parser.addOption('time', abbr: 't', defaultsTo: '10');
  parser.addFlag('deamon', abbr: 'd', defaultsTo: false);
  return parser;
}

bool _isValidIp(String ip) {
  final ipv4Pattern = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
  if (!ipv4Pattern.hasMatch(ip)) {
    return false;
  }

  final parts = ip.split('.');
  for (var part in parts) {
    final num = int.tryParse(part);
    if (num == null || num < 0 || num > 255) {
      return false;
    }
  }

  return true;
}

bool _isValidPort(String port) {
  final num = int.tryParse(port);
  if (num == null) {
    return false;
  }

  return num >= 1 && num <= 65535;
}
