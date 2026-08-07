import 'book_model.dart';
import 'marketplace_equipment_model.dart';

enum SearchResultType {
  book,
  equipment,
}

class SearchResultModel {
  final String id;
  final SearchResultType type;
  final String title;
  final String category;
  final String imageUrl;
  final double relevanceScore;
  final BookModel? book;
  final MarketplaceEquipmentModel? equipment;

  SearchResultModel({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.relevanceScore,
    this.book,
    this.equipment,
  });

  factory SearchResultModel.fromBook(BookModel book, double score) {
    return SearchResultModel(
      id: book.bookId,
      type: SearchResultType.book,
      title: book.title,
      category: book.category,
      imageUrl: book.coverImage,
      relevanceScore: score,
      book: book,
    );
  }

  factory SearchResultModel.fromEquipment(MarketplaceEquipmentModel equip, double score) {
    return SearchResultModel(
      id: equip.equipmentId,
      type: SearchResultType.equipment,
      title: equip.equipmentName,
      category: equip.category,
      imageUrl: equip.imageUrls.isNotEmpty ? equip.imageUrls.first : '',
      relevanceScore: score,
      equipment: equip,
    );
  }
}
