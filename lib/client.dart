import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:auto_wallpager/lib.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket/web_socket.dart';

import 'config.dart';
import 'workflow_template.dart';

class ComfyClient {
  late String _clientId;
  Map<String, dynamic> workflow = {};
  final Dio _dio;
  final _queue = <String>[];
  final completed = <String>[];
  final Config config;
  WebSocket? _ws;
  ComfyClient(this.config, this._dio) {
    _clientId = Uuid().v4();
    // 如果有配置的模板路径，从 API 加载
    print("config $config");
    if (config.templatePath != null && config.templatePath!.isNotEmpty) {
      _loadTemplateFromApi(config.templatePath!);
    } else {
      // 默认使用内置模板
      workflow = Map<String, dynamic>.from(template);
    }
  }

  /// 从 API 加载工作流模板
  Future<void> _loadTemplateFromApi(String templatePath) async {
    final url = '${config.address}/api/userdata/api_workflows%2F$templatePath';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(
          responseType: ResponseType.json,
          headers: {'Authorization': config.authorization},
        ),
      );

      if (response.data != null && response.data!.containsKey('prompt')) {
        workflow = Map<String, dynamic>.from(response.data!);
        await _configureWorkflowByClassType();
      }
    } catch (e) {
      print('Failed to load template from API $url : $e');
      // 加载失败时使用内置模板
      workflow = Map<String, dynamic>.from(template);
    }
  }

  /// 从外部 JSON 文件加载 workflow 模板
  ///
  /// [filePath] JSON 文件路径
  /// [setClassType] 当为 true 时，通过 class_type 搜索并设置相关配置项
  Future<void> loadWorkflowFromJson(
    String filePath, {
    bool setClassType = true,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Workflow file not found', filePath);
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;

    // 验证 JSON 结构
    if (!json.containsKey('prompt')) {
      throw FormatException('Invalid workflow JSON: missing "prompt" key');
    }

    workflow = json;

    if (setClassType) {
      await _configureWorkflowByClassType();
    }
  }

  /// 从 API 加载工作流模板（公共方法）
  ///
  /// [templatePath] 模板路径，例如："anima.json" 或 "subdir/template.json"
  Future<void> loadTemplateFromApi(String templatePath) async {
    await _loadTemplateFromApi(templatePath);
  }

  /// 通过 class_type 搜索并配置 workflow 中的节点
  Future<void> _configureWorkflowByClassType() async {
    workflow['client_id'] = _clientId;
    var prompt = workflow['prompt'] as Map<String, dynamic>;

    // 遍历所有节点，按 class_type 配置
    prompt.forEach((nodeId, node) {
      if (node is! Map<String, dynamic>) return;
      if (node['class_type'] case final classType?) {
        _configureNodeByClassType(prompt, nodeId, classType);
      }
    });
  }

  /// 根据 class_type 配置单个节点
  void _configureNodeByClassType(
    Map<String, dynamic> prompt,
    String nodeId,
    String classType,
  ) {
    final inputs = prompt[nodeId]['inputs'] as Map<String, dynamic>;
    switch (classType) {
      case 'DanbooruTagsTransformerLoader':
        inputs['model'] = config.tagModel;
        break;

      case 'DanbooruTagsTransformerComposePromptV2':
        inputs['rating'] = config.rating;
        inputs['character'] = config.target?.name ?? '';
        inputs['copyright'] = config.target?.series ?? '';
        inputs['aspect_ratio'] = _calculateAspectRatio();
        break;

      case 'UpscaleModelLoader':
        inputs['model_name'] = config.upscaleModel;
        break;

      case 'DanbooruTagsTransformerGenerateAdvanced':
        if (config.blockTags != null && config.blockTags!.isNotEmpty) {
          inputs['ban_tags'] = config.blockTags!.join(',');
        }
        break;

      case 'UNETLoader':
        if (config.model != null && config.model!.isNotEmpty) {
          inputs['unet_name'] = config.model;
        }
        break;
      case 'EmptyLatentImage':
      case 'EmptySD3LatentImage':
        inputs['width'] = config.width;
        inputs['height'] = config.height;
        break;
    }
    print("set $classType for $nodeId $inputs");
  }

  /// 根据宽高比计算 aspect_ratio
  String _calculateAspectRatio() {
    switch (config.width / config.height) {
      case >= 2:
        return 'ultra_wide';
      case >= 9 / 8 && < 2:
        return 'wide';
      case >= 8 / 9 && < 9 / 8:
        return 'square';
      case < 8 / 9:
        return 'tall';
      default:
        return 'wide';
    }
  }

  /// 根据 class_type 设置特定节点的某个输入项
  ///
  /// [classType] 节点类型
  /// [inputKey] 要设置的输入键名
  /// [value] 要设置的值
  void setNodeInputByClassType(
    String classType,
    String inputKey,
    dynamic value,
  ) {
    var prompt = workflow['prompt'] as Map<String, dynamic>;
    prompt.forEach((nodeId, node) {
      if (node is Map<String, dynamic>) {
        if (node['class_type'] == classType) {
          final inputs = node['inputs'] as Map<String, dynamic>;
          inputs[inputKey] = value;
        }
      }
    });
  }

  /// 初始化 workflow 配置
  void _initWorkflow() {
    workflow['client_id'] = _clientId;
    var prompt = workflow['prompt'] as Map<String, dynamic>;

    // 遍历所有节点，按 class_type 配置
    prompt.forEach((nodeId, node) {
      if (node is! Map<String, dynamic>) return;
      final classType = node['class_type'];
      if (classType != null && classType is String) {
        _configureNodeByClassType(prompt, nodeId, classType);
      }
    });
  }

  /// 初始化 WebSocket 连接
  Future<void> _init() async {
    try {
      if (_ws == null) {
        var uri =
            '${config.address.startsWith('https') ? 'wss' : 'ws'}${config.address.substring(config.address.startsWith('https') ? 5 : 4)}/ws?clientId=$_clientId';
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

  /// 查找所有匹配 class_type 的节点 ID
  List<String> findNodesByClassType(String classType) {
    var prompt = workflow['prompt'] as Map<String, dynamic>;
    return prompt.entries
        .where((e) => e.value is Map && e.value['class_type'] == classType)
        .map((e) => e.key)
        .toList();
  }

  /// 获取指定 class_type 的节点
  Map<String, dynamic>? getNodeByClassType(String classType) {
    var prompt = workflow['prompt'] as Map<String, dynamic>;
    final entry = prompt.entries.firstWhereOrNull(
      (e) => e.value is Map && e.value['class_type'] == classType,
    );
    return entry?.value as Map<String, dynamic>?;
  }

  /// 获取 workflow 中所有的 class_type
  Set<String> getAllClassTypes() {
    var prompt = workflow['prompt'] as Map<String, dynamic>;
    return prompt.entries
        .where((e) => e.value is Map && e.value['class_type'] != null)
        .map((e) => e.value['class_type'] as String)
        .toSet();
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
    // DanbooruTagsTransformerGenerateAdvanced - seed for tag generation
    var tagNode = getNodeByClassType('DanbooruTagsTransformerGenerateAdvanced');
    if (tagNode != null) {
      (tagNode['inputs'] as Map<String, dynamic>)['seed'] = Random().nextInt(
        1 << 32,
      );
    }
    tagNode = getNodeByClassType('DanbooruTagsTransformerGenerate');
    if (tagNode != null) {
      (tagNode['inputs'] as Map<String, dynamic>)['seed'] = Random().nextInt(
        1 << 32,
      );
    }
    // KSampler - seed for image generation
    final ksamplerNode = getNodeByClassType('KSampler');
    if (ksamplerNode != null) {
      (ksamplerNode['inputs'] as Map<String, dynamic>)['seed'] = Random()
          .nextInt64();
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '${config.address}/prompt',
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
      '${config.address}/view?$urlValues',
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
      '${config.address}/history/$promptId',
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
        '${config.address}/free',
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
