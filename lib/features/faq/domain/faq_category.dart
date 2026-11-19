import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';

/// One question shown in an expandable tile.
class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// Keeps the API order. Category is not shown.
List<FaqItem> faqItemsInOrder(List<LoFaqDto> faqs) {
  final items = <FaqItem>[];
  for (final faq in faqs) {
    final question = faq.question.trim();
    if (question.isEmpty) continue;
    items.add(FaqItem(question: question, answer: faq.answer));
  }
  return items;
}
