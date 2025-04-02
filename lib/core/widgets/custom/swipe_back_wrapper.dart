import 'package:flutter/material.dart';
import '../../utils/gesture_manager.dart';

class SwipeBackWrapper extends StatefulWidget {
  final Widget child;

  const SwipeBackWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _SwipeBackWrapperState createState() => _SwipeBackWrapperState();
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragStartX = 0.0;
  bool _isSwiping = false;
  double _dragExtent = 0.0; // Текущее смещение
  final double _dragThreshold = 50.0; // Минимальное расстояние для активации

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0), // Анимация вправо
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _dragStartX = event.position.dx;
    _isSwiping = true;
    _dragExtent = 0.0; // Сбрасываем текущее смещение
    GestureManager.isScreenSwiping.value =
        true; // Устанавливаем флаг свайпа экрана
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isSwiping) return;

    final delta = event.delta.dx;
    final screenWidth = context.size?.width ?? 1.0;

    setState(() {
      _dragExtent += delta;

      // Проверяем, движется ли пользователь обратно вправо
      if (_dragExtent <= 0) {
        GestureManager.isScreenSwiping.value = false; // Сбрасываем флаг
      } else {
        GestureManager.isScreenSwiping.value = true; // Устанавливаем флаг
      }

      // Применяем порог активации
      if (_dragExtent.abs() < _dragThreshold) {
        _controller.value = 0.0; // Не двигаем экран, пока не достигнут порог
      } else {
        // Вычисляем прогресс после достижения порога
        final progress = (_dragExtent - _dragThreshold) / screenWidth;
        _controller.value = progress.clamp(0.0, 1.0);
      }
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    _isSwiping = false;

    // Сбрасываем флаг свайпа экрана
    GestureManager.isScreenSwiping.value = false;

    if (_controller.value > 0.3) {
      _controller.animateTo(1.0).then((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    } else {
      _controller.animateBack(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_controller.isAnimating) {
          await _controller.animateBack(0.0);
          return false;
        }
        return true;
      },
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        child: Stack(
          children: [
            // Фоновый слой для эффекта затемнения
            if (_controller.value > 0)
              Opacity(
                opacity: _controller.value * 0.5,
                child: Container(
                  color: Colors.black,
                ),
              ),
            // Основной контент с анимацией
            SlideTransition(
              position: _slideAnimation,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
