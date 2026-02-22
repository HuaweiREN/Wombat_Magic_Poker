import 'dart:async';
// import 'dart:io';
import 'dart:math';
// import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:sherpa_onnx/sherpa_onnx.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'card_selector.dart';

/// 语音命令选择器（使用 sherpa-onnx + flutter_sound）
/*
class VoiceCommandCardSelector implements CardSelector {
  // sherpa-onnx 识别器
  OnlineRecognizer? _recognizer;
  OnlineStream? _stream;

  // 录音相关
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  StreamController<Uint8List>? _audioController;
  StreamSubscription<Uint8List>? _audioSubscription;

  // 识别结果
  String _lastWords = '';
  int? _lastVoiceRank;
  int? _lastVoiceSuit;

  // 模型文件在 assets 中的路径（保持不变）
  static const List<String> _assetModelFiles = [
    'assets/models/encoder-epoch-99-avg-1.onnx',
    'assets/models/decoder-epoch-99-avg-1.onnx',
    'assets/models/joiner-epoch-99-avg-1.onnx',
    'assets/models/tokens.txt',
  ];

  // 复制后的目标文件路径（在应用文档目录下）
  late String _encoderPath;
  late String _decoderPath;
  late String _joinerPath;
  late String _tokensPath;

  // 外部传入的 setState 回调
  final void Function(VoidCallback) setState;

  VoiceCommandCardSelector({required this.setState});

  @override
  Widget buildSelector({
    required BuildContext context,
    required void Function(int rank, int? suit) onCardSelected,
    required VoidCallback onRequestBack,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRecognizer(onCardSelected);
    });

    return GestureDetector(
      onTap: () {
        if (_lastVoiceRank != null) {
          onCardSelected(_lastVoiceRank!, _lastVoiceSuit);
          _lastVoiceRank = null;
          _lastVoiceSuit = null;
          setState(() => _lastWords = '');
        }
      },
      onLongPress: onRequestBack,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_recognizer == null)
                const Text(
                  '正在加载语音模型...\n首次使用需等待几秒',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                )
              else if (!_isRecording)
                const Text(
                  '准备就绪，开始说话吧',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                )
              else
                Text(
                  _lastWords.isEmpty ? '正在聆听...' : '识别到: $_lastWords',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initRecognizer(
    void Function(int rank, int? suit) onCardSelected,
  ) async {
    try {
      print("开始初始化 sherpa-onnx 识别器...");

      // 获取应用文档目录并设置目标路径
      final dir = await getApplicationDocumentsDirectory();
      final targetDir = dir.path;
      _encoderPath = '$targetDir/encoder-epoch-99-avg-1.onnx';
      _decoderPath = '$targetDir/decoder-epoch-99-avg-1.onnx';
      _joinerPath = '$targetDir/joiner-epoch-99-avg-1.onnx';
      _tokensPath = '$targetDir/tokens.txt';

      // 复制模型文件（如果不存在）
      await _copyModelsIfNeeded(targetDir);

      // 检查复制后的文件是否存在
      if (!File(_encoderPath).existsSync()) {
        setState(() => _lastWords = '模型文件复制失败: encoder');
        return;
      }
      if (!File(_decoderPath).existsSync()) {
        setState(() => _lastWords = '模型文件复制失败: decoder');
        return;
      }
      if (!File(_joinerPath).existsSync()) {
        setState(() => _lastWords = '模型文件复制失败: joiner');
        return;
      }
      if (!File(_tokensPath).existsSync()) {
        setState(() => _lastWords = '模型文件复制失败: tokens');
        return;
      }

      print("模型文件检查通过，开始配置识别器...");

      final config = OnlineRecognizerConfig(
        feat: FeatureConfig(sampleRate: 16000, featureDim: 80),
        model: OnlineModelConfig(
          transducer: OnlineTransducerModelConfig(
            encoder: _encoderPath,
            decoder: _decoderPath,
            joiner: _joinerPath,
          ),
          tokens: _tokensPath,
          numThreads: 2,
          debug: false,
        ),
        decodingMethod: 'greedy_search',
        maxActivePaths: 4,
      );

      _recognizer = OnlineRecognizer(config);
      print("识别器创建成功，开始监听...");
      await _startListening(onCardSelected);
    } catch (e) {
      print('初始化 sherpa-onnx 失败: $e');
      print('堆栈: ${StackTrace.current}');
      setState(() => _lastWords = '语音引擎初始化失败: $e');
    }
  }

  // 复制模型文件（如果不存在）
  Future<void> _copyModelsIfNeeded(String targetDir) async {
    for (String assetPath in _assetModelFiles) {
      final fileName = assetPath.split('/').last;
      final targetFile = File('$targetDir/$fileName');

      if (!await targetFile.exists()) {
        setState(() => _lastWords = '正在复制模型文件: $fileName...');
        print("复制模型文件: $fileName");

        try {
          // 从 assets 加载
          final byteData = await rootBundle.load(assetPath);
          final buffer = byteData.buffer;
          await targetFile.writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          );
          print("完成复制: $fileName");
        } catch (e) {
          print("复制 $fileName 失败: $e");
          rethrow;
        }
      } else {
        print("模型文件已存在: $fileName");
      }
    }
    setState(() => _lastWords = '模型文件准备就绪');
    print("所有模型文件已就绪");
  }

  Future<void> _startListening(
    void Function(int rank, int? suit) onCardSelected,
  ) async {
    if (_isRecording) return;

    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _lastWords = '需要麦克风权限');
      return;
    }

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();

    _audioController = StreamController<Uint8List>();

    await _recorder!.startRecorder(
      toStream: _audioController!.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );

    _audioSubscription = _audioController!.stream.listen((Uint8List data) {
      Float32List samples = _convertUint8ToFloat32(data);
      _processAudio(samples, onCardSelected);
    }, onError: (error) => print('音频流错误: $error'));

    _isRecording = true;
    setState(() {});
  }

  Float32List _convertUint8ToFloat32(Uint8List data) {
    int length = data.length ~/ 2;
    var samples = Float32List(length);
    for (int i = 0; i < length; i++) {
      int low = data[i * 2];
      int high = data[i * 2 + 1];
      int val = (high << 8) | low;
      if (val > 32767) val -= 65536;
      samples[i] = val / 32768.0;
    }
    return samples;
  }

  // 修正后的音频处理方法
  void _processAudio(
    Float32List samples,
    void Function(int rank, int? suit) onCardSelected,
  ) {
    if (!_isRecording || _recognizer == null) return;

    // 确保流存在
    _stream ??= _recognizer!.createStream();

    // 将音频数据送入流（需要同时提供 sampleRate）
    _stream!.acceptWaveform(samples: samples, sampleRate: 16000);

    // 尝试解码（根据常见 API，可能不需要显式检查就绪状态）
    // 如果下面方法报错，可尝试其他名称，如 decodeStream、process 等
    try {
      _recognizer!.decode(_stream!);
    } catch (e) {
      // 如果 decode 不存在，尝试 decodeOnlineStream（但之前报错未定义）
      // 或者忽略，直接获取结果（可能自动解码）
    }

    // 获取识别结果
    final result = _recognizer!.getResult(_stream!);
    // result 可能有 text 属性
    final String text = result.text; // 假设存在
    if (text.isNotEmpty) {
      setState(() => _lastWords = text);
      _parseCommand(text, onCardSelected);
    }
  }

  void _parseCommand(
    String text,
    void Function(int rank, int? suit) onCardSelected,
  ) {
    const suits = {'黑桃': 0, '红桃': 1, '梅花': 2, '方块': 3, '方片': 3};
    const ranks = {
      'a': 1,
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      '6': 6,
      '7': 7,
      '8': 8,
      '9': 9,
      '10': 10,
      'j': 11,
      'q': 12,
      'k': 13,
      '大王': 15,
      '小王': 14,
    };

    String lowerText = text.toLowerCase();

    if (lowerText.contains('大王')) {
      _lastVoiceRank = 15;
      _lastVoiceSuit = null;
      return;
    }
    if (lowerText.contains('小王')) {
      _lastVoiceRank = 14;
      _lastVoiceSuit = null;
      return;
    }

    int? suit;
    String? matchedSuitKey;
    for (var entry in suits.entries) {
      if (lowerText.contains(entry.key.toLowerCase())) {
        suit = entry.value;
        matchedSuitKey = entry.key;
        break;
      }
    }
    if (suit == null) return;

    String afterSuit = text
        .substring(text.indexOf(matchedSuitKey!) + matchedSuitKey.length)
        .trim()
        .toLowerCase();

    for (var entry in ranks.entries) {
      if (afterSuit.contains(entry.key)) {
        _lastVoiceRank = entry.value;
        _lastVoiceSuit = suit;
        return;
      }
    }
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioController?.close();
    _isRecording = false;
    _recorder?.stopRecorder();
    _recorder?.closeRecorder();
    _stream?.free();
    _recognizer?.free();
  }
}
*/

/// 随机点击选择器：点击屏幕任意位置随机选一张牌（包括大小王）
/*
class RandomTapCardSelector implements CardSelector {
  final Random _random = Random();

  @override
  Widget buildSelector({
    required BuildContext context,
    required void Function(int rank, int? suit) onCardSelected,
    required VoidCallback onRequestBack,
  }) {
    return GestureDetector(
      onTap: () {
        // 随机生成 rank 1-15
        int rank = _random.nextInt(15) + 1;
        int? suit;

        // 如果是普通牌（1-13），随机生成花色（0-3）
        if (rank <= 13) {
          suit = _random.nextInt(4);
        } else {
          suit = null; // 大小王无花色
        }

        onCardSelected(rank, suit);
      },
      onLongPress: onRequestBack, // 长按返回待机
      child: Container(
        color: Colors.black,
        // 如果想显示提示文字，可保留以下 Center；若希望完全黑屏，请替换为 Container(color: Colors.black)
        child: const Center(
          child: Text(
            '点击屏幕随机选牌\n长按返回待机',
            style: TextStyle(color: Colors.white, fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 没有资源需要释放
  }
}
*/

/// 默认的基于网格和滑动的选择器（3x5网格 + 方向判断）
class GridSwipeCardSelector implements CardSelector {
  // 触摸追踪相关
  int? _activePointerId;
  Offset? _downPosition;
  Offset? _lastPosition;
  Timer? _directionTimer;
  bool _isProcessed = false;
  Size? _screenSize;

  static const double minSwipeDistance = 8.0;

  @override
  Widget buildSelector({
    required BuildContext context,
    required void Function(int rank, int? suit) onCardSelected,
    required VoidCallback onRequestBack,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_activePointerId != null) return; // 只追踪一个手指

        final size = MediaQuery.of(context).size;
        _activePointerId = event.pointer;
        _downPosition = event.position;
        _lastPosition = event.position;
        _screenSize = size;
        _isProcessed = false;

        _directionTimer?.cancel();
        _directionTimer = Timer(const Duration(milliseconds: 500), () {
          if (!_isProcessed && mounted(context)) {
            _resolveCard(onCardSelected);
          }
          _directionTimer = null;
        });
      },
      onPointerMove: (event) {
        if (event.pointer != _activePointerId) return;
        if (_isProcessed) return;
        _lastPosition = event.position;
      },
      onPointerUp: (event) {
        if (event.pointer != _activePointerId) return;
        if (_isProcessed) {
          _resetTracking();
          return;
        }
        _directionTimer?.cancel();
        _directionTimer = null;
        _resolveCard(onCardSelected);
        _resetTracking();
      },
      onPointerCancel: (event) {
        if (event.pointer == _activePointerId) {
          _resetTracking();
        }
      },
      child: Container(color: Colors.black),
    );
  }

  // 根据起始点位置计算牌面数字 (1~15)
  int _calculateRank(Offset position, Size screenSize) {
    double cellWidth = screenSize.width / 3;
    double cellHeight = screenSize.height / 5;

    int col = (position.dx / cellWidth).floor().clamp(0, 2);
    int row = (position.dy / cellHeight).floor().clamp(0, 4);

    return row * 3 + col + 1;
  }

  // 根据位移向量计算花色 (0: 黑桃, 1: 红桃, 2: 梅花, 3: 方块)
  int? _calculateSuit(Offset delta) {
    double distance = delta.distance;
    if (distance < minSwipeDistance) return null;

    double angleRad = atan2(delta.dx, -delta.dy);
    double angleDeg = (angleRad * 180 / pi + 360) % 360;

    if (angleDeg < 90) return 0;
    if (angleDeg < 180) return 1;
    if (angleDeg < 270) return 2;
    return 3;
  }

  void _resolveCard(void Function(int, int?) onCardSelected) {
    if (_isProcessed) return;
    if (_downPosition == null || _lastPosition == null || _screenSize == null)
      return;

    int rank = _calculateRank(_downPosition!, _screenSize!);
    Offset delta = _lastPosition! - _downPosition!;
    int? suit = _calculateSuit(delta);

    // 如果滑动距离过小导致无花色，且数字是普通牌（1-13），则此次操作无效
    if (suit == null && rank <= 13) {
      _resetTracking();
      return;
    }

    onCardSelected(rank, suit);
    _isProcessed = true;
    _resetTracking();
  }

  void _resetTracking() {
    _directionTimer?.cancel();
    _directionTimer = null;
    _activePointerId = null;
    _downPosition = null;
    _lastPosition = null;
    _screenSize = null;
    _isProcessed = false;
  }

  // 辅助方法：检查当前 context 是否仍然 mounted (Flutter 3.7+)
  bool mounted(BuildContext context) => context.mounted;

  @override
  void dispose() {
    _directionTimer?.cancel();
  }
}
