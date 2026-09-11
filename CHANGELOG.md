## 1.1.0

- Added 8 draggable handles: 4 corner handles + 4 edge midpoint handles.
- Midpoint handles use the same circle style as corner handles (`handleRadius`, `activeHandleRadius`, inner black dot).
- Dragging a midpoint handle moves both adjacent corners together to preserve the edge.
- Updated docs to reflect the new handle system.

## 1.0.1

- Updated package metadata with the GitHub repository information.
- Minor package metadata improvements.

## 1.0.0

- Initial release of `flutter_perspective_crop`.
- `PerspectiveCropPage` — Full-screen crop UI with draggable corner handles, dark overlay, grid guide, and crop/reset buttons.
- `PerspectiveCropEngine` — Homography-based perspective crop engine using a 40×40 subdivided triangle mesh for accurate projective mapping.
- `CropOverlayPainter` — Customizable `CustomPainter` for rendering the crop overlay.
- Supports full visual customization: colors, handle sizes, labels, padding, touch sensitivity.
- Returns the cropped image file path via `Navigator.pop`.