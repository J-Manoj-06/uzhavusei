import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/localized_text.dart';

class BookModel {
  const BookModel({
    required this.bookId,
    required this.title,
    required this.titleLocalized,
    required this.author,
    required this.authors,
    required this.category,
    required this.categoryLocalized,
    required this.description,
    required this.descriptionLocalized,
    required this.isbn,
    required this.coverImage,
    required this.imageUrls,
    required this.publisher,
    required this.publicationYear,
    required this.language,
    required this.totalCopies,
    required this.availableCopies,
    required this.createdAt,
    required this.rating,
    this.department = '',
    this.status = 'Available',
    this.isArchived = false,
  });

  final String bookId;
  final String title;
  final Map<String, String> titleLocalized;
  final String author;
  final List<String> authors;
  final String category;
  final Map<String, String> categoryLocalized;
  final String description;
  final Map<String, String> descriptionLocalized;
  final String isbn;
  final String coverImage;
  final List<String> imageUrls;
  final String publisher;
  final int publicationYear;
  final String language;
  final int totalCopies;
  final int availableCopies;
  final DateTime createdAt;
  final double rating;
  final String department;
  final String status;
  final bool isArchived;

  bool get isValidBook {
    if (isArchived) return false;
    final s = status.trim().toLowerCase();
    if (s == 'archived' || s == 'deleted' || s == 'maintenance' || s == 'out of stock') {
      return false;
    }
    if (s.isNotEmpty && s != 'available' && s != 'published' && s != 'active') {
      return false;
    }
    if (availableCopies <= 0) return false;
    return true;
  }

  String titleForLanguage(String languageCode) =>
      getLocalizedText(titleLocalized, languageCode);

  String categoryForLanguage(String languageCode) =>
      getLocalizedText(categoryLocalized, languageCode);

  String descriptionForLanguage(String languageCode) =>
      getLocalizedText(descriptionLocalized, languageCode);

  factory BookModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final titleLocalized = _parseLocalizedMap(data['titleLocalized'] ?? data['title']);
    final categoryLocalized = _parseLocalizedMap(data['categoryLocalized'] ?? data['category']);
    final descriptionLocalized = _parseLocalizedMap(data['descriptionLocalized'] ?? data['description']);

    final String titleStr = titleLocalized['en']?.isNotEmpty == true
        ? titleLocalized['en']!
        : (data['title'] ?? data['equipmentName'] ?? data['name'] ?? '').toString();

    final String categoryStr = categoryLocalized['en']?.isNotEmpty == true
        ? categoryLocalized['en']!
        : (data['category'] ?? 'Books').toString();

    final String descriptionStr = descriptionLocalized['en']?.isNotEmpty == true
        ? descriptionLocalized['en']!
        : (data['description'] ?? '').toString();

    final List<String> parsedAuthors = [];
    if (data['authors'] is List) {
      parsedAuthors.addAll((data['authors'] as List).map((e) => e.toString()));
    } else if (data['author'] != null) {
      parsedAuthors.add(data['author'].toString());
    }

    final List<String> images = [];
    if (data['imageUrls'] is List) {
      images.addAll((data['imageUrls'] as List).map((e) => e.toString()));
    } else if (data['images'] is List) {
      images.addAll((data['images'] as List).map((e) => e.toString()));
    }

    final String cover = (
      data['coverImage'] ??
      data['cover_image'] ??
      data['coverUrl'] ??
      data['cover_url'] ??
      data['cover'] ??
      data['imageUrl'] ??
      data['image_url'] ??
      data['image'] ??
      data['photoUrl'] ??
      data['photo_url'] ??
      data['thumbnail'] ??
      data['thumbnailUrl'] ??
      data['url'] ??
      (images.isNotEmpty ? images.first : '')
    ).toString().trim();

    if (cover.isNotEmpty && !images.contains(cover)) {
      images.insert(0, cover);
    }

    final String deptStr = (data['department'] ?? data['dept'] ?? data['departmentName'] ?? '').toString();
    final String statusStr = (data['status'] ?? 'Available').toString();
    final bool isArchivedBool = (data['isArchived'] ?? data['archived'] ?? false) == true;

    return BookModel(
      bookId: (data['bookId'] ?? data['id'] ?? doc.id).toString(),
      title: titleStr,
      titleLocalized: titleLocalized,
      author: parsedAuthors.isNotEmpty ? parsedAuthors.join(', ') : (data['author'] ?? 'Unknown Author').toString(),
      authors: parsedAuthors,
      category: categoryStr,
      categoryLocalized: categoryLocalized,
      description: descriptionStr,
      descriptionLocalized: descriptionLocalized,
      isbn: (data['isbn'] ?? data['isbn13'] ?? '').toString(),
      coverImage: cover,
      imageUrls: images,
      publisher: (data['publisher'] ?? '').toString(),
      publicationYear: _toInt(data['publicationYear'] ?? data['year']),
      language: (data['language'] ?? 'en').toString(),
      totalCopies: _toInt(data['totalCopies'] ?? data['copies'] ?? 1),
      availableCopies: _toInt(data['availableCopies'] ?? 1),
      createdAt: _toDate(data['createdAt'] ?? data['created_at']),
      rating: _toDouble(data['rating'] ?? 5.0),
      department: deptStr,
      status: statusStr,
      isArchived: isArchivedBool,
    );
  }
}

class BookCopyModel {
  const BookCopyModel({
    required this.copyId,
    required this.bookId,
    required this.copyNumber,
    required this.barcode,
    required this.rackNumber,
    required this.ownerId,
    required this.ownerName,
    required this.condition,
    required this.status,
    required this.availability,
    required this.price,
    required this.pricePerDay,
    required this.pricePerHour,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.createdAt,
    this.currentBorrowerId,
    this.currentTransactionId,
  });

  final String copyId;
  final String bookId;
  final String copyNumber;
  final String barcode;
  final String rackNumber;
  final String ownerId;
  final String ownerName;
  final String condition;
  final String status;
  final bool availability;
  final double price;
  final double pricePerDay;
  final double pricePerHour;
  final String location;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String? currentBorrowerId;
  final String? currentTransactionId;

  factory BookCopyModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final List<String> images = [];
    if (data['imageUrls'] is List) {
      images.addAll((data['imageUrls'] as List).map((e) => e.toString()));
    } else if (data['images'] is List) {
      images.addAll((data['images'] as List).map((e) => e.toString()));
    }

    final rawPrice = _toDouble(data['price'] ?? data['rentalPrice'] ?? data['pricePerDay']);
    final statusStr = (data['status'] ?? 'published').toString();

    return BookCopyModel(
      copyId: (data['copyId'] ?? data['id'] ?? doc.id).toString(),
      bookId: (data['bookId'] ?? '').toString(),
      copyNumber: (data['copyNumber'] ?? data['copy_number'] ?? doc.id.substring(0, doc.id.length > 6 ? 6 : doc.id.length)).toString(),
      barcode: (data['barcode'] ?? data['qrCode'] ?? data['isbn'] ?? '').toString(),
      rackNumber: (data['rackNumber'] ?? data['rack_number'] ?? data['shelf'] ?? 'Main Rack').toString(),
      ownerId: (data['owner_user_id'] ?? data['ownerId'] ?? data['lenderId'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? data['lenderName'] ?? 'Owner').toString(),
      condition: (data['condition'] ?? 'Good').toString(),
      status: statusStr,
      availability: (data['availability'] as bool?) ?? (statusStr == 'published' || statusStr == 'available'),
      price: rawPrice,
      pricePerDay: rawPrice,
      pricePerHour: rawPrice,
      location: (data['location'] ?? data['city'] ?? '').toString(),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      imageUrls: images,
      createdAt: _toDate(data['createdAt'] ?? data['created_at']),
      currentBorrowerId: data['currentBorrowerId']?.toString(),
      currentTransactionId: data['currentTransactionId']?.toString(),
    );
  }
}

class BookInventoryModel {
  final String bookId;
  final int totalCopies;
  final int availableCopies;
  final int borrowedCopies;
  final int reservedCopies;
  final int damagedCopies;
  final int lostCopies;
  final List<BookCopyModel> copies;

  const BookInventoryModel({
    required this.bookId,
    required this.totalCopies,
    required this.availableCopies,
    required this.borrowedCopies,
    required this.reservedCopies,
    required this.damagedCopies,
    required this.lostCopies,
    required this.copies,
  });

  String get stockStatusBadge {
    if (availableCopies <= 0) return 'Out of Stock';
    if (availableCopies <= 2) return 'Low Stock';
    return 'Available';
  }

  factory BookInventoryModel.fromCopies(String bookId, List<BookCopyModel> bookCopies, {int fallbackTotal = 1}) {
    if (bookCopies.isEmpty) {
      return BookInventoryModel(
        bookId: bookId,
        totalCopies: fallbackTotal > 0 ? fallbackTotal : 1,
        availableCopies: fallbackTotal > 0 ? fallbackTotal : 1,
        borrowedCopies: 0,
        reservedCopies: 0,
        damagedCopies: 0,
        lostCopies: 0,
        copies: const [],
      );
    }

    int available = 0;
    int borrowed = 0;
    int reserved = 0;
    int damaged = 0;
    int lost = 0;

    for (final copy in bookCopies) {
      final s = copy.status.toLowerCase();
      final c = copy.condition.toLowerCase();

      if (s == 'damaged' || c == 'damaged') {
        damaged++;
      } else if (s == 'lost' || c == 'lost') {
        lost++;
      } else if (s == 'borrowed' || s == 'rented' || (copy.currentBorrowerId != null && copy.currentBorrowerId!.isNotEmpty)) {
        borrowed++;
      } else if (s == 'reserved') {
        reserved++;
      } else if (s == 'available' || s == 'published' || copy.availability) {
        available++;
      } else {
        available++;
      }
    }

    return BookInventoryModel(
      bookId: bookId,
      totalCopies: bookCopies.length,
      availableCopies: available,
      borrowedCopies: borrowed,
      reservedCopies: reserved,
      damagedCopies: damaged,
      lostCopies: lost,
      copies: bookCopies,
    );
  }
}

Map<String, String> _parseLocalizedMap(dynamic value) {
  if (value is Map) {
    return {
      'en': (value['en'] ?? '').toString(),
      'ta': (value['ta'] ?? value['en'] ?? '').toString(),
      'hi': (value['hi'] ?? value['en'] ?? '').toString(),
    };
  }
  final String str = (value ?? '').toString();
  return {'en': str, 'ta': str, 'hi': str};
}

DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
