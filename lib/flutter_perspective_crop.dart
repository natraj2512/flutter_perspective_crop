/// A Flutter package for perspective image cropping with draggable corner
/// handles, grid overlay, and homography-based perspective correction.
///
/// ## Quick start
///
/// ```dart
/// import 'package:flutter_perspective_crop/flutter_perspective_crop.dart';
///
/// // Navigate to the crop page and await the result
/// final croppedPath = await Navigator.push<String>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => PerspectiveCropPage(imagePath: '/path/to/image.jpg'),
///   ),
/// );
///
/// if (croppedPath != null) {
///   // Use the cropped image at croppedPath
/// }
/// ```
library;

export 'src/crop_overlay_painter.dart';
export 'src/perspective_crop_engine.dart';
export 'src/perspective_crop_page.dart';