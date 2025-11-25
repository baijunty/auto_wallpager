import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:auto_wallpager/lib.dart';
import 'package:dio/dio.dart';
import 'package:logger/web.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket/web_socket.dart';

import 'config.dart';

class ComfyClient {
  final String url;
  late String _clientId;
  late Map<String, dynamic> workflow;
  final Dio _dio;
  final _queue = <String>[];
  final completed = <String>[];
  final Config config;
  final Logger? logger;
  WebSocket? _ws;
  ComfyClient(this.url, this.config, this._dio, {this.logger}) {
    _clientId = Uuid().v4();
    // Listen to websocket for completion signal
    File('dart_v2.json').watch(events: FileSystemEvent.modify).listen((_) {
      logger?.d('Reloading workflow');
      _initWorkflow();
    });
  }

  Future<void> _init() async {
    try {
      if (_ws == null) {
        var uri = Uri.parse(url);
        _ws = await WebSocket.connect(
          Uri.parse(
            '${uri.scheme == 'http' ? 'ws' : 'wss'}://${uri.host}:${uri.port}/ws?clientId=$_clientId',
          ),
        );
        _initWorkflow();
        loopForId();
      }
    } catch (e) {
      print(e);
      _ws?.close();
      _ws = null;
    }
  }

  Future<void> _initWorkflow() async {
    workflow = json.decode(File('dart_v2.json').readAsStringSync());
    workflow['client_id'] = _clientId;
    var prompt = workflow['prompt'] as Map<String, dynamic>;
    prompt['26']['inputs']['model'] = config.tagModel;
    prompt['36']['inputs']['ckpt_name'] = config.model;
    prompt['27']['inputs']['rating'] = config.rating;
    prompt['27']['inputs']['character'] = config.target?.name ?? '';
    prompt['27']['inputs']['copyright'] = config.target?.product ?? '';
  }

  Future<void> loopForId() async {
    await for (final out in _ws!.events) {
      if (out is TextDataReceived) {
        final message = json.decode(out.text);
        if (message is Map && message['type'] == 'executing') {
          final data = message['data'];
          if (data is Map &&
              data['node'] == null &&
              _queue.contains(data['prompt_id'])) {
            completed.add(data['prompt_id']);
            _queue.remove(data['prompt_id']);
          }
        }
      } else if (out is CloseReceived) {
        logger?.e('Connection closed ${out.reason}');
        _ws = null;
        break;
      }
    }
  }

  Future<void> close() async {
    await _ws?.close();
  }

  Future<Map<String, dynamic>> _queuePrompt() async {
    await _init();
    (workflow['prompt']['40'])['inputs']['seed'] = Random().nextInt64();
    (workflow['prompt']['43'])['inputs']['seed'] = Random().nextInt(1 << 32);
    final response = await _dio.post<Map<String, dynamic>>(
      '$url/prompt',
      data: json.encode(workflow),
      options: Options(responseType: ResponseType.json),
    );
    logger?.d(response.data);
    return response.data!;
  }

  Future<Uint8List> _getImage(
    String filename,
    String subfolder,
    String folderType,
  ) async {
    await _init();
    final data = {
      "filename": filename,
      "subfolder": subfolder,
      "type": folderType,
    };
    final urlValues = Uri(queryParameters: data).query;
    final response = await _dio.get<Uint8List>(
      '$url/view?$urlValues',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> getHistory(String promptId) async {
    await _init();
    final response = await _dio.get<Map<String, dynamic>>(
      '$url/history/$promptId',
      options: Options(responseType: ResponseType.json),
    );
    return response.data!;
  }

  Future<List<Uint8List>> getImages() async {
    await _init();
    final result = await _queuePrompt();
    final promptId = result['prompt_id'];
    final outputImages = <Uint8List>[];
    _queue.add(promptId);
    while (_queue.contains(promptId)) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    final history = await getHistory(promptId);
    final promptHistory = history[promptId];
    if (promptHistory != null && promptHistory['outputs'] != null) {
      final outputs = promptHistory['outputs'];

      for (final nodeId in outputs.keys) {
        final nodeOutput = outputs[nodeId];

        if (nodeOutput is Map && nodeOutput['images'] != null) {
          final images = nodeOutput['images'];
          if (images is List) {
            for (final image in images) {
              if (image is Map) {
                final imageData = await _getImage(
                  image['filename'].toString(),
                  image['subfolder'].toString(),
                  image['type'].toString(),
                );
                outputImages.add(imageData);
              }
            }
          }
        }
      }
    }
    return outputImages;
  }
}
