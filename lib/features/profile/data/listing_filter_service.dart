import '../presentation/widgets/unified_listing.dart';
import 'listing_filter_model.dart';

class ListingFilterService {
  List<UnifiedListing> applyFilters(
    List<UnifiedListing> items,
    ListingFilterModel filter,
    String searchQuery,
  ) {
    // 1. Filter locally
    var filtered = items.where((item) {
      // Search query filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesId = item.id.toLowerCase().contains(query);
        final matchesProductId = item.productId.toLowerCase().contains(query);
        final matchesCategory = item.category.toLowerCase().contains(query);
        if (!matchesTitle && !matchesId && !matchesProductId && !matchesCategory) {
          return false;
        }
      }

      // Category filter
      if (!_matchesCategory(item, filter.category)) {
        return false;
      }

      // Status filter
      if (!_matchesStatus(item, filter.status)) {
        return false;
      }

      return true;
    }).toList();

    // 2. Sort locally
    switch (filter.sortBy) {
      case 'Newest First':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest First':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Recently Updated':
        filtered.sort((a, b) {
          final timeA = a.originalEquipment?.updatedAt ?? a.createdAt;
          final timeB = b.originalEquipment?.updatedAt ?? b.createdAt;
          return timeB.compareTo(timeA);
        });
        break;
      case 'Most Viewed':
        filtered.sort((a, b) => b.views.compareTo(a.views));
        break;
      case 'Alphabetical':
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  bool _matchesCategory(UnifiedListing item, String filter) {
    if (filter == 'All') return true;
    final f = filter.toLowerCase();
    final c = item.category.toLowerCase();
    if (f.contains('book')) return c.contains('book');
    if (f.contains('farm') || f.contains('agri')) return c.contains('farm') || c.contains('agri');
    if (f.contains('construction') || f.contains('tool')) return c.contains('construction') || c.contains('tool');
    if (f.contains('electron')) return c.contains('electron');
    if (f.contains('music')) return c.contains('music');
    return c == f;
  }

  bool _matchesStatus(UnifiedListing item, String filter) {
    if (filter == 'All') return true;
    final f = filter.toLowerCase();
    final s = item.status.toLowerCase();
    if (f == 'available') return s == 'published' || s == 'available';
    if (f == 'borrowed') return s == 'booked' || s == 'rented';
    return s == f;
  }
}
