class ListingCardModel {
  final String title;
  final String productId;
  final String category;
  final String condition;
  final bool availability;
  final String distance;
  final double rating;
  final String? imageUrl;

  ListingCardModel({
    required this.title,
    required this.productId,
    required this.category,
    required this.condition,
    required this.availability,
    required this.distance,
    required this.rating,
    this.imageUrl,
  });

  factory ListingCardModel.fromJson(Map<String, dynamic> json) {
    return ListingCardModel(
      title: json['title'] ?? '',
      productId: json['productId'] ?? '',
      category: json['category'] ?? '',
      condition: json['condition'] ?? 'New',
      availability: json['availability'] ?? true,
      distance: json['distance'] ?? 'Unknown distance',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      imageUrl: json['imageUrl'],
    );
  }
}

class RecommendationCardModel {
  final String title;
  final String category;
  final double rating;
  final String distance;
  final bool availability;
  final String? imageUrl;
  final String productId;

  RecommendationCardModel({
    required this.title,
    required this.category,
    required this.rating,
    required this.distance,
    required this.availability,
    required this.productId,
    this.imageUrl,
  });

  factory RecommendationCardModel.fromJson(Map<String, dynamic> json) {
    return RecommendationCardModel(
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      distance: json['distance'] ?? 'Unknown distance',
      availability: json['availability'] ?? true,
      productId: json['productId'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}

class ComparisonItemModel {
  final String title;
  final String condition;
  final String distance;
  final double rating;
  final bool availability;
  final String category;
  final List<String> advantages;
  final List<String> disadvantages;
  final String productId;

  ComparisonItemModel({
    required this.title,
    required this.condition,
    required this.distance,
    required this.rating,
    required this.availability,
    required this.category,
    required this.advantages,
    required this.disadvantages,
    required this.productId,
  });

  factory ComparisonItemModel.fromJson(Map<String, dynamic> json) {
    return ComparisonItemModel(
      title: json['title'] ?? '',
      condition: json['condition'] ?? 'New',
      distance: json['distance'] ?? 'Unknown distance',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      availability: json['availability'] ?? true,
      category: json['category'] ?? '',
      advantages: List<String>.from(json['advantages'] ?? []),
      disadvantages: List<String>.from(json['disadvantages'] ?? []),
      productId: json['productId'] ?? '',
    );
  }
}

class ComparisonCardModel {
  final ComparisonItemModel item1;
  final ComparisonItemModel item2;

  ComparisonCardModel({
    required this.item1,
    required this.item2,
  });

  factory ComparisonCardModel.fromJson(Map<String, dynamic> json) {
    return ComparisonCardModel(
      item1: ComparisonItemModel.fromJson(json['item1'] ?? {}),
      item2: ComparisonItemModel.fromJson(json['item2'] ?? {}),
    );
  }
}

class BookSummaryCardModel {
  final String title;
  final String summary;
  final String difficultyLevel;
  final String recommendedFor;
  final String borrowRecommendation;
  final String? coverUrl;
  final String productId;

  BookSummaryCardModel({
    required this.title,
    required this.summary,
    required this.difficultyLevel,
    required this.recommendedFor,
    required this.borrowRecommendation,
    required this.productId,
    this.coverUrl,
  });

  factory BookSummaryCardModel.fromJson(Map<String, dynamic> json) {
    return BookSummaryCardModel(
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      difficultyLevel: json['difficultyLevel'] ?? 'Medium',
      recommendedFor: json['recommendedFor'] ?? 'General Readers',
      borrowRecommendation: json['borrowRecommendation'] ?? 'Highly Recommended',
      productId: json['productId'] ?? '',
      coverUrl: json['coverUrl'],
    );
  }
}

class SafetyCardModel {
  final String safetyLevel; // Low / Medium / High Risk
  final List<String> requiredPrecautions;
  final List<String> recommendedPPE;
  final List<String> inspectionChecklist;
  final List<String> warnings;
  final String category;

  SafetyCardModel({
    required this.safetyLevel,
    required this.requiredPrecautions,
    required this.recommendedPPE,
    required this.inspectionChecklist,
    required this.warnings,
    required this.category,
  });

  factory SafetyCardModel.fromJson(Map<String, dynamic> json) {
    return SafetyCardModel(
      safetyLevel: json['safetyLevel'] ?? 'Standard Risk',
      requiredPrecautions: List<String>.from(json['requiredPrecautions'] ?? []),
      recommendedPPE: List<String>.from(json['recommendedPPE'] ?? []),
      inspectionChecklist: List<String>.from(json['inspectionChecklist'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      category: json['category'] ?? '',
    );
  }
}

class RelatedListingItem {
  final String title;
  final String distance;
  final double rating;
  final String productId;
  final String? imageUrl;

  RelatedListingItem({
    required this.title,
    required this.distance,
    required this.rating,
    required this.productId,
    this.imageUrl,
  });

  factory RelatedListingItem.fromJson(Map<String, dynamic> json) {
    return RelatedListingItem(
      title: json['title'] ?? '',
      distance: json['distance'] ?? 'Unknown distance',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      productId: json['productId'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}

class RelatedListingsCardModel {
  final List<RelatedListingItem> items;

  RelatedListingsCardModel({required this.items});

  factory RelatedListingsCardModel.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return RelatedListingsCardModel(
      items: list.map((item) => RelatedListingItem.fromJson(item)).toList(),
    );
  }
}

class ActionItem {
  final String label;
  final String actionType; // follow_up, compare, search_similar, attach, copy, share
  final String payload;

  ActionItem({
    required this.label,
    required this.actionType,
    required this.payload,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      label: json['label'] ?? '',
      actionType: json['actionType'] ?? 'follow_up',
      payload: json['payload'] ?? '',
    );
  }
}

class ActionCardModel {
  final List<ActionItem> actions;

  ActionCardModel({required this.actions});

  factory ActionCardModel.fromJson(Map<String, dynamic> json) {
    final list = json['actions'] as List? ?? [];
    return ActionCardModel(
      actions: list.map((item) => ActionItem.fromJson(item)).toList(),
    );
  }
}

enum AiCardType {
  listing,
  recommendation,
  comparison,
  bookSummary,
  safety,
  relatedListings,
  action,
  none,
}

class StructuredAiResponse {
  final String messageText;
  final AiCardType cardType;
  final dynamic cardData;

  StructuredAiResponse({
    required this.messageText,
    required this.cardType,
    this.cardData,
  });
}
