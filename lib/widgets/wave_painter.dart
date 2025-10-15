import 'package:flutter/material.dart';

// 상단 웨이브 디자인을 위한 CustomPainter
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFFF8126)
      ..style = PaintingStyle.fill;
    
    final paint2 = Paint()
      ..color = const Color(0xFFFF8126)
      ..style = PaintingStyle.fill;

    // 첫 번째 웨이브 (진한 오렌지) - 더 부드러운 곡선
    final path1 = Path();
    path1.lineTo(0, size.height * 0.6);
    path1.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.4,
      size.width * 0.4,
      size.height * 0.5,
    );
    path1.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.6,
      size.width * 0.8,
      size.height * 0.45,
    );
    path1.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.35,
      size.width,
      size.height * 0.4,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // 두 번째 웨이브 (연한 오렌지) - 구름 모양
    final path2 = Path();
    path2.lineTo(0, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.6,
      size.width * 0.3,
      size.height * 0.7,
    );
    path2.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width * 0.7,
      size.height * 0.6,
    );
    path2.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.4,
      size.width,
      size.height * 0.5,
    );
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
