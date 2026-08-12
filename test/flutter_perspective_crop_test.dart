import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_perspective_crop/flutter_perspective_crop.dart';

void main() {
  group('PerspectiveCropEngine', () {
    test('computeHomography returns identity for identity mapping', () {
      // Map unit square to itself — should yield identity-like coefficients
      final src = [
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(1, 1),
        const Offset(0, 1),
      ];
      final dst = [
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(1, 1),
        const Offset(0, 1),
      ];

      final h = PerspectiveCropEngine.computeHomography(src, dst);

      // For an identity mapping: h[0]=1, h[1]=0, h[2]=0, h[3]=0, h[4]=1, h[5]=0
      expect(h[0], closeTo(1.0, 1e-10));
      expect(h[1], closeTo(0.0, 1e-10));
      expect(h[2], closeTo(0.0, 1e-10));
      expect(h[3], closeTo(0.0, 1e-10));
      expect(h[4], closeTo(1.0, 1e-10));
      expect(h[5], closeTo(0.0, 1e-10));
    });

    test('computeHomography handles scaled mapping', () {
      // Scale by 2x
      final src = [
        const Offset(0, 0),
        const Offset(2, 0),
        const Offset(2, 2),
        const Offset(0, 2),
      ];
      final dst = [
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(1, 1),
        const Offset(0, 1),
      ];

      final h = PerspectiveCropEngine.computeHomography(src, dst);

      // Verify a mapped point: (2,2) in src should map to (1,1) in dst
      final x = 2.0, y = 2.0;
      final w = h[6] * x + h[7] * y + 1.0;
      final mappedX = (h[0] * x + h[1] * y + h[2]) / w;
      final mappedY = (h[3] * x + h[4] * y + h[5]) / w;

      expect(mappedX, closeTo(1.0, 1e-10));
      expect(mappedY, closeTo(1.0, 1e-10));
    });

    test('solveLinearSystem solves 2x2 system', () {
      // 2x + y = 5
      // x + 3y = 10
      final a = [
        [2.0, 1.0],
        [1.0, 3.0],
      ];
      final b = [5.0, 10.0];

      final x = PerspectiveCropEngine.solveLinearSystem(a, b);

      expect(x[0], closeTo(1.0, 1e-10));
      expect(x[1], closeTo(3.0, 1e-10));
    });

    test('solveLinearSystem solves 3x3 system', () {
      // x + y + z = 6
      // 2x + y + z = 9  =>  x=3
      // x + 2y + z = 8  =>  y=2, z=1
      final a = [
        [1.0, 1.0, 1.0],
        [2.0, 1.0, 1.0],
        [1.0, 2.0, 1.0],
      ];
      final b = [6.0, 9.0, 8.0];

      final x = PerspectiveCropEngine.solveLinearSystem(a, b);

      expect(x[0], closeTo(3.0, 1e-10));
      expect(x[1], closeTo(2.0, 1e-10));
      expect(x[2], closeTo(1.0, 1e-10));
    });
  });

  group('PerspectiveCropPage', () {
    testWidgets('renders with required imagePath', (tester) async {
      // We can't fully render without a real image file, but we can verify
      // the widget instantiates without crashing by checking its properties.
      const page = PerspectiveCropPage(imagePath: '/fake/path.jpg');

      expect(page.imagePath, '/fake/path.jpg');
      expect(page.title, 'Crop Image');
      expect(page.backgroundColor, Colors.black);
      expect(page.resetLabel, 'Reset');
      expect(page.cropLabel, 'Crop');
    });

    test('PerspectiveCropPage accepts custom parameters', () {
      const page = PerspectiveCropPage(
        imagePath: '/test.jpg',
        title: 'Custom Title',
        backgroundColor: Colors.white,
        resetLabel: 'Start Over',
        cropLabel: 'Apply',
        handleRadius: 15.0,
        touchSlop: 80.0,
      );

      expect(page.imagePath, '/test.jpg');
      expect(page.title, 'Custom Title');
      expect(page.backgroundColor, Colors.white);
      expect(page.resetLabel, 'Start Over');
      expect(page.cropLabel, 'Apply');
      expect(page.handleRadius, 15.0);
      expect(page.touchSlop, 80.0);
    });
  });
}