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
      var url = args['url'];
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
  parser.addOption('url', abbr: 'u', defaultsTo: 'http://127.0.0.1:8188');
  parser.addOption('time', abbr: 't', defaultsTo: '10');
  parser.addFlag('deamon', abbr: 'd', defaultsTo: false);
  return parser;
}
