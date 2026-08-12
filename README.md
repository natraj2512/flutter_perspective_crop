# flutter_perspective_crop

A Flutter package for perspective image cropping with draggable corner handles, grid overlay, and homography-based perspective correction.

## Features

- **Perspective crop** — Drag four corner handles to define an arbitrary quadrilateral crop region
- **Homography-based transform** — Uses projective (perspective) mapping via a subdivided triangle mesh for accurate results
- **Interactive UI** — Real-time preview with dark overlay, crop border, and 3×3 grid guide
- **Fully customizable** — Colors, handle sizes, labels, padding, and more are configurable via constructor parameters
- **Simple API** — Navigate to `PerspectiveCropPage` and receive the cropped image file path on pop

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_perspective_crop: ^1.0.0
```

Then run:

```bash
flutter pub get
```

Import it in your Dart code:

```dart
import 'package:flutter_perspective_crop/flutter_perspective_crop.dart';
```

## Usage

### Basic usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_perspective_crop/flutter_perspective_crop.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final croppedPath = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (_) => PerspectiveCropPage(
                  imagePath: '/path/to/your/image.jpg',
                ),
              ),
            );

            if (croppedPath != null) {
              debugPrint('Cropped image saved at: $croppedPath');
            }
          },
          child: const Text('Crop Image'),
        ),
      ),
    );
  }
}
```

### Customized usage

```dart
PerspectiveCropPage(
  imagePath: imagePath,
  title: 'Adjust Crop',
  backgroundColor: Colors.grey.shade900,
  appBarColor: Colors.grey.shade900,
  cropLabel: 'Apply',
  resetLabel: 'Start Over',
  handleRadius: 14.0,
  activeHandleRadius: 18.0,
  overlayColor: Colors.black54,
  borderColor: Colors.cyan,
  activeHandleColor: Colors.cyanAccent,
  gridColor: Colors.cyan.withValues(alpha: 0.3),
  touchSlop: 80.0,
  onError: (error) => debugPrint('Crop failed: $error'),
)
```

### Using the engine directly

You can also use `PerspectiveCropEngine` programmatically if you need to perform a perspective crop without the UI:

```dart
import 'dart:ui' as ui;
import 'package:flutter_perspective_crop/flutter_perspective_crop.dart';

Future<ui.Image?> cropImage(ui.Image source, List<Offset> corners) {
  // corners: [topLeft, topRight, bottomRight, bottomLeft] in pixel coordinates
  return PerspectiveCropEngine.apply(source, corners);
}
```

## API Reference

### PerspectiveCropPage

| Parameter | Type | Default | Description |
|---|---|---|---|
| `imagePath` | `String` | **required** | Path to the source image file |
| `title` | `String` | `'Crop Image'` | AppBar title |
| `backgroundColor` | `Color` | `Colors.black` | Page background color |
| `appBarColor` | `Color` | `Colors.black` | AppBar background |
| `appBarIconColor` | `Color` | `Colors.white` | AppBar icon color |
| `appBarTextColor` | `Color` | `Colors.white` | AppBar text color |
| `padding` | `EdgeInsetsGeometry` | `EdgeInsets.all(16)` | Padding around crop area |
| `resetLabel` | `String` | `'Reset'` | Reset button label |
| `cropLabel` | `String` | `'Crop'` | Crop button label |
| `cropButtonColor` | `Color` | `Colors.white` | Crop button background |
| `cropButtonForegroundColor` | `Color` | `Colors.black` | Crop button text color |
| `handleRadius` | `double` | `12.0` | Corner handle radius |
| `activeHandleRadius` | `double` | `16.0` | Active handle radius |
| `overlayColor` | `Color` | `Color(0x99000000)` | Overlay outside crop |
| `borderColor` | `Color` | `Colors.white` | Border & handle color |
| `activeHandleColor` | `Color` | `Colors.yellow` | Active handle color |
| `gridColor` | `Color` | `Color(0x4DFFFFFF)` | Grid line color |
| `touchSlop` | `double` | `60.0` | Touch grab distance |
| `onError` | `void Function(Object)?` | `null` | Error callback |

### PerspectiveCropEngine

| Method | Description |
|---|---|
| `apply(source, quadCorners)` | Crops the source image using perspective transform. Returns the cropped `ui.Image`. |
| `computeHomography(srcPts, dstPts)` | Computes the 3×3 homography matrix for 4 point correspondences. |

### CropOverlayPainter

A `CustomPainter` that renders the image with the crop overlay. Accepts all visual customization parameters.

## Additional information

- Report bugs and request features on the [GitHub issue tracker](https://github.com/your-username/flutter_perspective_crop/issues)
- Contributions are welcome! Please open a pull request.
- Licensed under the MIT License.