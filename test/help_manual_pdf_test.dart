import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Help user manual downloads as a PDF', () async {
    final bytes = await buildHelpManualPdf();
    expect(bytes.length, greaterThan(2000));
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
