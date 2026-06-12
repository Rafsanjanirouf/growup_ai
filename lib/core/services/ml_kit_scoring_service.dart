import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class MLKitScoringService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<Map<String, dynamic>> analyzeFace(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      // If no face found, generate mock fallback data
      return _generateMockData(isFallback: true);
    }

    final face = faces.first;
    return _generateScoresFromFace(face);
  }

  Map<String, dynamic> _generateScoresFromFace(Face face) {
    final random = Random();

    // 1. Posture Score (Derived from Euler Angles)
    // rotY (turning head left/right) and rotZ (tilting head left/right)
    double rotY = face.headEulerAngleY ?? 0;
    double rotZ = face.headEulerAngleZ ?? 0;
    double rotX = face.headEulerAngleX ?? 0; // Looking up/down
    
    double posturePenalty = (rotY.abs() * 1.5) + (rotZ.abs() * 2.0) + (rotX.abs() * 1.0);
    double postureScore = (100.0 - posturePenalty).clamp(50.0, 99.0);

    // 2. Symmetry (Jawline) Score
    // A perfectly straight head (rotY = 0) implies better perceived symmetry.
    double symmetryScore = (95.0 - rotY.abs() - (random.nextDouble() * 5)).clamp(60.0, 98.0);

    // 3. Expression & Eyes
    double smileProb = face.smilingProbability ?? 0.0;
    double leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    double rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
    double eyeAlertness = ((leftEyeOpen + rightEyeOpen) / 2.0 * 100.0).clamp(60.0, 99.0);

    // 4. Aura Score (1 - 10 scale)
    // Great posture + good eye alertness + slight smile = Elite Aura
    double auraBase = 6.0;
    auraBase += (postureScore > 85 ? 1.0 : 0.0);
    auraBase += (symmetryScore > 85 ? 1.0 : 0.0);
    auraBase += (smileProb > 0.4 && smileProb < 0.8 ? 0.8 : 0.0); // Smirk is high aura
    auraBase += (eyeAlertness > 90 ? 0.7 : 0.0);
    double auraScore = (auraBase + (random.nextDouble() * 0.5)).clamp(4.0, 9.9);

    // 5. Approximated/Mocked Scores (Since ML Kit can't detect skin/hotness directly)
    double goldenRatio = (80.0 + random.nextDouble() * 15.0).clamp(60.0, 98.0);
    double cuteness = (70.0 + (smileProb * 20.0) + random.nextDouble() * 10.0).clamp(60.0, 98.0);
    double hotness = (symmetryScore * 0.4 + postureScore * 0.3 + goldenRatio * 0.3).clamp(65.0, 98.0);
    double domScore = (postureScore * 0.5 + (1.0 - smileProb) * 30.0 + 20.0).clamp(50.0, 98.0);
    
    // Skin is purely mocked as requested since ML Kit doesn't detect texture
    double skinTexture = (75.0 + random.nextDouble() * 20.0).clamp(65.0, 98.0);

    double overallScore = (auraScore * 10.0 * 0.4) + (symmetryScore * 0.3) + (postureScore * 0.3);
    overallScore = overallScore.clamp(60.0, 99.0);

    String rating = _computeRating(auraScore * 10);

    return {
      "overall_score": double.parse(overallScore.toStringAsFixed(1)),
      "aura_score": double.parse(auraScore.toStringAsFixed(1)),
      "symmetry_score": double.parse(symmetryScore.toStringAsFixed(1)),
      "golden_ratio_score": double.parse(goldenRatio.toStringAsFixed(1)),
      "cuteness_score": double.parse(cuteness.toStringAsFixed(1)),
      "hotness_score": double.parse(hotness.toStringAsFixed(1)),
      "domination_score": double.parse(domScore.toStringAsFixed(1)),
      "posture_score": double.parse(postureScore.toStringAsFixed(1)),
      "rating": rating,
      "jawline_details": {
        "sharpness": (symmetryScore - random.nextDouble() * 5).round(),
        "definition": (symmetryScore - random.nextDouble() * 4).round()
      },
      "cheekbone_details": {
        "prominence": (goldenRatio - random.nextDouble() * 6).round(),
        "symmetry": symmetryScore.round()
      },
      "eye_details": {
        "alertness": eyeAlertness.round(),
        "symmetry": (95.0 - (leftEyeOpen - rightEyeOpen).abs() * 50).clamp(60, 99).round()
      },
      "nose_details": {
        "symmetry": (symmetryScore + random.nextDouble() * 3).clamp(60, 99).round(),
        "proportion": goldenRatio.round()
      },
      "lip_details": {
        "fullness": (75 + random.nextInt(20)),
        "symmetry": symmetryScore.round()
      },
      "chin_details": {
        "projection": (postureScore - random.nextDouble() * 5).clamp(60, 99).round(),
        "symmetry": symmetryScore.round()
      },
      "skin_details": {
        "texture": skinTexture.round(),
        "clarity": (skinTexture - random.nextDouble() * 4).round()
      },
      "highlights": _generateHighlights(auraScore, postureScore, symmetryScore),
      "suggestions": _generateSuggestions(postureScore, symmetryScore)
    };
  }

  List<String> _generateHighlights(double aura, double posture, double symmetry) {
    List<String> h = [];
    if (aura > 8.0) h.add("Elite aura presence");
    if (posture > 90) h.add("Perfect head alignment");
    if (symmetry > 90) h.add("Excellent facial symmetry");
    if (h.isEmpty) h.add("Good baseline features");
    return h;
  }

  List<String> _generateSuggestions(double posture, double symmetry) {
    List<String> s = [];
    if (posture < 85) s.add("Keep your chin parallel to the floor");
    if (symmetry < 85) s.add("Chew evenly on both sides");
    if (s.isEmpty) s.add("Maintain your current routine");
    return s;
  }

  String _computeRating(double aura100) {
    if (aura100 >= 85) return 'Legendary';
    if (aura100 >= 72) return 'Elite';
    if (aura100 >= 58) return 'Rising';
    return 'Developing';
  }

  Map<String, dynamic> _generateMockData({required bool isFallback}) {
    // If we fail to detect a face, we fallback gracefully
    return {
      "overall_score": 75.0,
      "aura_score": 7.0,
      "symmetry_score": 75.0,
      "golden_ratio_score": 75.0,
      "cuteness_score": 75.0,
      "hotness_score": 75.0,
      "domination_score": 75.0,
      "posture_score": 75.0,
      "rating": "Rising",
      "jawline_details": {"sharpness": 75, "definition": 75},
      "cheekbone_details": {"prominence": 75, "symmetry": 75},
      "eye_details": {"alertness": 75, "symmetry": 75},
      "nose_details": {"symmetry": 75, "proportion": 75},
      "lip_details": {"fullness": 75, "symmetry": 75},
      "chin_details": {"projection": 75, "symmetry": 75},
      "skin_details": {"texture": 75, "clarity": 75},
      "highlights": ["Face partially obscured"],
      "suggestions": ["Ensure good lighting", "Look straight at the camera"]
    };
  }

  void dispose() {
    _faceDetector.close();
  }
}
