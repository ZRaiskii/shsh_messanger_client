import 'package:flutter/material.dart';
import 'dart:math';

class NewYearSnowfall extends StatefulWidget {
  final Widget child;
  final String animationType;
  final bool isPlaying;

  const NewYearSnowfall({
    super.key,
    required this.child,
    required this.animationType,
    required this.isPlaying,
  });

  @override
  _NewYearSnowfallState createState() => _NewYearSnowfallState();
}

class _NewYearSnowfallState extends State<NewYearSnowfall>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Snowflake> _snowflakes = [];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..repeat();
  }

  @override
  void didUpdateWidget(NewYearSnowfall oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  void stopAnimation() {
    _controller.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _generateSnowflakes();
  }

  void _generateSnowflakes() {
    _snowflakes.clear();
    for (int i = 0; i < 50; i++) {
      _snowflakes.add(Snowflake(
        position: Offset(
            Random().nextDouble() * MediaQuery.of(context).size.width, 0),
        speed: Random().nextDouble() * 2 + 1,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: SnowfallPainter(
                    _snowflakes, _controller.value, widget.animationType),
              );
            },
          ),
        ),
      ],
    );
  }
}

class Snowflake {
  Offset position;
  final double speed;

  Snowflake({required this.position, required this.speed});
}

class SnowfallPainter extends CustomPainter {
  final List<Snowflake> snowflakes;
  final double animationValue;
  final String animationType;

  SnowfallPainter(this.snowflakes, this.animationValue, this.animationType);

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.black // Цвет обводки
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.white // Цвет заливки
      ..style = PaintingStyle.fill;

    for (var snowflake in snowflakes) {
      final newPosition = Offset(
        snowflake.position.dx,
        snowflake.position.dy + snowflake.speed * animationValue,
      );
      if (newPosition.dy > size.height) {
        snowflake.position = Offset(Random().nextDouble() * size.width, 0);
      } else {
        snowflake.position = newPosition;
      }

      switch (animationType) {
        case "snowflakes":
          _drawSnowflake(canvas, snowflake.position, strokePaint, fillPaint);
          break;
        case "hearts":
          _drawHeart(canvas, snowflake.position, strokePaint, fillPaint);
          break;
        case "smileys":
          _drawSmiley(canvas, snowflake.position, strokePaint, fillPaint);
          break;
        default:
          _drawSnowflake(canvas, snowflake.position, strokePaint, fillPaint);
      }
    }
  }

  void _drawSnowflake(
      Canvas canvas, Offset position, Paint strokePaint, Paint fillPaint) {
    const radius = 5.0;
    final center = position;

    // Draw the main lines of the snowflake with stroke
    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * pi) / 6;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), strokePaint);
    }

    // Draw the smaller lines of the snowflake with stroke
    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * pi) / 6;
      final x = center.dx + (radius / 2) * cos(angle);
      final y = center.dy + (radius / 2) * sin(angle);
      canvas.drawLine(center, Offset(x, y), strokePaint);
    }

    // Fill the center of the snowflake
    canvas.drawCircle(center, radius / 4, fillPaint);
  }

  void _drawHeart(
      Canvas canvas, Offset position, Paint strokePaint, Paint fillPaint) {
    final path = Path();
    const size = 10.0;
    final center = position;

    // Draw a heart shape
    path.moveTo(center.dx, center.dy + size / 4);
    path.cubicTo(
      center.dx - size / 2,
      center.dy - size / 2,
      center.dx - size,
      center.dy + size / 4,
      center.dx,
      center.dy + size,
    );
    path.cubicTo(
      center.dx + size,
      center.dy + size / 4,
      center.dx + size / 2,
      center.dy - size / 2,
      center.dx,
      center.dy + size / 4,
    );

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawSmiley(
      Canvas canvas, Offset position, Paint strokePaint, Paint fillPaint) {
    const radius = 5.0;
    final center = position;

    // Draw the face
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, strokePaint);

    // Draw the eyes
    final leftEye = Offset(center.dx - radius / 2, center.dy - radius / 2);
    final rightEye = Offset(center.dx + radius / 2, center.dy - radius / 2);
    canvas.drawCircle(leftEye, radius / 4, strokePaint);
    canvas.drawCircle(rightEye, radius / 4, strokePaint);

    // Draw the smile
    final smilePath = Path();
    smilePath.moveTo(center.dx - radius / 2, center.dy + radius / 2);
    smilePath.quadraticBezierTo(
      center.dx,
      center.dy + radius,
      center.dx + radius / 2,
      center.dy + radius / 2,
    );
    canvas.drawPath(smilePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
