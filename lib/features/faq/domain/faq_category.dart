/// One question inside an FAQ category tab.
class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// Website category. [title] is the tab label (`question` on the API).
class FaqCategory {
  const FaqCategory({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<FaqItem> items;

  /// Parses the guest FAQ payload: `{ data: [ { question, subFaq, active } ] }`.
  static List<FaqCategory> parse(dynamic body) {
    final rows = _rows(body);
    final categories = <FaqCategory>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row['active'] == false) continue;
      final title = _text(row['question']);
      if (title.isEmpty) continue;
      final items = _items(row['subFaq']);
      categories.add(
        FaqCategory(
          id: _text(row['id']).isEmpty ? '$i' : _text(row['id']),
          title: title,
          items: items,
        ),
      );
    }
    return categories;
  }

  static List<Map<String, dynamic>> _rows(dynamic body) {
    if (body is List) return _maps(body);
    if (body is Map) {
      final data = body['data'];
      if (data is List) return _maps(data);
      if (data is Map && data['question'] != null) {
        return [Map<String, dynamic>.from(data)];
      }
    }
    return const [];
  }

  static List<Map<String, dynamic>> _maps(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static List<FaqItem> _items(dynamic raw) {
    if (raw is! List) return const [];
    final items = <FaqItem>[];
    for (final entry in raw.whereType<Map>()) {
      final question = readableFaqText(_text(entry['question']));
      if (question.isEmpty) continue;
      items.add(
        FaqItem(
          question: question,
          answer: readableFaqText(_text(entry['answer'])),
        ),
      );
    }
    return items;
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';
}

/// Turns CMS text into plain copy: tags out, entities decoded.
String readableFaqText(String raw) {
  var text = raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  text = text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ');
  text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.tryParse(match.group(1)!);
    if (code == null || code <= 0 || code > 0x10FFFF) return match.group(0)!;
    return String.fromCharCode(code);
  });
  return text
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
