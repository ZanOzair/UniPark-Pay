import 'package:flutter/material.dart';
import 'package:uniparkpay/utils/image_data_converter.dart';

/// Reusable widget for displaying images from various data sources
/// Handles String (base64), Uint8List, and List\<int\> image data
class ImageViewer extends StatelessWidget {
  final dynamic imageData;
  final double? height;
  final double? width;
  final BoxFit fit;
  final String? placeholderText;
  final Widget? placeholderWidget;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showLoading;
  final bool showError;
  final String? errorMessage;

  const ImageViewer({
    super.key,
    required this.imageData,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.placeholderText = 'No image available',
    this.placeholderWidget,
    this.backgroundColor,
    this.borderRadius,
    this.showLoading = true,
    this.showError = true,
    this.errorMessage,
  });

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholderWidget != null) {
      return placeholderWidget!;
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: height != null ? height! * 0.3 : 48,
            color: Colors.grey,
          ),
          if (placeholderText != null) ...[
            const SizedBox(height: 8),
            Text(
              placeholderText!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (!showError) return _buildPlaceholder(context);

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: height != null ? height! * 0.3 : 48,
            color: Colors.red,
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Failed to load image',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = ImageDataConverter.convertToImageBytes(imageData);

    if (imageBytes == null) {
      return _buildPlaceholder(context);
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.memory(
          imageBytes,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('ImageViewer error: $error');
            return _buildErrorWidget(context);
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            if (frame == null && showLoading) {
              return Container(
                height: height,
                width: width,
                color: backgroundColor ?? Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return child;
          },
        ),
      ),
    );
  }
}

/// Enhanced ImageViewer with metadata display
class ImageViewerWithMetadata extends StatelessWidget {
  final dynamic imageData;
  final String? title;
  final String? subtitle;
  final Map<String, String>? metadata;
  final double? imageHeight;
  final double? imageWidth;
  final BoxFit fit;
  final bool showBorder;
  final EdgeInsetsGeometry padding;

  const ImageViewerWithMetadata({
    super.key,
    required this.imageData,
    this.title,
    this.subtitle,
    this.metadata,
    this.imageHeight = 200,
    this.imageWidth,
    this.fit = BoxFit.contain,
    this.showBorder = true,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: showBorder ? 2 : 0,
      shape: showBorder
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Center(
              child: ImageViewer(
                imageData: imageData,
                height: imageHeight,
                width: imageWidth ?? double.infinity,
                fit: fit,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
            if (metadata != null && metadata!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...metadata!.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}