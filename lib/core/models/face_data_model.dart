import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Comprehensive Face Data model mirroring the Java "RealFaceData"
class FaceDataModel {
  final Rect boundingBox;
  final double headEulerAngleX; // Pitch
  final double headEulerAngleY; // Yaw
  final double headEulerAngleZ; // Roll
  
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  
  final Map<FaceLandmarkType, Offset> landmarks;
  final Map<FaceContourType, List<Offset>> contours;
  
  final Size imageSize;
  final DateTime timestamp;

  FaceDataModel({
    required this.boundingBox,
    required this.headEulerAngleX,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    required this.landmarks,
    required this.contours,
    required this.imageSize,
    required this.timestamp,
  });

  /// Convert to Map for serialization/storage
  Map<String, dynamic> toMap() {
    return {
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'right': boundingBox.right,
        'bottom': boundingBox.bottom,
      },
      'headRotation': {
        'x': headEulerAngleX,
        'y': headEulerAngleY,
        'z': headEulerAngleZ,
      },
      'probabilities': {
        'smile': smilingProbability,
        'leftEye': leftEyeOpenProbability,
        'rightEye': rightEyeOpenProbability,
      },
      'landmarkCount': landmarks.length,
      'contourCount': contours.length,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Utility to extract rich data from ML Kit Face objects
class FaceDataExtractor {
  static FaceDataModel extract(Face face, Size imageSize) {
    // Extract Landmarks
    final Map<FaceLandmarkType, Offset> extractedLandmarks = {};
    for (final type in FaceLandmarkType.values) {
      final landmark = face.landmarks[type];
      if (landmark != null) {
        extractedLandmarks[type] = Offset(
          landmark.position.x.toDouble(),
          landmark.position.y.toDouble(),
        );
      }
    }

    // Extract Contours
    final Map<FaceContourType, List<Offset>> extractedContours = {};
    for (final type in FaceContourType.values) {
      final contour = face.contours[type];
      if (contour != null) {
        extractedContours[type] = contour.points
            .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
            .toList();
      }
    }

    return FaceDataModel(
      boundingBox: face.boundingBox,
      headEulerAngleX: face.headEulerAngleX ?? 0,
      headEulerAngleY: face.headEulerAngleY ?? 0,
      headEulerAngleZ: face.headEulerAngleZ ?? 0,
      smilingProbability: face.smilingProbability,
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
      landmarks: extractedLandmarks,
      contours: extractedContours,
      imageSize: imageSize,
      timestamp: DateTime.now(),
    );
  }
}
