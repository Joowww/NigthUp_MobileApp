// lib/widgets/image_with_fallback.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    this.fallbackAsset = 'assets/images/google.png',
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
          isCircle ? Icons.person : Icons.image,
          color: Colors.grey[600],
          size: isCircle ? (width ?? 40) * 0.7 : 50,
        ),
      ),
    );

    // Validar que imageUrl sea una string válida
    final String? validImageUrl = _validateImageUrl(imageUrl);
    if (validImageUrl == null) {
      return _buildFinalWidget(
        _buildAssetImage(fallbackAsset, defaultFallback),
      );
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
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white30,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        return _buildAssetImage(fallbackAsset, defaultFallback);
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
      if (url.isEmpty) return null;

      // ✅ Si la URL contiene "default-images", es una imagen semilla del backend.
      // Devolvemos null para que el widget use el [fallbackAsset] local y evitemos el 404.
      if (url.contains('default-images')) return null;

      // Si ya es absoluta (http...), la devolvemos tal cual
      if (Uri.parse(url).isAbsolute) {
        return url;
      }
      // Si empieza por /, asumimos es relativa a localhost (para desarrollo)
      if (url.startsWith('/')) {
        // Asumiendo que las imágenes se sirven desde la raíz http://localhost:3000
        return 'http://localhost:3000$url';
      }
      // O tal vez es relativa sin / (ej. "uploads/...")
      return 'http://localhost:3000/$url';
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
