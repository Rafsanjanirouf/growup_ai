import 'dart:math';
import '../models/face_data_model.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceAnalysisResult {
  // --- 1. OVERVIEW & PRIMARY ---
  final double attractivenessScore;
  final double modelPotential;
  final String attractivenessRating;
  final String beautyCategory;
  final int globalRanking;
  final double hotScore;

  // --- 2. SYMMETRY & HARMONY ---
  final double overallSymmetry;
  final double horizontalSymmetry;
  final double verticalSymmetry;
  final double diagonalSymmetry;
  final double goldenRatioScore;
  final double harmonyScore;
  final double faceLengthToWidthRatio;
  final String celebrityMatch;

  // --- 3. FACE & EYES ---
  final String faceShape;
  final double faceShapeScore;
  final double eyeSize;
  final double eyeShapeScore;
  final double eyeSymmetry;
  final double eyeSpacing;
  final double eyebrowArch;
  final double eyebrowThickness;
  final double gonialAngle;
  final double mandibularAngle;

  // --- 4. NOSE & LIPS ---
  final double noseTipShape;
  final double noseWidth;
  final double noseLength;
  final double nostrilSymmetry;
  final double lipThickness;
  final double lipSymmetry;
  final String lipShape;
  final double lipRatio;
  final double smileIntensity;
  final double smileSymmetry;
  final double nasolabialAngle;
  final double overallBeautyScore;

  // --- 5. SKIN, AGE & GENETICS ---
  final double skinSmooth;
  final double skinTexture;
  final double skinTone;
  final double faceClarity;
  final double youthfulnessScore;
  final double femininityScore;
  final double masculinityScore;
  final double cheekboneScore;
  final int estimatedAge;
  final String dominantEmotion;
  final String primaryEthnicity;
  final double ethnicityConfidence;
  final List<EthnicityMatch> ethnicityBreakdown;

  // --- 6. FEEDBACK ---
  final List<String> uniqueFeatures;
  final List<String> strengths;
  final List<String> improvements;

  FaceAnalysisResult({
    required this.attractivenessScore,
    required this.modelPotential,
    required this.attractivenessRating,
    required this.beautyCategory,
    required this.globalRanking,
    required this.hotScore,
    required this.overallSymmetry,
    required this.horizontalSymmetry,
    required this.verticalSymmetry,
    required this.diagonalSymmetry,
    required this.goldenRatioScore,
    required this.harmonyScore,
    required this.faceLengthToWidthRatio,
    required this.celebrityMatch,
    required this.faceShape,
    required this.faceShapeScore,
    required this.eyeSize,
    required this.eyeShapeScore,
    required this.eyeSymmetry,
    required this.eyeSpacing,
    required this.eyebrowArch,
    required this.eyebrowThickness,
    required this.gonialAngle,
    required this.mandibularAngle,
    required this.noseTipShape,
    required this.noseWidth,
    required this.noseLength,
    required this.nostrilSymmetry,
    required this.lipThickness,
    required this.lipSymmetry,
    required this.lipShape,
    required this.lipRatio,
    required this.smileIntensity,
    required this.smileSymmetry,
    required this.nasolabialAngle,
    required this.overallBeautyScore,
    required this.skinSmooth,
    required this.skinTexture,
    required this.skinTone,
    required this.faceClarity,
    required this.youthfulnessScore,
    required this.femininityScore,
    required this.masculinityScore,
    required this.cheekboneScore,
    required this.estimatedAge,
    required this.dominantEmotion,
    required this.primaryEthnicity,
    required this.ethnicityConfidence,
    required this.ethnicityBreakdown,
    required this.uniqueFeatures,
    required this.strengths,
    required this.improvements,
  });
}

class EthnicityMatch {
  final String ethnicity;
  final double percentage;
  final String region;

  EthnicityMatch(this.ethnicity, this.percentage, this.region);
}

class FaceAnalyzerEngine {
  static const double goldenRatio = 1.618;

  static FaceAnalysisResult analyze(FaceDataModel data) {
    final rand = Random();

    // 1. CALCULATE SYMMETRY (Simulating Java logic)
    final double hSymmetry = _calculateHorizontalSymmetry(data);
    final double vSymmetry = _calculateVerticalSymmetry(data);
    final double dSymmetry = 88.0 + rand.nextDouble() * 10;
    final double overallSymmetry = (hSymmetry * 0.5 + vSymmetry * 0.3 + dSymmetry * 0.2);

    // 2. GOLDEN RATIO & PROPORTIONS
    final double faceHeight = data.boundingBox.height;
    final double faceWidth = data.boundingBox.width;
    final double faceRatio = faceHeight / faceWidth;
    final double goldenDiff = (faceRatio - goldenRatio).abs();
    final double goldenScore = max(0, 100 - (goldenDiff * 50));
    final double harmonyScore = 75.0 + rand.nextDouble() * 20;

    // 3. FACE & EYES
    final String faceShape = _determineFaceShape(faceRatio, data);
    final double eyeSymmetry = min(100, hSymmetry + 2.0);
    final double eyeSize = 65.0 + rand.nextDouble() * 25;
    final double eyebrowArch = 70.0 + rand.nextDouble() * 20;
    
    // 4. NOSE & LIPS
    final double noseWidth = 40.0 + rand.nextDouble() * 20;
    final double lipThickness = 55.0 + rand.nextDouble() * 30;
    final double lipRatioString = 1.4 + rand.nextDouble() * 0.4;

    // 5. PRIMARY SCORES
    final double attractivenessScore = (overallSymmetry * 0.35) + (goldenScore * 0.20) + (harmonyScore * 0.45);
    final double modelPotential = (overallSymmetry * 0.4) + (goldenScore * 0.3) + (harmonyScore * 0.3);
    
    // 6. CATEGORIES (Exactly matching Java reference)
    String rating = "Average";
    String category = "Standard";
    int rank = 50;
    if (attractivenessScore >= 95) { rating = "Exceptionally Beautiful"; category = "Model Tier"; rank = 1; }
    else if (attractivenessScore >= 90) { rating = "Stunning"; category = "Model Potential"; rank = 2; }
    else if (attractivenessScore >= 80) { rating = "Beautiful"; category = "Highly Attractive"; rank = 10; }
    else if (attractivenessScore >= 70) { rating = "Attractive"; category = "Above Average"; rank = 25; }

    // 7. ETHNICITY SIMULATION
    final breakdown = [
      EthnicityMatch("European", 65.0, "Western Europe"),
      EthnicityMatch("Central Asian", 20.0, "Caucasus"),
      EthnicityMatch("Middle Eastern", 15.0, "Levant"),
    ];

    return FaceAnalysisResult(
      // Overview
      attractivenessScore: attractivenessScore.clamp(0, 100),
      modelPotential: modelPotential.clamp(0, 100),
      attractivenessRating: rating,
      beautyCategory: category,
      globalRanking: rank,
      hotScore: 75.0 + rand.nextDouble() * 20,
      
      // Symmetry
      overallSymmetry: overallSymmetry.clamp(0, 100),
      horizontalSymmetry: hSymmetry.clamp(0, 100),
      verticalSymmetry: vSymmetry.clamp(0, 100),
      diagonalSymmetry: dSymmetry.clamp(0, 100),
      goldenRatioScore: goldenScore.clamp(0, 100),
      harmonyScore: harmonyScore,
      faceLengthToWidthRatio: faceRatio,
      celebrityMatch: "Classic Hollywood Look",
      
      // Face & Eyes
      faceShape: faceShape,
      faceShapeScore: 82.0 + rand.nextDouble() * 10,
      eyeSize: eyeSize,
      eyeShapeScore: 75.0 + rand.nextDouble() * 15,
      eyeSymmetry: eyeSymmetry,
      eyeSpacing: 60.0 + rand.nextDouble() * 30,
      eyebrowArch: eyebrowArch,
      eyebrowThickness: 70.0 + rand.nextDouble() * 20,
      gonialAngle: 120.0 + rand.nextDouble() * 10,
      mandibularAngle: 115.0 + rand.nextDouble() * 15,
      
      // Nose & Lips
      noseTipShape: 75.0 + rand.nextDouble() * 20,
      noseWidth: noseWidth,
      noseLength: 50.0 + rand.nextDouble() * 20,
      nostrilSymmetry: 85.0 + rand.nextDouble() * 10,
      lipThickness: lipThickness,
      lipSymmetry: 88.0 + rand.nextDouble() * 10,
      lipShape: lipThickness > 70 ? "Full" : "Heart",
      lipRatio: lipRatioString,
      smileIntensity: (data.smilingProbability ?? 0.1) * 100,
      smileSymmetry: 90.0 + rand.nextDouble() * 8,
      nasolabialAngle: 95.0 + rand.nextDouble() * 15,
      overallBeautyScore: attractivenessScore,
      
      // Skin, Age & Genetics
      skinSmooth: 78.0 + rand.nextDouble() * 15,
      skinTexture: 82.0 + rand.nextDouble() * 12,
      skinTone: 85.0 + rand.nextDouble() * 10,
      faceClarity: 90.0 + rand.nextDouble() * 10,
      youthfulnessScore: 85.0 + rand.nextDouble() * 10,
      femininityScore: 75.0 + rand.nextDouble() * 20,
      masculinityScore: 80.0 + rand.nextDouble() * 15,
      cheekboneScore: 82.0 + rand.nextDouble() * 12,
      estimatedAge: 22 + rand.nextInt(5),
      dominantEmotion: (data.smilingProbability ?? 0.0) > 0.5 ? "Happy" : "Neutral",
      primaryEthnicity: "European",
      ethnicityConfidence: 65.0,
      ethnicityBreakdown: breakdown,
      
      // Feedback
      uniqueFeatures: ["Strong Jawline", "High Symmetry", "Prominent Cheekbones"],
      strengths: ["Excellent vertical balance", "Healthy skin glow"],
      improvements: ["Slight eyebrow refinement", "Enhance facial leanness"],
    );
  }

  static double _calculateHorizontalSymmetry(FaceDataModel data) {
    final leftEye = data.landmarks[FaceLandmarkType.leftEye];
    final rightEye = data.landmarks[FaceLandmarkType.rightEye];
    final noseBase = data.landmarks[FaceLandmarkType.noseBase];
    if (leftEye == null || rightEye == null || noseBase == null) return 78.0;
    final double centerX = noseBase.dx;
    final double diff = ((leftEye.dx - centerX).abs() - (rightEye.dx - centerX).abs()).abs();
    return max(0, 100 - (diff * 2.5));
  }

  static double _calculateVerticalSymmetry(FaceDataModel data) {
    return 86.0 - (data.headEulerAngleY.abs() * 1.5); 
  }

  static String _determineFaceShape(double ratio, FaceDataModel data) {
    if (ratio > 1.5) return "Oval";
    if (ratio > 1.3) return "Heart";
    if (ratio > 1.1) return "Round";
    return "Square";
  }
}
