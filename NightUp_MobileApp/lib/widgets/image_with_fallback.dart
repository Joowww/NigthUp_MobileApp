// lib/widgets/image_with_fallback.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';

class ImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  // Usamos google.png como la imagen de reserva que ya existe en tu assets
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
    // 1. Widget de reserva por defecto (si no hay imagen ni asset de reserva)
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

    // Validar que imageUrl sea una string válida
    final String? validImageUrl = _validateImageUrl(imageUrl);
    if (validImageUrl == null) {
      if (fallbackAsset != null) {
        return _buildFinalWidget(
          _buildAssetImage(fallbackAsset, defaultFallback),
        );
      }
      return defaultFallback;
    }

    // Widget de CachedNetworkImage para cargar la imagen remota
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

  // Helper para imágenes de assets
  Widget _buildAssetImage(String? asset, Widget errorWidget) {
    if (asset == null || asset.isEmpty) return errorWidget;
    return Image.asset(
      asset,
      fit: fit,
      width: width,
      height: height,
      // Si el asset falla (ej. no existe), mostramos el widget por defecto
      errorBuilder: (context, error, stackTrace) => errorWidget,
    );
  }

  // Valida que la url sea un String y una URL absoluta
  String? _validateImageUrl(dynamic url) {
    if (url == null) return null;
    if (url is String) {
      final String trimmedUrl = url.trim();
      if (trimmedUrl.isEmpty) return null;

      // Si empieza por assets/, es un recurso local
      if (trimmedUrl.startsWith('assets/')) return null;

      // ✅ PRIORIDAD: Si ya es absoluta (http...), la devolvemos tal cual
      if (trimmedUrl.startsWith('http')) {
        return trimmedUrl;
      }

      // Si empieza por /, asumimos es relativa al servidor
      if (trimmedUrl.startsWith('/')) {
        return ApiConstants.baseUrl.replaceFirst('/api', '') + trimmedUrl;
      }

      // Si llegamos aquí y no tiene esquema, asumimos relativa
      return '${ApiConstants.baseUrl.replaceFirst('/api', '')}/$trimmedUrl';
    }
    return null;
  }

  // Helper para aplicar Clip Oval/RRect al widget final
  Widget _buildFinalWidget(Widget child) {
    if (isCircle) {
      return ClipOval(child: child);
    } else if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
