import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:auto_wallpager/lib.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket/web_socket.dart';

import 'config.dart';
import 'workflow_template.dart';

class ComfyClient {
  final String url;
  late String _clientId;
  final Map<String, dynamic> workflow = template;
  final Dio _dio;
  final _queue = <String>[];
  final completed = <String>[];
  final Config config;
  WebSocket? _ws;
  ComfyClient(this.url, this.config, this._dio) {
    _clientId = Uuid().v4();
  }

  Future<void> _init() async {
    try {
      if (_ws == null) {
        var uri =
            '${url.startsWith('https') ? 'wss' : 'ws'}${url.substring(url.startsWith('https') ? 5 : 4)}/ws?clientId=$_clientId';
        _ws = await WebSocket.connect(Uri.parse(uri));
        _initWorkflow();
        loopForId();
      }
    } catch (e) {
      print('init error $e');
      _ws?.close();
      _ws = null;
    }
  }

  Future<void> _initWorkflow() async {
    workflow['client_id'] = _clientId;
    var prompt = workflow['prompt'] as Map<String, dynamic>;
    // DanbooruTagsTransformerLoader - model
    prompt['62']['inputs']['model'] = config.tagModel;
    // DanbooruTagsTransformerComposePromptV2 - prompt composition
    prompt['63']['inputs']['rating'] = config.rating;
    prompt['63']['inputs']['character'] = config.target?.name ?? '';
    prompt['63']['inputs']['copyright'] = config.target?.series ?? '';
    switch (config.width / config.height) {
      case >= 2:
        prompt['63']['inputs']['aspect_ratio'] = 'ultra_wide';
        break;
      case >= 9 / 8 && < 2:
        prompt['63']['inputs']['aspect_ratio'] = 'wide';
        break;
      case >= 8 / 9 && < 9 / 8:
        prompt['63']['inputs']['aspect_ratio'] = 'square';
        break;
      case < 8 / 9:
        prompt['63']['inputs']['aspect_ratio'] = 'tall';
        break;
      default:
        prompt['63']['inputs']['aspect_ratio'] = 'wide';
        break;
    }
    // UpscaleModelLoader - upscale model
    prompt['71']['inputs']['model_name'] = config.upscaleModel;
    // DanbooruTagsTransformerGenerateAdvanced - ban tags
    if (config.blockTags != null && config.blockTags!.isNotEmpty) {
      prompt['64']['inputs']['ban_tags'] = config.blockTags!.join(',');
    }
    // UNETLoader - model (optional override)
    if (config.model != null && config.model!.isNotEmpty) {
      prompt['57:28']['inputs']['unet_name'] = config.model;
    }
    // EmptySD3LatentImage - dimensions
    prompt['57:13']['inputs']['width'] = config.width;
    prompt['57:13']['inputs']['height'] = config.height;
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
        print('Connection closed ${out.reason}');
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
    var prompt = workflow['prompt'] as Map<String, dynamic>;
    // DanbooruTagsTransformerGenerateAdvanced - seed for tag generation
    prompt['64']['inputs']['seed'] = Random().nextInt(1 << 32);
    // KSampler - seed for image generation
    prompt['57:3']['inputs']['seed'] = Random().nextInt64();
    final response = await _dio.post<Map<String, dynamic>>(
      '$url/prompt',
      data: json.encode(workflow),
      options: Options(
        responseType: ResponseType.json,
        headers: {'Authorization': config.authorization},
      ),
    );
    print(response.data);
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
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Authorization': config.authorization},
      ),
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> getHistory(String promptId) async {
    await _init();
    final response = await _dio.get<Map<String, dynamic>>(
      '$url/history/$promptId',
      options: Options(
        responseType: ResponseType.json,
        headers: {'Authorization': config.authorization},
      ),
    );
    return response.data!;
  }

  Future<void> _freeMemory() async {
    try {
      await _dio.post(
        '$url/free',
        data: json.encode({'unload_models': true, 'free_memory': true}),
        options: Options(headers: {'Authorization': config.authorization}),
      );
    } catch (e) {
      // 即使释放内存失败，也不影响主流程
      print('Failed to free memory: $e');
    }
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

        if (nodeOutput is Map) {
          final images = nodeOutput['images'] ?? nodeOutput["text"];
          if (images is List) {
            for (final image in images) {
              if (image is Map) {
                final imageData = await _getImage(
                  image['filename'].toString(),
                  image['subfolder'].toString(),
                  image['type'].toString(),
                );
                outputImages.add(imageData);
              } else if (image is String) {
                final obj = json.decode(image) as Map;
                outputImages.add(base64Decode(obj.values.first));
              }
            }
          }
        }
      }
    }
    if (config.releaseMemory) {
      await _freeMemory();
    }
    return outputImages;
  }
}
