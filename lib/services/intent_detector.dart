enum AiUserIntent {
  recommendation,
  comparison,
  explanation,
  safety,
  summary,
  inspection,
  borrowAdvice,
  search,
  general,
}

class IntentDetector {
  IntentDetector._();
  static final IntentDetector instance = IntentDetector._();

  /// Classifies a user query into a core intent.
  AiUserIntent detectIntent(String query) {
    final lower = query.trim().toLowerCase();

    // 1. Comparison
    if (lower.contains('compare') ||
        lower.contains('versus') ||
        lower.contains(' vs ') ||
        lower.contains('difference between') ||
        lower.contains('better than') ||
        lower.contains('alternative')) {
      return AiUserIntent.comparison;
    }

    // 2. Summary
    if (lower.contains('summarize') ||
        lower.contains('summary') ||
        lower.contains('outline') ||
        lower.contains('overview of') ||
        lower.contains('briefly explain') ||
        lower.contains('what is this about')) {
      return AiUserIntent.summary;
    }

    // 3. Safety
    if (lower.contains('safety') ||
        lower.contains('safe') ||
        lower.contains('precaution') ||
        lower.contains('danger') ||
        lower.contains('hazard') ||
        lower.contains('protective') ||
        lower.contains('warning')) {
      return AiUserIntent.safety;
    }

    // 4. Inspection
    if (lower.contains('inspect') ||
        lower.contains('checklist') ||
        lower.contains('check before') ||
        lower.contains('damage') ||
        lower.contains('condition') ||
        lower.contains('verify') ||
        lower.contains('what to check')) {
      return AiUserIntent.inspection;
    }

    // 5. Recommendation
    if (lower.contains('recommend') ||
        lower.contains('suggest') ||
        lower.contains('similar') ||
        lower.contains('like this') ||
        lower.contains('other option') ||
        lower.contains('related')) {
      return AiUserIntent.recommendation;
    }

    // 6. Borrow Advice
    if (lower.contains('borrow') ||
        lower.contains('rent') ||
        lower.contains('lend') ||
        lower.contains('duration') ||
        lower.contains('cost') ||
        lower.contains('price') ||
        lower.contains('deposit') ||
        lower.contains('suitable for')) {
      return AiUserIntent.borrowAdvice;
    }

    // 7. Search
    if (lower.contains('search') ||
        lower.contains('find') ||
        lower.contains('locate') ||
        lower.contains('where can i') ||
        lower.contains('closest') ||
        lower.contains('near me')) {
      return AiUserIntent.search;
    }

    // 8. Explanation
    if (lower.contains('how to') ||
        lower.contains('use') ||
        lower.contains('operate') ||
        lower.contains('explain') ||
        lower.contains('guide') ||
        lower.contains('tutorial') ||
        lower.contains('work')) {
      return AiUserIntent.explanation;
    }

    // 9. General Question
    return AiUserIntent.general;
  }
}
