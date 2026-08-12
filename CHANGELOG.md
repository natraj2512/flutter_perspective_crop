## 1.0.0

- Initial release of `flutter_perspective_crop`.
- `PerspectiveCropPage` — Full-screen crop UI with draggable corner handles, dark overlay, grid guide, and crop/reset buttons.
- `PerspectiveCropEngine` — Homography-based perspective crop engine using a 40×40 subdivided triangle mesh for accurate projective mapping.
- `CropOverlayPainter` — Customizable `CustomPainter` for rendering the crop overlay.
- Supports full visual customization: colors, handle sizes, labels, padding, touch sensitivity.
- Returns the cropped image file path via `Navigator.pop`.