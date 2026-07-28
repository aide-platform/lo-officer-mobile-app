import 'dart:math';

import 'package:flutter/material.dart';

class CaptchaPainter extends CustomPainter {
  final String captcha;
  final double difficulty;
  late final Random _random;

  CaptchaPainter(this.captcha, {this.difficulty = 1.0})
      : _random = Random(captcha.hashCode ^ difficulty.hashCode);

  static const _fonts = [
    'Roboto',
    'Courier',
    'Arial',
    'Times New Roman',
    'Georgia',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final scale = (size.height / 44).clamp(0.7, 1.2);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black,
          Colors.deepPurple.shade800,
          Colors.indigo.shade900,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final noiseCount = (200 * difficulty * scale).toInt().clamp(40, 200);
    for (int i = 0; i < noiseCount; i++) {
      canvas.drawCircle(
        Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        _random.nextDouble() * 2.2 * scale,
        Paint()
          ..color = Colors.white.withValues(alpha: _random.nextDouble() * 0.3),
      );
    }

    for (int i = 0; i < (5 * difficulty).ceil(); i++) {
      final path = Path()..moveTo(0, _random.nextDouble() * size.height);
      for (double x = 0; x <= size.width; x += 5) {
        path.lineTo(
          x,
          size.height / 2 +
              sin(x / (12 + _random.nextInt(10))) *
                  (size.height * 0.22) *
                  difficulty,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    final fontSize = (size.height * 0.55).clamp(12.0, 18.0);
    final step = size.width / (captcha.length + 0.5);
    var xOffset = step * 0.25;

    for (int i = 0; i < captcha.length; i++) {
      canvas.save();

      canvas.translate(
        xOffset,
        size.height / 2 +
            (_random.nextDouble() - 0.5) * size.height * 0.25 * difficulty,
      );
      canvas.rotate((_random.nextDouble() - 0.5) * 1.2 * difficulty);

      final textPainter = TextPainter(
        text: TextSpan(
          text: captcha[i],
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            fontFamily: _fonts[_random.nextInt(_fonts.length)],
            color: Colors.white.withValues(
              alpha: 0.85 + _random.nextDouble() * 0.15,
            ),
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(0, -textPainter.height / 2));

      canvas.restore();
      xOffset += step;
    }

    final fgNoise = (120 * difficulty * scale).toInt().clamp(30, 120);
    for (int i = 0; i < fgNoise; i++) {
      canvas.drawCircle(
        Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        _random.nextDouble() * 3.2 * scale,
        Paint()
          ..color = Colors.white.withValues(alpha: _random.nextDouble() * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CaptchaPainter oldDelegate) {
    return oldDelegate.captcha != captcha ||
        oldDelegate.difficulty != difficulty;
  }
}
