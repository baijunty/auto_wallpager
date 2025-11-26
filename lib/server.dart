import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' show Dio;
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'lib.dart';

class TaskWrap {
  final Router _router = Router();
  final Dio _dio;
  var _config = Config();
  late ComfyClient _client;
  late Timer _timer;
  final logger = Logger(
    output: AdvancedFileOutput(path: 'wallpaper.log', overrideExisting: true),
  );
  Config get config => _config;
  final success = {'message': 'ok', 'success': true};
  TaskWrap(this._config, this._dio) {
    logger.e('start server');
    _client = ComfyClient(_config.address, _config, _dio, logger: logger);
    _router
      ..post('/setting', _setting)
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
    if (newConfig.address != _config.address) {
      _client = ComfyClient(newConfig.address, newConfig, _dio, logger: logger);
      _restart(request);
    }
    _config = newConfig;
    return Response.ok(json.encode(success));
  }

  Future<void> _next() async {
    final images = await _client.getImages();
    final image = images.first;
    final temp = File('temp.png');
    temp.writeAsBytesSync(image);
    logger.d('set wallpaper');
    if (setWallpaper(temp.absolute.path) != 0) {
      logger.d('failed to set wallpaper');
    }
  }

  Future<Response> _nextWallPaper(Request req) async {
    try {
      await _next();
      _restart(req);
      return Response.ok(json.encode(success));
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'message': '$e', 'success': false}),
      );
    }
  }

  Future<Response> _pause(Request req) async {
    _timer.cancel();
    return Response.ok(json.encode(success));
  }

  Future<Response> _restart(Request req) async {
    _timer.cancel();
    _timer = Timer.periodic(Duration(minutes: _config.duration), (timer) async {
      await _next();
    });
    return Response.ok(json.encode(success));
  }
}

Future<void> runServer(TaskWrap wrap) async {
  final handler = Pipeline()
      .addMiddleware(
        logRequests(
          logger: (message, isError) {
            isError ? wrap.logger.e(message) : wrap.logger.d(message);
          },
        ),
      )
      .addHandler(wrap._router.call);
  final servers = await serve(
    handler,
    InternetAddress.loopbackIPv4,
    8987,
    poweredByHeader: 'wallpager',
  );
  servers.autoCompress = true;
  wrap._next();
}
