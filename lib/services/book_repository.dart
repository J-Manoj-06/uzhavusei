import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

/// A set of filter parameters applied when fetching books from Firestore.
class BookFilter {
  final String? category;
  final String? author;
  final String? publisher;
  final String? language;
  final int? publicationYear;
  final bool? availableOnly;
  final String sortBy; // 'newest' | 'oldest' | 'az' | 'za' | 'mostAvailable' | 'lowStock'

  const BookFilter({
    this.category,
    this.author,
    this.publisher,
    this.language,
    this.publicationYear,
    this.availableOnly,
    this.sortBy = 'newest',
  });

  BookFilter copyWith({
    Object? category = _sentinel,
    Object? author = _sentinel,
    Object? publisher = _sentinel,
    Object? language = _sentinel,
    Object? publicationYear = _sentinel,
    Object? availableOnly = _sentinel,
    String? sortBy,
  }) {
    return BookFilter(
      category: category == _sentinel ? this.category : category as String?,
      author: author == _sentinel ? this.author : author as String?,
      publisher: publisher == _sentinel ? this.publisher : publisher as String?,
      language: language == _sentinel ? this.language : language as String?,
      publicationYear: publicationYear == _sentinel ? this.publicationYear : publicationYear as int?,
      availableOnly: availableOnly == _sentinel ? this.availableOnly : availableOnly as bool?,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

const _sentinel = Object();

/// Paginated book result with cursor for next-page loading.
class BookPage {
  final List<BookModel> books;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const BookPage({
    required this.books,
    required this.lastDoc,
    required this.hasMore,
  });
}

/// Repository that reads directly from the `books` Firestore collection
/// using [BookModel]. Supports realtime streaming, cursor pagination,
/// dynamic filtering, and full-text substring search (client-side).
class BookRepository {
  BookRepository._({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static final BookRepository instance = BookRepository._();

  final FirebaseFirestore _db;
  static const _col = 'books';
  static const int pageSize = 20;

  // ─────────────────────────────────────────────────────────────
  // 1. Realtime stream of ALL books (home page / category counts)
  // ─────────────────────────────────────────────────────────────

  /// Streams every document in the books collection, mapped to [BookModel].
  /// Updates in real time whenever the librarian adds / edits / deletes a book.
  Stream<List<BookModel>> watchAllBooks() {
    return _db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(_safeFromDoc)
            .whereType<BookModel>()
            .where((b) => b.isValidBook)
            .toList());
  }

  /// Streams the latest [limit] books — used for "Recently Added" carousel.
  Stream<List<BookModel>> watchRecentBooks({int limit = 10}) {
    return _db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(_safeFromDoc)
            .whereType<BookModel>()
            .where((b) => b.isValidBook)
            .take(limit)
            .toList());
  }

  /// Streams books in a specific category — used for category chips.
  Stream<List<BookModel>> watchBooksByCategory(String category, {int limit = 20}) {
    return _db
        .collection(_col)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) => snap.docs
            .map(_safeFromDoc)
            .whereType<BookModel>()
            .where((b) => b.isValidBook)
            .take(limit)
            .toList());
  }

  /// Streams a map of category → book count for dynamic chips.
  Stream<Map<String, int>> watchCategoryCounts() {
    return _db.collection(_col).snapshots().map((snap) {
      final counts = <String, int>{'All': snap.docs.length};
      for (final doc in snap.docs) {
        try {
          final data = doc.data();
          final cat = (data['category'] ?? '').toString().trim();
          if (cat.isNotEmpty) {
            counts[cat] = (counts[cat] ?? 0) + 1;
          }
        } catch (_) {}
      }
      return counts;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Paginated book loading with filters
  // ─────────────────────────────────────────────────────────────

  /// Fetches the first page of books with optional [filter].
  Future<BookPage> fetchFirstPage(BookFilter filter, {String query = ''}) async {
    return _fetchPage(filter, query: query, startAfter: null);
  }

  /// Fetches the next page of books, starting after [lastDoc].
  Future<BookPage> fetchNextPage(
    BookFilter filter, {
    required DocumentSnapshot lastDoc,
    String query = '',
  }) async {
    return _fetchPage(filter, query: query, startAfter: lastDoc);
  }

  Future<BookPage> _fetchPage(
    BookFilter filter, {
    required DocumentSnapshot? startAfter,
    String query = '',
  }) async {
    // For free-text search we do a broad client-side filter after fetching.
    // Firestore native ordering/filtering is applied first to reduce reads.
    Query<Map<String, dynamic>> ref = _db.collection(_col);

    // Apply Firestore-level filter only for exact-match fields
    if (filter.category != null && filter.category!.isNotEmpty && filter.category != 'All') {
      ref = ref.where('category', isEqualTo: filter.category);
    }

    if (filter.language != null && filter.language!.isNotEmpty && filter.language != 'All') {
      ref = ref.where('language', isEqualTo: filter.language);
    }

    // Sort
    switch (filter.sortBy) {
      case 'oldest':
        ref = ref.orderBy('createdAt', descending: false);
        break;
      case 'az':
        ref = ref.orderBy('title', descending: false);
        break;
      case 'za':
        ref = ref.orderBy('title', descending: true);
        break;
      case 'mostAvailable':
        ref = ref.orderBy('availableCopies', descending: true);
        break;
      default:
        ref = ref.orderBy('createdAt', descending: true);
    }

    if (startAfter != null) {
      ref = ref.startAfterDocument(startAfter);
    }

    // Fetch extra to detect hasMore
    final snap = await ref.limit(pageSize + 1).get(
      const GetOptions(source: Source.serverAndCache),
    );

    List<BookModel> books = snap.docs
        .map(_safeFromDoc)
        .whereType<BookModel>()
        .where((b) => b.isValidBook)
        .toList();

    // Client-side filters that can't be done purely in Firestore
    if (filter.author != null && filter.author!.isNotEmpty) {
      final lowerAuthor = filter.author!.toLowerCase();
      books = books.where((b) => b.author.toLowerCase().contains(lowerAuthor)).toList();
    }

    if (filter.publisher != null && filter.publisher!.isNotEmpty) {
      final lowerPub = filter.publisher!.toLowerCase();
      books = books.where((b) => b.publisher.toLowerCase().contains(lowerPub)).toList();
    }

    if (filter.publicationYear != null) {
      books = books.where((b) => b.publicationYear == filter.publicationYear).toList();
    }

    if (filter.availableOnly == true) {
      books = books.where((b) => b.availableCopies > 0).toList();
    }

    if (filter.sortBy == 'lowStock') {
      books = books.where((b) => b.availableCopies > 0 && b.availableCopies <= 2).toList();
    }

    // Free-text search (Title, Author, ISBN, Category, Department, Publisher, Language)
    if (query.isNotEmpty) {
      final lq = query.toLowerCase();
      books = books.where((b) {
        return b.title.toLowerCase().contains(lq) ||
            b.author.toLowerCase().contains(lq) ||
            b.isbn.toLowerCase().contains(lq) ||
            b.category.toLowerCase().contains(lq) ||
            b.department.toLowerCase().contains(lq) ||
            b.publisher.toLowerCase().contains(lq) ||
            b.language.toLowerCase().contains(lq);
      }).toList();
    }

    final hasMore = snap.docs.length > pageSize;
    final lastDocSnap = snap.docs.length > pageSize
        ? snap.docs[pageSize - 1]
        : (snap.docs.isNotEmpty ? snap.docs.last : null);

    if (books.length > pageSize) {
      books = books.sublist(0, pageSize);
    }

    return BookPage(
      books: books,
      lastDoc: lastDocSnap,
      hasMore: hasMore,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Single-book stream (book details)
  // ─────────────────────────────────────────────────────────────

  Stream<BookModel?> watchBook(String bookId) {
    return _db.collection(_col).doc(bookId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _safeFromDoc(doc);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 4. Search autocomplete suggestions
  // ─────────────────────────────────────────────────────────────

  Future<List<String>> getSuggestions(String query) async {
    final lq = query.toLowerCase().trim();
    if (lq.isEmpty) return const [];

    final snap = await _db.collection(_col).limit(50).get(
      const GetOptions(source: Source.serverAndCache),
    );

    final suggestions = <String>{};
    for (final doc in snap.docs) {
      try {
        final book = _safeFromDoc(doc);
        if (book == null) continue;
        if (book.title.toLowerCase().contains(lq)) suggestions.add(book.title);
        if (book.author.toLowerCase().contains(lq) && book.author.isNotEmpty) {
          suggestions.add(book.author);
        }
        if (book.category.toLowerCase().contains(lq) && book.category.isNotEmpty) {
          suggestions.add(book.category);
        }
        if (book.isbn.toLowerCase().contains(lq) && book.isbn.isNotEmpty) {
          suggestions.add(book.isbn);
        }
      } catch (_) {}
    }
    return suggestions.take(6).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // 5. Helper
  // ─────────────────────────────────────────────────────────────

  BookModel? _safeFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return BookModel.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }
}
