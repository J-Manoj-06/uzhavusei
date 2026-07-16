import 'package:flutter/foundation.dart';

class LoggerService {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void warn(String message) {
    debugPrint('[WARN] $message');
  }

  static void error(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('Error details: $error');
    if (stack != null) debugPrint('StackTrace:\n$stack');
  }

  // Analytics Hooks
  static void trackListingView(String listingId) {
    debug('[ANALYTICS] Listing View - ID: $listingId');
  }

  static void trackBorrowRequest(String listingId, String borrowerId) {
    debug('[ANALYTICS] Borrow Request - Listing: $listingId, Borrower: $borrowerId');
  }

  static void trackCategoryClick(String categoryName) {
    debug('[ANALYTICS] Category Click - Name: $categoryName');
  }

  static void trackSearchUsage(String query) {
    debug('[ANALYTICS] Search Usage - Query: $query');
  }

  static void trackRecommendationClick(String listingId) {
    debug('[ANALYTICS] Recommendation Click - Listing: $listingId');
  }

  static void trackFavoriteToggle(String listingId, bool isFavorite) {
    debug('[ANALYTICS] Favorite Toggle - Listing: $listingId, Favorite: $isFavorite');
  }
}
