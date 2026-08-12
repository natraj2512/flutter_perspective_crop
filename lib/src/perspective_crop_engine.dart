import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Engine that performs perspective crop using homography-based transform.
///
/// Uses a subdivided triangle mesh with a proper homography (projective transform)
/// to map each output pixel to its exact source location.
class PerspectiveCropEngine {
  /// Applies perspective crop on [source] image using [quadCorners].
  ///
  /// [quadCorners] must contain exactly 4 [Offset] points in pixel coordinates
  /// representing the corners of the crop region in the source image:
  /// top-left, top-right, bottom-right, bottom-left.
  ///
  /// Returns the cropped [ui.Image] or `null` if the output dimensions are invalid.
  static Future<ui.Image?> apply(
    ui.Image source,
    List<Offset> quadCorners,
  ) async {
    assert(quadCorners.length == 4, 'Exactly 4 corners required');

    final tl = quadCorners[0];
    final tr = quadCorners[1];
    final br = quadCorners[2];
    final bl = quadCorners[3];

    final topWidth = (tr - tl).distance;
    final bottomWidth = (br - bl).distance;
    final leftHeight = (bl - tl).distance;
    final rightHeight = (br - tr).distance;

    final outWidth = max(topWidth, bottomWidth).toInt();
    final outHeight = max(leftHeight, rightHeight).toInt();

    if (outWidth <= 0 || outHeight <= 0) return null;

    final dstPts = [
      Offset(0, 0),
      Offset(outWidth.toDouble(), 0),
      Offset(outWidth.toDouble(), outHeight.toDouble()),
      Offset(0, outHeight.toDouble()),
    ];
    final srcPts = [tl, tr, br, bl];

    final h = computeHomography(dstPts, srcPts);

    const int gridCols = 40;
    const int gridRows = 40;

    final List<Offset> positions = [];
    final List<Offset> texCoords = [];
    final List<int> indices = [];

    for (int row = 0; row <= gridRows; row++) {
      for (int col = 0; col <= gridCols; col++) {
        final u = col / gridCols;
        final v = row / gridRows;

        final outX = u * outWidth;
        final outY = v * outHeight;
        positions.add(Offset(outX, outY));

        final w = h[6] * outX + h[7] * outY + 1.0;
        final srcX = (h[0] * outX + h[1] * outY + h[2]) / w;
        final srcY = (h[3] * outX + h[4] * outY + h[5]) / w;
        texCoords.add(Offset(srcX, srcY));
      }
    }

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final i = row * (gridCols + 1) + col;
        indices.add(i);
        indices.add(i + 1);
        indices.add(i + gridCols + 1);
        indices.add(i + 1);
        indices.add(i + gridCols + 2);
        indices.add(i + gridCols + 1);
      }
    }

    final vertices = ui.Vertices(
      VertexMode.triangles,
      positions,
      textureCoordinates: texCoords,
      indices: indices,
    );

    final identityMatrix = Float64List.fromList([
      1.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0,
    ]);
    final imageShader = ui.ImageShader(
      source,
      TileMode.clamp,
      TileMode.clamp,
      identityMatrix,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawVertices(
      vertices,
      BlendMode.src,
      Paint()
        ..shader = imageShader
        ..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    return await picture.toImage(outWidth, outHeight);
  }

  /// Computes a 3x3 homography matrix (returned as 8 elements, h[8] is 1.0).
  ///
  /// Maps points from [srcPts] to [dstPts] using a projective transform.
  @visibleForTesting
  static List<double> computeHomography(
    List<Offset> srcPts,
    List<Offset> dstPts,
  ) {
    final a = List.generate(8, (_) => List.filled(8, 0.0));
    final b = List.filled(8, 0.0);

    for (int i = 0; i < 4; i++) {
      final sx = srcPts[i].dx, sy = srcPts[i].dy;
      final dx = dstPts[i].dx, dy = dstPts[i].dy;
      final r1 = i * 2, r2 = i * 2 + 1;

      a[r1][0] = sx;
      a[r1][1] = sy;
      a[r1][2] = 1;
      a[r1][3] = 0;
      a[r1][4] = 0;
      a[r1][5] = 0;
      a[r1][6] = -sx * dx;
      a[r1][7] = -sy * dx;
      b[r1] = dx;

      a[r2][0] = 0;
      a[r2][1] = 0;
      a[r2][2] = 0;
      a[r2][3] = sx;
      a[r2][4] = sy;
      a[r2][5] = 1;
      a[r2][6] = -sx * dy;
      a[r2][7] = -sy * dy;
      b[r2] = dy;
    }

    return solveLinearSystem(a, b);
  }

  /// Solves a linear system Ax = b using Gaussian elimination with partial pivoting.
  @visibleForTesting
  static List<double> solveLinearSystem(
    List<List<double>> a,
    List<double> b,
  ) {
    final n = b.length;

    for (int col = 0; col < n; col++) {
      int maxRow = col;
      double maxVal = a[col][col].abs();
      for (int row = col + 1; row < n; row++) {
        if (a[row][col].abs() > maxVal) {
          maxVal = a[row][col].abs();
          maxRow = row;
        }
      }
      if (maxRow != col) {
        final tmpRow = a[col];
        a[col] = a[maxRow];
        a[maxRow] = tmpRow;
        final tmpB = b[col];
        b[col] = b[maxRow];
        b[maxRow] = tmpB;
      }
      for (int row = col + 1; row < n; row++) {
        final factor = a[row][col] / a[col][col];
        for (int j = col; j < n; j++) {
          a[row][j] -= factor * a[col][j];
        }
        b[row] -= factor * b[col];
      }
    }

    final x = List.filled(n, 0.0);
    for (int row = n - 1; row >= 0; row--) {
      double sum = b[row];
      for (int j = row + 1; j < n; j++) {
        sum -= a[row][j] * x[j];
      }
      x[row] = sum / a[row][row];
    }
    return x;
  }
}