import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ViralShareService {
  /// Captures a [GlobalKey] attached to a [RepaintBoundary] as PNG bytes.
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Render at 3x pixel ratio for crisp export quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Saves [bytes] to a temp file and triggers the system share sheet.
  static Future<void> shareGlowUpCard(
    Uint8List bytes, {
    String text = '🔥 My Glow-Up Journey — powered by GrowUp AI #GlowUp #Lookmaxxing',
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/growup_share_card.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: text,
      subject: 'My Glow-Up Card 🚀',
    );
  }
}
