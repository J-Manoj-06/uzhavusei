import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Builds a smart image widget that handles:
/// - Asset paths (starts with 'assets/')
/// - Cloudinary URLs (auto-format + quality transformations)
/// - Any network URL with CachedNetworkImage
/// - Shimmer placeholder while loading
/// - Book-icon error widget for broken URLs
/// - Never shows an empty container
int? _safeMemCacheSize(double? val) {
  if (val == null || val.isInfinite || val.isNaN || val <= 0) return null;
  return (val * 2).toInt();
}

Widget buildSmartImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
  Widget? errorWidget,
  bool isBook = false,
}) {
  final resolvedUrl = _resolveUrl(url);
  final Widget image;

  if (resolvedUrl.startsWith('assets/')) {
    image = Image.asset(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildErrorPlaceholder(width, height, isBook: isBook),
    );
  } else if (resolvedUrl.isEmpty) {
    image = _buildErrorPlaceholder(width, height, isBook: isBook);
  } else {
    image = CachedNetworkImage(
      imageUrl: resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, _) => _buildShimmerPlaceholder(width, height),
      errorWidget: (context, _, __) =>
          errorWidget ?? _buildErrorPlaceholder(width, height, isBook: isBook),
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheWidth: _safeMemCacheSize(width),
      memCacheHeight: _safeMemCacheSize(height),
    );
  }

  if (borderRadius != null) {
    return ClipRRect(borderRadius: borderRadius, child: image);
  }
  return image;
}

String _resolveUrl(String raw) {
  var trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('//')) {
    trimmed = 'https:$trimmed';
  } else if (!trimmed.startsWith('http://') &&
      !trimmed.startsWith('https://') &&
      !trimmed.startsWith('assets/')) {
    if (trimmed.contains('cloudinary.com') ||
        trimmed.contains('res.cloudinary') ||
        trimmed.contains('cloudinary') ||
        trimmed.contains('http')) {
      trimmed = 'https://$trimmed';
    }
  }

  // Cloudinary URL optimisation: insert f_auto,q_auto before upload/
  if (trimmed.contains('cloudinary.com') && !trimmed.contains('f_auto')) {
    trimmed = trimmed.replaceFirst('/upload/', '/upload/f_auto,q_auto/');
  }

  return trimmed;
}

Widget _buildShimmerPlaceholder(double? width, double? height) {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: Container(
      width: width,
      height: height,
      color: Colors.white,
    ),
  );
}

Widget _buildErrorPlaceholder(double? width, double? height, {bool isBook = false}) {
  if (isBook) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 38,
            ),
            SizedBox(height: 4),
            Text(
              'No Cover',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Container(
    width: width,
    height: height,
    color: const Color(0xFFF3F4F6),
    child: Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: const Color(0xFF9CA3AF),
        size: (height != null && height < 80) ? 20 : 40,
      ),
    ),
  );
}
