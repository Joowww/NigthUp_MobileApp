import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';

class ImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackAsset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool isCircle;
  final BorderRadiusGeometry? borderRadius;

  const ImageWithFallback({
    super.key,
    this.imageUrl,
    this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.isCircle = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget defaultFallback = Container(
      width: width,
      height: height,
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          isCircle ? Icons.person : Icons.image_not_supported_outlined,
          color: Colors.white12,
          size: isCircle ? (width ?? 40) * 0.5 : 30,
        ),
      ),
    );

    final String? validImageUrl = _validateImageUrl(imageUrl);
    if (validImageUrl == null) {
      if (fallbackAsset != null) {
        return _buildFinalWidget(
          _buildAssetImage(fallbackAsset, defaultFallback),
        );
      }
      return defaultFallback;
    }

    final Widget imageWidget = CachedNetworkImage(
      imageUrl: validImageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[900],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white10,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        if (fallbackAsset != null) {
          return _buildAssetImage(fallbackAsset, defaultFallback);
        }
        return defaultFallback;
      },
    );

    return _buildFinalWidget(imageWidget);
  }

  Widget _buildAssetImage(String? asset, Widget errorWidget) {
    if (asset == null || asset.isEmpty) return errorWidget;
    return Image.asset(
      asset,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => errorWidget,
    );
  }

  String? _validateImageUrl(dynamic url) {
    if (url == null) return null;
    if (url is String) {
      final String trimmedUrl = url.trim();
      if (trimmedUrl.isEmpty) return null;

      if (trimmedUrl.startsWith('assets/')) return null;

      if (trimmedUrl.startsWith('http')) {
        return trimmedUrl;
      }

      if (trimmedUrl.startsWith('/')) {
        return ApiConstants.baseUrl.replaceFirst('/api', '') + trimmedUrl;
      }
      return '${ApiConstants.baseUrl.replaceFirst('/api', '')}/$trimmedUrl';
    }
    return null;
  }

  Widget _buildFinalWidget(Widget child) {
    if (isCircle) {
      return ClipOval(child: child);
    } else if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
