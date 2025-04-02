import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Отдельный StatefulWidget для Lottie-анимации
class ReusableLottie extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;

  const ReusableLottie({
    required this.assetPath,
    this.width = 100,
    this.height = 100,
    Key? key,
  }) : super(key: key);

  @override
  _ReusableLottieState createState() => _ReusableLottieState();
}

class _ReusableLottieState extends State<ReusableLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    _controller.reset();
    await _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Lottie.asset(
        widget.assetPath,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        controller: _controller,
        onLoaded: (composition) {
          // Устанавливаем длительность анимации
          _controller.duration = composition.duration;
        },
      ),
    );
  }
}
