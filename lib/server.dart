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
  late Timer _timer;
  final String _configFilePath;
  Config get config => _config;
  final _success = {'message': 'ok', 'success': true};
  TaskWrap(this._configFilePath, this._dio) {
    _config = Config.fromJson(
      json.decode(File(_configFilePath).readAsStringSync()),
    );
    _client = ComfyClient(_config.address, _config, _dio);
    _router
      ..get('/', _mainPage)
      ..post('/setting', _setting)
      ..get('/config', (req) => Response.ok(json.encode(_config.toJson())))
      ..get('/nextPaper', _nextWallPaper)
      ..get('/pause', _pause)
      ..get('/restart', _restart);
    _timer = Timer.periodic(Duration(minutes: _config.duration), (timer) async {
      await _next();
    });
  }

  Future<Response> _setting(Request request) async {
    final body = await request.readAsString();
    var newConfig = Config.fromJson(json.decode(body));
    File(_configFilePath).writeAsStringSync(json.encode(newConfig.toJson()));
    _client.close();
    _client = ComfyClient(newConfig.address, newConfig, _dio);
    _restart(request);
    _config = newConfig;
    return Response.ok(json.encode(_success));
  }

  Future<Response> _mainPage(Request request) async {
    return Response.ok(
      htmlTemplate,
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  Future<void> _next() async {
    try {
      final images = await _client.getImages();
      final image = images.first;
      final temp = File('temp.png');
      temp.writeAsBytesSync(image);
      print('set wallpaper');
      if (setWallpaper(temp.absolute.path) == 0) {
        print('failed to set wallpaper');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<Response> _nextWallPaper(Request req) async {
    try {
      await _next();
      _restart(req);
      return Response.ok(json.encode(_success));
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'message': '$e', 'success': false}),
      );
    }
  }

  Future<Response> _pause(Request req) async {
    _timer.cancel();
    return Response.ok(json.encode(_success));
  }

  Future<Response> _restart(Request req) async {
    _timer.cancel();
    _timer = Timer.periodic(Duration(minutes: _config.duration), (timer) async {
      await _next();
    });
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
