import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'crop_overlay_painter.dart';
import 'perspective_crop_engine.dart';

/// A page that lets the user crop an image by adjusting four corner handles.
///
/// Returns the file path of the cropped image via [Navigator.pop].
///
/// ## Usage
///
/// ```dart
/// final croppedPath = await Navigator.push<String>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => PerspectiveCropPage(imagePath: '/path/to/image.jpg'),
///   ),
/// );
/// ```
class PerspectiveCropPage extends StatefulWidget {
  /// Path to the source image file.
  final String imagePath;

  /// Optional title shown in the AppBar.
  final String title;

  /// Background color of the page.
  final Color backgroundColor;

  /// AppBar background color.
  final Color appBarColor;

  /// AppBar icon theme color.
  final Color appBarIconColor;

  /// AppBar title text color.
  final Color appBarTextColor;

  /// Padding around the crop area.
  final EdgeInsetsGeometry padding;

  /// Label for the reset button in the AppBar.
  final String resetLabel;

  /// Label for the crop button.
  final String cropLabel;

  /// Color of the crop button background.
  final Color cropButtonColor;

  /// Color of the crop button foreground (text/icon).
  final Color cropButtonForegroundColor;

  /// Radius for the corner handles in the crop overlay.
  final double handleRadius;

  /// Radius for the active (dragged) corner handle.
  final double activeHandleRadius;

  /// Color of the dark overlay outside the crop area.
  final Color overlayColor;

  /// Color of the crop border and handles.
  final Color borderColor;

  /// Color of the active (dragged) handle.
  final Color activeHandleColor;

  /// Color of the grid lines inside the crop area.
  final Color gridColor;

  /// Maximum touch distance (in logical pixels) to grab a corner handle.
  final double touchSlop;

  /// Callback invoked when the crop operation fails.
  final void Function(Object error)? onError;

  /// Creates a [PerspectiveCropPage].
  const PerspectiveCropPage({
    super.key,
    required this.imagePath,
    this.title = 'Crop Image',
    this.backgroundColor = Colors.black,
    this.appBarColor = Colors.black,
    this.appBarIconColor = Colors.white,
    this.appBarTextColor = Colors.white,
    this.padding = const EdgeInsets.all(16.0),
    this.resetLabel = 'Reset',
    this.cropLabel = 'Crop',
    this.cropButtonColor = Colors.white,
    this.cropButtonForegroundColor = Colors.black,
    this.handleRadius = 12.0,
    this.activeHandleRadius = 16.0,
    this.overlayColor = const Color(0x99000000),
    this.borderColor = Colors.white,
    this.activeHandleColor = Colors.yellow,
    this.gridColor = const Color(0x4DFFFFFF),
    this.touchSlop = 60.0,
    this.onError,
  });

  @override
  State<PerspectiveCropPage> createState() => _PerspectiveCropPageState();
}

class _PerspectiveCropPageState extends State<PerspectiveCropPage> {
  ui.Image? _image;
  bool _isLoading = true;
  bool _isProcessing = false;

  // The 4 corner points (normalized 0.0 - 1.0 relative to image display area)
  late List<Offset> _corners;

  // Index of the corner being dragged, -1 if none
  int _draggingCornerIndex = -1;

  // Size of the displayed image within the screen
  Size _displaySize = Size.zero;
  Offset _imageOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _initCorners();
      _isLoading = false;
    });
  }

  void _initCorners() {
    if (_image == null) return;
    _corners = [
      Offset.zero, // top-left
      const Offset(1.0, 0.0), // top-right
      const Offset(1.0, 1.0), // bottom-right
      const Offset(0.0, 1.0), // bottom-left
    ];
  }

  void _calculateDisplayLayout(BoxConstraints constraints) {
    if (_image == null) return;

    final imageWidth = _image!.width.toDouble();
    final imageHeight = _image!.height.toDouble();
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final imageAspect = imageWidth / imageHeight;
    final screenAspect = screenWidth / screenHeight;

    double displayWidth, displayHeight;

    if (imageAspect > screenAspect) {
      displayWidth = screenWidth;
      displayHeight = screenWidth / imageAspect;
    } else {
      displayHeight = screenHeight;
      displayWidth = screenHeight * imageAspect;
    }

    _displaySize = Size(displayWidth, displayHeight);
    _imageOffset = Offset(
      (screenWidth - displayWidth) / 2,
      (screenHeight - displayHeight) / 2,
    );
  }

  Offset _normalizedToScreen(Offset normalized) {
    return Offset(
      _imageOffset.dx + normalized.dx * _displaySize.width,
      _imageOffset.dy + normalized.dy * _displaySize.height,
    );
  }

  Offset _screenToNormalized(Offset screen) {
    return Offset(
      ((screen.dx - _imageOffset.dx) / _displaySize.width).clamp(0.0, 1.0),
      ((screen.dy - _imageOffset.dy) / _displaySize.height).clamp(0.0, 1.0),
    );
  }

  Future<void> _cropImage() async {
    if (_image == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final originalBytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      final imgW = originalImage.width.toDouble();
      final imgH = originalImage.height.toDouble();

      // Convert normalized corners to pixel coordinates
      final List<Offset> pixelCorners = _corners.map((c) {
        return Offset(c.dx * imgW, c.dy * imgH);
      }).toList();

      final croppedImage = await PerspectiveCropEngine.apply(
        originalImage,
        pixelCorners,
      );

      if (croppedImage != null) {
        final byteData =
            await croppedImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final croppedFile = File('${tempDir.path}/cropped_$timestamp.png');
          await croppedFile.writeAsBytes(byteData.buffer.asUint8List());

          if (mounted) {
            Navigator.pop(context, croppedFile.path);
          }
        }
      }
    } catch (e) {
      debugPrint('Crop error: $e');
      widget.onError?.call(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to crop image')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _resetCorners() {
    setState(() {
      _initCorners();
    });
  }

  void _onPanStart(DragStartDetails details) {
    final touchPos = details.localPosition;
    double minDist = double.infinity;
    int closestIndex = -1;

    for (int i = 0; i < _corners.length; i++) {
      final screenPos = _normalizedToScreen(_corners[i]);
      final dist = (touchPos - screenPos).distance;
      if (dist < minDist && dist < widget.touchSlop) {
        minDist = dist;
        closestIndex = i;
      }
    }

    setState(() {
      _draggingCornerIndex = closestIndex;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggingCornerIndex < 0) return;

    setState(() {
      _corners[_draggingCornerIndex] =
          _screenToNormalized(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _draggingCornerIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.appBarColor,
        iconTheme: IconThemeData(color: widget.appBarIconColor),
        title: Text(
          widget.title,
          style: TextStyle(color: widget.appBarTextColor),
        ),
        actions: [
          TextButton(
            onPressed: _resetCorners,
            child: Text(
              widget.resetLabel,
              style: TextStyle(color: widget.appBarTextColor),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: widget.padding,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _calculateDisplayLayout(constraints);

                  return GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: CropOverlayPainter(
                        image: _image!,
                        corners: _corners,
                        normalizedToScreen: _normalizedToScreen,
                        draggingIndex: _draggingCornerIndex,
                        overlayColor: widget.overlayColor,
                        borderColor: widget.borderColor,
                        activeHandleColor: widget.activeHandleColor,
                        gridColor: widget.gridColor,
                        handleRadius: widget.handleRadius,
                        activeHandleRadius: widget.activeHandleRadius,
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _cropImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.cropButtonColor,
              foregroundColor: widget.cropButtonForegroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.cropButtonForegroundColor,
                    ),
                  )
                : Text(
                    widget.cropLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}