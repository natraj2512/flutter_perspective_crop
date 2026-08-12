import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A [CustomPainter] that draws the image with a perspective crop overlay.
///
/// Renders the source image, a dark overlay outside the crop region,
/// draggable corner handles, connecting edges, and a 3×3 grid guide.
class CropOverlayPainter extends CustomPainter {
  /// The source image to display.
  final ui.Image image;

  /// The 4 corner points in normalized coordinates (0.0 – 1.0).
  final List<Offset> corners;

  /// Converts a normalized offset to screen coordinates.
  final Offset Function(Offset) normalizedToScreen;

  /// Index of the currently dragged corner, or -1 if none.
  final int draggingIndex;

  /// Color of the dark overlay outside the crop area.
  final Color overlayColor;

  /// Color of the crop border and handles.
  final Color borderColor;

  /// Color of the active (dragged) handle.
  final Color activeHandleColor;

  /// Color of the grid lines inside the crop area.
  final Color gridColor;

  /// Stroke width of the crop border.
  final double borderStrokeWidth;

  /// Radius of corner handle circles.
  final double handleRadius;

  /// Radius of corner handle circles when being dragged.
  final double activeHandleRadius;

  CropOverlayPainter({
    required this.image,
    required this.corners,
    required this.normalizedToScreen,
    required this.draggingIndex,
    this.overlayColor = const Color(0x99000000),
    this.borderColor = Colors.white,
    this.activeHandleColor = Colors.yellow,
    this.gridColor = const Color(0x4DFFFFFF),
    this.borderStrokeWidth = 2.0,
    this.handleRadius = 12.0,
    this.activeHandleRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    final imageAspect = image.width / image.height;
    final screenAspect = size.width / size.height;

    double displayWidth, displayHeight;
    if (imageAspect > screenAspect) {
      displayWidth = size.width;
      displayHeight = size.width / imageAspect;
    } else {
      displayHeight = size.height;
      displayWidth = size.height * imageAspect;
    }

    final imageOffset = Offset(
      (size.width - displayWidth) / 2,
      (size.height - displayHeight) / 2,
    );

    final dstRect = Rect.fromLTWH(
        imageOffset.dx, imageOffset.dy, displayWidth, displayHeight);

    // Draw image
    canvas.drawImageRect(image, srcRect, dstRect, Paint());

    // Dark overlay outside crop area
    final screenCorners = corners.map(normalizedToScreen).toList();
    final cropPath = Path()..addPolygon(screenCorners, true);
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final overlayPath =
        Path.combine(PathOperation.difference, fullPath, cropPath);

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    // Crop border
    canvas.drawPath(
      cropPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderStrokeWidth,
    );

    // Corner handles and edges
    for (int i = 0; i < screenCorners.length; i++) {
      final isDragging = i == draggingIndex;

      canvas.drawCircle(
        screenCorners[i],
        isDragging ? activeHandleRadius : handleRadius,
        Paint()
          ..color = isDragging ? activeHandleColor : borderColor
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        screenCorners[i],
        4,
        Paint()..color = Colors.black,
      );

      final nextIndex = (i + 1) % screenCorners.length;
      canvas.drawLine(
        screenCorners[i],
        screenCorners[nextIndex],
        Paint()
          ..color = isDragging
              ? activeHandleColor
              : borderColor.withValues(alpha: 0.8)
          ..strokeWidth = 1.5,
      );
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 1; i < 3; i++) {
      final t = i / 3.0;
      canvas.drawLine(
        _lerp(screenCorners[0], screenCorners[3], t),
        _lerp(screenCorners[1], screenCorners[2], t),
        gridPaint,
      );
      canvas.drawLine(
        _lerp(screenCorners[0], screenCorners[1], t),
        _lerp(screenCorners[3], screenCorners[2], t),
        gridPaint,
      );
    }
  }

  Offset _lerp(Offset a, Offset b, double t) {
    return Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.draggingIndex != draggingIndex ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.activeHandleColor != activeHandleColor ||
        oldDelegate.gridColor != gridColor ||
        !_listEquals(oldDelegate.corners, corners);
  }

  bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}