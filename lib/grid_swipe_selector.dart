import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'card_selector.dart';

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
