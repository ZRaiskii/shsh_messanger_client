import 'package:flutter/material.dart';

class ChatListTypeSelector extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const ChatListTypeSelector({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey[700],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: CustomPaint(
              size: Size(double.infinity, 100), // Adjust the size as needed
              painter:
                  ChatListPainter(linesCount: title == 'Трёхстрочный' ? 3 : 2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class ChatListPainter extends CustomPainter {
  final int linesCount;

  ChatListPainter({required this.linesCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final circlePaint = Paint()..color = Colors.white.withOpacity(0.5);

    final circleRadius = 8.0;
    final lineSpacing = size.height / (linesCount + 1);

    for (int i = 0; i < linesCount; i++) {
      final y = (i + 1) * lineSpacing;
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);

      canvas.drawCircle(Offset(16, y), circleRadius, circlePaint);
      if (linesCount == 3 && i == 1) {
        canvas.drawCircle(
            Offset(size.width - 16, y), circleRadius, circlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
