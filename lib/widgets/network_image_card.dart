import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class NetworkImageCard extends StatelessWidget {
  const NetworkImageCard({
    required this.url,
    this.height = 150,
    this.fit = BoxFit.cover,
    this.borderRadius = 16,
    super.key,
  });

  final String? url;
  final double height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: double.infinity,
        color: AppColors.surfaceSoft,
        child: imageUrl == null || imageUrl.isEmpty
            ? const _Fallback()
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: fit,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const _Fallback(),
              ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(Icons.quiz_rounded, size: 52, color: AppColors.muted),
      );
}
