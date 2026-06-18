import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' show Dio;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'html_template.dart';
import 'lib.dart';

class TaskWrap {
  final Router _router = Router();
  final Dio _dio;
  late Config _config;
  late ComfyClient _client;
  Timer? _timer;
  final String _configFilePath;
  Config get config => _config;
  final _success = {'message': 'ok', 'success': true};

  TaskWrap(this._configFilePath, this._dio) {
    _config = Config.fromJson(
      json.decode(File(_configFilePath).readAsStringSync()),
    );
    _client = ComfyClient(_config, _dio);
    _router
      ..get('/', _mainPage)
      ..post('/setting', _setting)
      ..get('/config', (req) => Response.ok(json.encode(_config.toJson())))
      ..get('/nextPaper', _nextWallPaper)
      ..get('/pause', _pause)
      ..get('/restart', _restart);
    _scheduleNextGeneration();
  }

  Future<Response> _setting(Request request) async {
    final body = await request.readAsString();
    var newConfig = Config.fromJson(json.decode(body));
    print('new config: $newConfig from $body');
    File(_configFilePath).writeAsStringSync(json.encode(newConfig.toJson()));
    _client.close();
    _config = newConfig;
    _client = ComfyClient(newConfig, _dio);
    _restart(request);
    return Response.ok(json.encode(_success));
  }

  Future<Response> _mainPage(Request request) async {
    return Response.ok(
      htmlTemplate,
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  /// 保存下次生成时间到配置文件
  void _saveNextGenTime(DateTime? time) {
    _config = _config.copyWith(nextGenTime: time);
    File(_configFilePath).writeAsStringSync(json.encode(_config.toJson()));
  }

  /// 获取下一次应该生成的时间
  DateTime _getNextGenerationTime() {
    final now = DateTime.now();
    // 如果没有记录的时间，使用当前时间 + duration 分钟
    if (_config.nextGenTime == null) {
      return now.add(Duration(minutes: _config.duration));
    }
    // 如果已到记录的时间（或超时），直接返回当前时间（触发立即生成）
    if (!_config.nextGenTime!.isAfter(now)) {
      return now;
    }
    return _config.nextGenTime!;
  }

  /// 调度下一次壁纸生成
  void _scheduleNextGeneration() {
    _timer?.cancel();

    final now = DateTime.now();
    final nextTime = _getNextGenerationTime();

    // 如果已到生成时间（或超时），立即生成
    if (nextTime.isBefore(now) || nextTime.isAtSameMomentAs(now)) {
      print('Next generation time reached ($nextTime), generating immediately');
      _triggerGeneration();
      return;
    }

    // 否则定时到指定时间生成
    final delay = nextTime.difference(now);
    print('Next generation scheduled at $nextTime (in ${delay.inSeconds} seconds)');
    _saveNextGenTime(nextTime);

    _timer = Timer(delay, () {
      print('Scheduled generation time reached');
      _triggerGeneration();
    });
  }

  /// 触发壁纸生成
  Future<void> _triggerGeneration() async {
    try {
      final images = await _client.getImages();
      final image = images.first;
      final temp = File('temp.png');
      temp.writeAsBytesSync(image);
      print('set wallpaper');
      if (setWallpaper(temp.absolute.path) == 0) {
        print('failed to set wallpaper');
      }
      // 生成完成后，设置下次生成时间
      final nextTime = DateTime.now().add(Duration(minutes: _config.duration));
      _saveNextGenTime(nextTime);
      // 重新调度
      _scheduleNextGeneration();
    } catch (e, stack) {
      print('fetch next paper $e with $stack');
      // 出错时重新调度
      _scheduleNextGeneration();
    }
  }

  Future<Response> _nextWallPaper(Request req) async {
    try {
      await _triggerGeneration();
      return Response.ok(json.encode(_success));
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'message': '$e', 'success': false}),
      );
    }
  }

  Future<Response> _pause(Request req) async {
    _timer?.cancel();
    _timer = null;
    _saveNextGenTime(null);
    return Response.ok(json.encode(_success));
  }

  Future<Response> _restart(Request req) async {
    _scheduleNextGeneration();
    return Response.ok(json.encode(_success));
  }
}

Future<void> runServer(TaskWrap wrap) async {
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(wrap._router.call);
  final servers = await serve(
    handler,
    InternetAddress.loopbackIPv4,
    8987,
    poweredByHeader: 'wallpager',
  );
  print('visit http://127.0.0.1:8987 to configure');
  servers.autoCompress = true;
}
