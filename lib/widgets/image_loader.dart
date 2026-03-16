import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

Widget buildSmartImage(
  String url, {
  double? width,
  double? height,
  BoxFit? fit,
  BorderRadius? borderRadius,
}) {
  final isAsset = url.startsWith('assets/');
  final image = isAsset
      ? Image.asset(url, width: width, height: height, fit: fit)
      : CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          placeholder: (context, _) => Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, _, __) => const Icon(Icons.broken_image),
        );

  if (borderRadius != null) {
    return ClipRRect(borderRadius: borderRadius, child: image);
  }
  return image;
}
