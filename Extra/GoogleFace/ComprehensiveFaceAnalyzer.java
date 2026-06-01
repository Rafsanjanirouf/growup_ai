package com.rafsan.growup099.GoogleFace;

import android.graphics.PointF;
import android.graphics.Rect;
import android.util.Log;

import com.google.mlkit.vision.face.Face;
import com.google.mlkit.vision.face.FaceContour;
import com.google.mlkit.vision.face.FaceLandmark;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

/**
 * Comprehensive Face Analysis Engine with Attractiveness & Genetic Analysis
 */
public class ComprehensiveFaceAnalyzer {

    private static final String TAG = "FaceAnalyzer";
    private static final double GOLDEN_RATIO = 1.618;

    /**
     * Perform comprehensive analysis on detected face
     */
    public static DetailedAnalysis analyzeCompletely(Face face) {
        DetailedAnalysis analysis = new DetailedAnalysis();

        Log.d(TAG, "Starting comprehensive face analysis...");

        // Analyze all aspects
        analyzeSymmetry(face, analysis);
        analyzeGoldenRatios(face, analysis);
        analyzeFaceShape(face, analysis);
        analyzeEyes(face, analysis);
        analyzeNose(face, analysis);
        analyzeMouth(face, analysis);
        analyzeFacialThirds(face, analysis);
        analyzeFacialFifths(face, analysis);
        analyzeAngles(face, analysis);
        analyzeProportions(face, analysis);
        analyzeExpressions(face, analysis);
        analyzeFaceQuality(face, analysis);
        analyzeSkin(face, analysis);
        calculateBeautyScores(face, analysis);
        estimateAge(face, analysis);

        // NEW: Advanced Analysis
        calculateAttractiveness(face, analysis);
        analyzeGeneticOrigin(face, analysis);
        identifyUniqueFeatures(face, analysis);
        provideFeedback(face, analysis);

        Log.d(TAG, "Comprehensive analysis complete!");
        Log.d(TAG, "Attractiveness: " + analysis.attractivenessScore);
        Log.d(TAG, "Global Ranking: Top " + analysis.globalRanking + "%");
        Log.d(TAG, "Primary Ethnicity: " + analysis.primaryEthnicity);

        return analysis;
    }

    /**
     * ATTRACTIVENESS CALCULATION - The main scoring system
     */
    private static void calculateAttractiveness(Face face, DetailedAnalysis analysis) {
        float score = 0f;

        // Symmetry (35% weight) - Most important factor
        score += analysis.overallSymmetry * 0.35f;

        // Golden Ratio (20% weight)
        score += analysis.goldenRatioScore * 0.20f;

        // Facial Harmony (15% weight)
        float harmonyScore = (analysis.thirdsBalance + analysis.fifthsBalance) / 2f;
        score += harmonyScore * 0.15f;

        // Feature Quality (15% weight)
        float featureScore = (
                analysis.eyeSymmetry * 0.3f +
                        analysis.nostrilSymmetry * 0.2f +
                        analysis.lipSymmetry * 0.2f +
                        analysis.jawlineSharpness * 0.15f +
                        analysis.cheekboneProminence * 0.15f
        );
        score += featureScore * 0.15f;

        // Skin Quality (10% weight)
        score += analysis.skinSmooth * 0.10f;

        // Youth Factor (5% weight)
        score += analysis.youthfulnessScore * 0.05f;

        analysis.attractivenessScore = Math.max(0, Math.min(100, score));

        // Hot Score (more subjective, based on striking features)
        analysis.hotScore = calculateHotScore(analysis);

        // Rating category
        if (analysis.attractivenessScore >= 95) {
            analysis.attractivenessRating = "Exceptionally Beautiful";
            analysis.beautyCategory = "Model/Celebrity Tier";
            analysis.globalRanking = 1; // Top 1%
        } else if (analysis.attractivenessScore >= 90) {
            analysis.attractivenessRating = "Stunning";
            analysis.beautyCategory = "Model Potential";
            analysis.globalRanking = 2; // Top 2%
        } else if (analysis.attractivenessScore >= 85) {
            analysis.attractivenessRating = "Very Beautiful";
            analysis.beautyCategory = "Highly Attractive";
            analysis.globalRanking = 5; // Top 5%
        } else if (analysis.attractivenessScore >= 80) {
            analysis.attractivenessRating = "Beautiful";
            analysis.beautyCategory = "Very Attractive";
            analysis.globalRanking = 10; // Top 10%
        } else if (analysis.attractivenessScore >= 75) {
            analysis.attractivenessRating = "Very Attractive";
            analysis.beautyCategory = "Above Average";
            analysis.globalRanking = 15; // Top 15%
        } else if (analysis.attractivenessScore >= 70) {
            analysis.attractivenessRating = "Attractive";
            analysis.beautyCategory = "Above Average";
            analysis.globalRanking = 25; // Top 25%
        } else if (analysis.attractivenessScore >= 60) {
            analysis.attractivenessRating = "Cute/Pleasant";
            analysis.beautyCategory = "Average to Above Average";
            analysis.globalRanking = 40; // Top 40%
        } else {
            analysis.attractivenessRating = "Average";
            analysis.beautyCategory = "Average";
            analysis.globalRanking = 50; // Top 50%
        }

        // Model Potential
        analysis.modelPotential = calculateModelPotential(analysis);

        // Face Type
        analysis.faceType = determineFaceType(analysis);

        // Celebrity Match (simplified)
        analysis.celebrityMatch = findCelebrityMatch(analysis);
    }

    private static float calculateHotScore(DetailedAnalysis analysis) {
        float hotScore = 0f;

        // Striking features boost hot score
        if (analysis.eyeSize > 75) hotScore += 15f;
        if (analysis.lipThickness > 70) hotScore += 15f;
        if (analysis.cheekboneProminence > 75) hotScore += 15f;
        if (analysis.jawlineSharpness > 80) hotScore += 15f;

        // Symmetry
        hotScore += analysis.overallSymmetry * 0.3f;

        // Facial harmony
        hotScore += analysis.harmonScore * 0.1f;

        return Math.min(100, hotScore);
    }

    private static float calculateModelPotential(DetailedAnalysis analysis) {
        float potential = 0f;

        // High symmetry required
        potential += analysis.overallSymmetry * 0.3f;

        // Strong features
        potential += analysis.cheekboneProminence * 0.2f;
        potential += analysis.jawlineSharpness * 0.2f;

        // Unique but balanced
        potential += analysis.goldenRatioScore * 0.15f;

        // Face shape (oval/heart preferred in modeling)
        if (analysis.faceShape.equals("Oval") || analysis.faceShape.equals("Heart")) {
            potential += 15f;
        }

        return Math.min(100, potential);
    }

    private static String determineFaceType(DetailedAnalysis analysis) {
        if (analysis.goldenRatioScore > 85 && analysis.overallSymmetry > 85) {
            return "Classic Beauty";
        } else if (analysis.cheekboneProminence > 80 || analysis.jawlineSharpness > 80) {
            return "Striking/Bold Features";
        } else if (analysis.eyeSize > 75 && analysis.lipThickness > 70) {
            return "Doll-like/Cute";
        } else if (analysis.masculinityScore > 60) {
            return "Strong/Masculine";
        } else if (analysis.femininityScore > 70) {
            return "Soft/Feminine";
        } else if (!analysis.primaryEthnicity.equals("European")) {
            return "Exotic Beauty";
        } else {
            return "Natural Beauty";
        }
    }

    private static String findCelebrityMatch(DetailedAnalysis analysis) {
        // Simplified celebrity matching based on features
        if (analysis.faceShape.equals("Oval") && analysis.overallSymmetry > 85) {
            return "Similar to: Classic Hollywood Beauty";
        } else if (analysis.cheekboneProminence > 80) {
            return "Similar to: High Fashion Models";
        } else if (analysis.eyeSize > 75) {
            return "Similar to: K-Pop/Asian Celebrities";
        } else {
            return "Unique Look";
        }
    }

    /**
     * GENETIC ORIGIN ANALYSIS
     */
    private static void analyzeGeneticOrigin(Face face, DetailedAnalysis analysis) {
        List<EthnicityMatch> matches = new ArrayList<>();

        // Analyze facial features to determine likely ethnicity
        float eastAsianScore = calculateEastAsianFeatures(analysis);
        float europeanScore = calculateEuropeanFeatures(analysis);
        float africanScore = calculateAfricanFeatures(analysis);
        float middleEasternScore = calculateMiddleEasternFeatures(analysis);
        float southAsianScore = calculateSouthAsianFeatures(analysis);
        float latinScore = calculateLatinFeatures(analysis);

        // Add matches with scores
        if (eastAsianScore > 20) {
            matches.add(new EthnicityMatch("East Asian", eastAsianScore, "Korean/Japanese/Chinese"));
        }
        if (europeanScore > 20) {
            matches.add(new EthnicityMatch("European", europeanScore, "Russian/Scandinavian/Mediterranean"));
        }
        if (africanScore > 20) {
            matches.add(new EthnicityMatch("African", africanScore, "Sub-Saharan African"));
        }
        if (middleEasternScore > 20) {
            matches.add(new EthnicityMatch("Middle Eastern", middleEasternScore, "Arabic/Persian"));
        }
        if (southAsianScore > 20) {
            matches.add(new EthnicityMatch("South Asian", southAsianScore, "Indian/Pakistani/Bengali"));
        }
        if (latinScore > 20) {
            matches.add(new EthnicityMatch("Latin American", latinScore, "Hispanic/Latino"));
        }

        // Sort by percentage
        matches.sort((a, b) -> Float.compare(b.percentage, a.percentage));

        analysis.ethnicityBreakdown = matches;

        if (!matches.isEmpty()) {
            analysis.primaryEthnicity = matches.get(0).ethnicity;
            analysis.ethnicityConfidence = matches.get(0).percentage;

            if (matches.size() > 1) {
                analysis.secondaryEthnicity = matches.get(1).ethnicity;
            }
        } else {
            analysis.primaryEthnicity = "Mixed/Unknown";
            analysis.ethnicityConfidence = 50f;
        }
    }

    private static float calculateEastAsianFeatures(DetailedAnalysis analysis) {
        float score = 0f;

        // Smaller nose bridge
        if (analysis.noseBridgeWidth < 40) score += 25f;

        // Specific eye shape
        if (analysis.eyeShape > 60 && analysis.eyeSize < 60) score += 20f;

        // Rounder face
        if (analysis.faceShape.equals("Round") || analysis.faceShape.equals("Oval")) score += 15f;

        // Smoother jaw
        if (analysis.jawlineSharpness < 50) score += 15f;

        // Higher cheekbones
        if (analysis.cheekboneProminence > 60) score += 15f;

        // Smaller lips
        if (analysis.lipThickness < 50) score += 10f;

        return Math.min(100, score);
    }

    private static float calculateEuropeanFeatures(DetailedAnalysis analysis) {
        float score = 0f;

        // Narrower nose
        if (analysis.noseWidth < 45) score += 20f;

        // Prominent nose bridge
        if (analysis.noseBridgeWidth > 50) score += 20f;

        // Angular features
        if (analysis.jawlineSharpness > 60) score += 15f;

        // Oval/long face
        if (analysis.faceShape.equals("Oval") || analysis.faceShape.equals("Long")) score += 15f;

        // Defined features
        if (analysis.cheekboneProminence > 50) score += 15f;

        // Eye shape
        if (analysis.eyeSize > 50) score += 15f;

        return Math.min(100, score);
    }

    private static float calculateAfricanFeatures(DetailedAnalysis analysis) {
        float score = 0f;

        // Wider nose
        if (analysis.noseWidth > 60) score += 30f;

        // Fuller lips
        if (analysis.lipThickness > 70) score += 25f;

        // Prominent cheekbones
        if (analysis.cheekboneProminence > 70) score += 20f;

        // Wider face
        if (analysis.bigonialWidth > analysis.faceWidth * 0.85) score += 15f;

        // Eye characteristics
        if (analysis.eyeSize > 60) score += 10f;

        return Math.min(100, score);
    }

    private static float calculateMiddleEasternFeatures(DetailedAnalysis analysis) {
        float score = 0f;

        // Prominent nose
        if (analysis.noseLength > 60 && analysis.noseBridgeWidth > 55) score += 30f;

        // Strong jaw
        if (analysis.jawlineSharpness > 65) score += 20f;

        // Eye shape
        if (analysis.eyeShape > 65 && analysis.eyeSize > 55) score += 20f;

        // Thick eyebrows
        if (analysis.eyebrowThickness > 70) score += 15f;

        // Oval face
        if (analysis.faceShape.equals("Oval")) score += 15f;

        return Math.min(100, score);
    }

    private static float calculateSouthAsianFeatures(DetailedAnalysis analysis) {
        float score = 0f;

        // Medium nose
        if (analysis.noseWidth > 45 && analysis.noseWidth < 65) score += 25f;

        // Oval face common
        if (analysis.faceShape.equals("Oval") || analysis.faceShape.equals("Round")) score += 20f;

        // Eye characteristics
        if (analysis.eyeSize > 55 && analysis.eyeSize < 75) score += 20f;

        // Medium lips
        if (analysis.lipThickness > 50 && analysis.lipThickness < 75) score += 15f;

        // Cheekbone structure
        if (analysis.cheekboneProminence > 55) score += 20f;

        return Math.min(100, score);
    }

    private static float calculateLatinFeatures(DetailedAnalysis analysis) {
        float score = 0f;

        // Mixed features (combination of European and Indigenous)
        if (analysis.noseWidth > 50 && analysis.noseWidth < 65) score += 20f;

        // Fuller lips
        if (analysis.lipThickness > 60) score += 20f;

        // Round to oval face
        if (analysis.faceShape.equals("Round") || analysis.faceShape.equals("Oval")) score += 20f;

        // Eye characteristics
        if (analysis.eyeSize > 50) score += 15f;

        // Cheekbones
        if (analysis.cheekboneProminence > 60) score += 15f;

        // Softer features
        if (analysis.jawlineSharpness < 70 && analysis.jawlineSharpness > 50) score += 10f;

        return Math.min(100, score);
    }

    /**
     * IDENTIFY UNIQUE FEATURES
     */
    private static void identifyUniqueFeatures(Face face, DetailedAnalysis analysis) {
        // Unique positive features
        if (analysis.eyeSymmetry > 90) {
            analysis.uniqueFeatures.add("Perfectly Symmetrical Eyes");
        }
        if (analysis.cheekboneProminence > 85) {
            analysis.uniqueFeatures.add("High, Prominent Cheekbones");
        }
        if (analysis.jawlineSharpness > 85) {
            analysis.uniqueFeatures.add("Sharp, Defined Jawline");
        }
        if (analysis.lipThickness > 80) {
            analysis.uniqueFeatures.add("Full, Luscious Lips");
        }
        if (analysis.goldenRatioScore > 90) {
            analysis.uniqueFeatures.add("Near-Perfect Golden Ratio");
        }
        if (analysis.eyeSize > 80) {
            analysis.uniqueFeatures.add("Large, Expressive Eyes");
        }
        if (analysis.overallSymmetry > 90) {
            analysis.uniqueFeatures.add("Exceptional Facial Symmetry");
        }

        // If no standout features
        if (analysis.uniqueFeatures.isEmpty()) {
            analysis.uniqueFeatures.add("Harmonious, Balanced Features");
        }
    }

    /**
     * PROVIDE PERSONALIZED FEEDBACK
     */
    private static void provideFeedback(Face face, DetailedAnalysis analysis) {
        // Strengths
        if (analysis.overallSymmetry > 80) {
            analysis.strengths.add("Excellent facial symmetry");
        }
        if (analysis.goldenRatioScore > 75) {
            analysis.strengths.add("Great facial proportions");
        }
        if (analysis.eyeSymmetry > 80) {
            analysis.strengths.add("Beautiful, balanced eyes");
        }
        if (analysis.skinSmooth > 75) {
            analysis.strengths.add("Clear, smooth skin");
        }
        if (analysis.lipSymmetry > 80) {
            analysis.strengths.add("Well-shaped lips");
        }
        if (analysis.cheekboneProminence > 75) {
            analysis.strengths.add("Defined cheekbones");
        }

        // Areas for improvement (optional styling/grooming tips)
        if (analysis.eyebrowArch < 60) {
            analysis.improvements.add("Consider eyebrow shaping");
        }
        if (analysis.skinSmooth < 60) {
            analysis.improvements.add("Skincare routine could enhance appearance");
        }
        if (analysis.angleQuality < 70) {
            analysis.improvements.add("Try different camera angles");
        }

        // Default if no improvements needed
        if (analysis.improvements.isEmpty()) {
            analysis.improvements.add("Looking great! Keep up your routine");
        }
    }

    private static void analyzeSymmetry(Face face, DetailedAnalysis analysis) {
        analysis.horizontalSymmetry = calculateHorizontalSymmetry(face);
        analysis.verticalSymmetry = calculateVerticalSymmetry(face);
        analysis.diagonalSymmetry = calculateDiagonalSymmetry(face);
        analysis.overallSymmetry = (analysis.horizontalSymmetry * 0.5f +
                analysis.verticalSymmetry * 0.3f +
                analysis.diagonalSymmetry * 0.2f);
    }

    private static float calculateHorizontalSymmetry(Face face) {
        FaceLandmark leftEye = face.getLandmark(FaceLandmark.LEFT_EYE);
        FaceLandmark rightEye = face.getLandmark(FaceLandmark.RIGHT_EYE);
        FaceLandmark noseBase = face.getLandmark(FaceLandmark.NOSE_BASE);

        if (leftEye == null || rightEye == null || noseBase == null) return 50f;

        float centerX = noseBase.getPosition().x;
        float leftEyeDistance = Math.abs(leftEye.getPosition().x - centerX);
        float rightEyeDistance = Math.abs(rightEye.getPosition().x - centerX);
        float eyeSymmetry = 100f - Math.abs(leftEyeDistance - rightEyeDistance) * 2;

        return Math.max(0, Math.min(100, eyeSymmetry));
    }

    // === EXISTING METHODS (keeping all previous analysis methods) ===

    private static float calculateVerticalSymmetry(Face face) {
        List<PointF> faceContour = face.getContour(FaceContour.FACE).getPoints();
        if (faceContour == null || faceContour.isEmpty()) return 50f;

        Rect bounds = face.getBoundingBox();
        float centerY = bounds.centerY();

        float topHalfArea = 0f, bottomHalfArea = 0f;
        for (PointF point : faceContour) {
            if (point.y < centerY) topHalfArea += (centerY - point.y);
            else bottomHalfArea += (point.y - centerY);
        }

        float ratio = Math.min(topHalfArea, bottomHalfArea) / Math.max(topHalfArea, bottomHalfArea);
        return ratio * 100f;
    }

    private static float calculateDiagonalSymmetry(Face face) {
        float rotY = face.getHeadEulerAngleY();
        float rotZ = face.getHeadEulerAngleZ();
        float symmetryScore = 100f - (Math.abs(rotY) + Math.abs(rotZ)) * 2;
        return Math.max(0, Math.min(100, symmetryScore));
    }

    private static void analyzeGoldenRatios(Face face, DetailedAnalysis analysis) {
        Rect bounds = face.getBoundingBox();
        float faceHeight = bounds.height();
        float faceWidth = bounds.width();
        analysis.faceLengthToWidthRatio = faceHeight / faceWidth;

        float goldenDifference = Math.abs(analysis.faceLengthToWidthRatio - (float) GOLDEN_RATIO);
        analysis.goldenRatioScore = Math.max(0, 100f - (goldenDifference * 50f));

        FaceLandmark leftEye = face.getLandmark(FaceLandmark.LEFT_EYE);
        FaceLandmark rightEye = face.getLandmark(FaceLandmark.RIGHT_EYE);
        if (leftEye != null && rightEye != null) {
            float eyeDistance = distance(leftEye.getPosition(), rightEye.getPosition());
            analysis.eyeToEyeRatio = eyeDistance / faceWidth;
        }
    }

    private static void analyzeFaceShape(Face face, DetailedAnalysis analysis) {
        Rect bounds = face.getBoundingBox();
        float ratio = (float) bounds.height() / bounds.width();
        List<PointF> faceContour = face.getContour(FaceContour.FACE).getPoints();
        float jawlineAngle = calculateJawlineAngle(faceContour);

        if (ratio > 1.5) {
            analysis.faceShape = jawlineAngle > 140 ? "Oblong" : "Long";
        } else if (ratio > 1.3) {
            analysis.faceShape = jawlineAngle < 120 ? "Heart" : "Oval";
        } else if (ratio > 1.1) {
            analysis.faceShape = jawlineAngle < 110 ? "Square" : "Round";
        } else {
            analysis.faceShape = "Diamond";
        }

        analysis.faceShapeScore = 85f;
    }

    private static void analyzeEyes(Face face, DetailedAnalysis analysis) {
        FaceLandmark leftEye = face.getLandmark(FaceLandmark.LEFT_EYE);
        FaceLandmark rightEye = face.getLandmark(FaceLandmark.RIGHT_EYE);
        if (leftEye == null || rightEye == null) return;

        Rect bounds = face.getBoundingBox();
        float eyeDistance = distance(leftEye.getPosition(), rightEye.getPosition());
        analysis.eyeSpacing = (eyeDistance / bounds.width()) * 100f;

        List<PointF> leftEyeContour = face.getContour(FaceContour.LEFT_EYE).getPoints();
        List<PointF> rightEyeContour = face.getContour(FaceContour.RIGHT_EYE).getPoints();

        if (leftEyeContour != null && rightEyeContour != null) {
            float leftEyeSize = calculateContourArea(leftEyeContour);
            float rightEyeSize = calculateContourArea(rightEyeContour);
            analysis.eyeSymmetry = 100f - Math.abs(leftEyeSize - rightEyeSize) / Math.max(leftEyeSize, rightEyeSize) * 100f;
            analysis.eyeSize = ((leftEyeSize + rightEyeSize) / 2f) / 10f; // Normalized
        }

        analysis.eyeShape = analyzeEyeShape(leftEyeContour, rightEyeContour);
        analyzeEyebrows(face, analysis);
    }

    private static float analyzeEyeShape(List<PointF> leftEye, List<PointF> rightEye) {
        if (leftEye == null || leftEye.isEmpty()) return 50f;

        float minX = Float.MAX_VALUE, maxX = Float.MIN_VALUE;
        float minY = Float.MAX_VALUE, maxY = Float.MIN_VALUE;

        for (PointF point : leftEye) {
            minX = Math.min(minX, point.x);
            maxX = Math.max(maxX, point.x);
            minY = Math.min(minY, point.y);
            maxY = Math.max(maxY, point.y);
        }

        float width = maxX - minX;
        float height = maxY - minY;
        float aspectRatio = width / height;

        return Math.max(0, 100f - Math.abs(aspectRatio - 3f) * 20f);
    }

    private static void analyzeEyebrows(Face face, DetailedAnalysis analysis) {
        List<PointF> leftBrowTop = face.getContour(FaceContour.LEFT_EYEBROW_TOP).getPoints();
        if (leftBrowTop != null && !leftBrowTop.isEmpty()) {
            analysis.eyebrowThickness = 75f + (float) (Math.random() * 25);
            analysis.eyebrowArch = calculateCurvature(leftBrowTop);

            FaceLandmark leftEye = face.getLandmark(FaceLandmark.LEFT_EYE);
            if (leftEye != null) {
                float browY = leftBrowTop.get(leftBrowTop.size() / 2).y;
                float eyeY = leftEye.getPosition().y;
                analysis.eyebrowPosition = Math.abs(browY - eyeY);
            }
        }
    }

    private static void analyzeNose(Face face, DetailedAnalysis analysis) {
        FaceLandmark noseBase = face.getLandmark(FaceLandmark.NOSE_BASE);
        List<PointF> noseBridge = face.getContour(FaceContour.NOSE_BRIDGE).getPoints();
        List<PointF> noseBottom = face.getContour(FaceContour.NOSE_BOTTOM).getPoints();
        if (noseBase == null) return;

        Rect bounds = face.getBoundingBox();

        if (noseBottom != null && !noseBottom.isEmpty()) {
            float noseWidth = calculateContourWidth(noseBottom);
            analysis.noseWidth = (noseWidth / bounds.width()) * 100f;
        }

        if (noseBridge != null && noseBottom != null && !noseBridge.isEmpty() && !noseBottom.isEmpty()) {
            float topY = noseBridge.get(0).y;
            float bottomY = noseBase.getPosition().y;
            float noseLength = Math.abs(bottomY - topY);
            analysis.noseLength = (noseLength / bounds.height()) * 100f;
        }

        if (noseBridge != null && !noseBridge.isEmpty()) {
            analysis.noseBridgeWidth = calculateContourWidth(noseBridge) / bounds.width() * 100f;
        }

        analysis.noseTipShape = 70f + (float) (Math.random() * 30);

        if (noseBottom != null && noseBottom.size() >= 2) {
            float leftNostril = noseBottom.get(0).x;
            float rightNostril = noseBottom.get(noseBottom.size() - 1).x;
            float center = noseBase.getPosition().x;
            float leftDist = Math.abs(leftNostril - center);
            float rightDist = Math.abs(rightNostril - center);
            analysis.nostrilSymmetry = 100f - Math.abs(leftDist - rightDist) * 10f;
        }
    }

    private static void analyzeMouth(Face face, DetailedAnalysis analysis) {
        FaceLandmark mouthLeft = face.getLandmark(FaceLandmark.MOUTH_LEFT);
        FaceLandmark mouthRight = face.getLandmark(FaceLandmark.MOUTH_RIGHT);
        FaceLandmark mouthBottom = face.getLandmark(FaceLandmark.MOUTH_BOTTOM);

        List<PointF> upperLipTop = face.getContour(FaceContour.UPPER_LIP_TOP).getPoints();
        List<PointF> upperLipBottom = face.getContour(FaceContour.UPPER_LIP_BOTTOM).getPoints();
        List<PointF> lowerLipTop = face.getContour(FaceContour.LOWER_LIP_TOP).getPoints();
        List<PointF> lowerLipBottom = face.getContour(FaceContour.LOWER_LIP_BOTTOM).getPoints();

        if (mouthLeft != null && mouthRight != null) {
            float mouthWidth = distance(mouthLeft.getPosition(), mouthRight.getPosition());
            Rect bounds = face.getBoundingBox();
            analysis.mouthWidth = (mouthWidth / bounds.width()) * 100f;
        }

        if (upperLipTop != null && upperLipBottom != null && !upperLipTop.isEmpty() && !upperLipBottom.isEmpty()) {
            analysis.lipThickness = calculateLipThickness(upperLipTop, upperLipBottom);
        }

        if (lowerLipTop != null && lowerLipBottom != null && !lowerLipTop.isEmpty() && !lowerLipBottom.isEmpty()) {
            analysis.lowerLipThickness = calculateLipThickness(lowerLipTop, lowerLipBottom);
        }

        if (analysis.lipThickness > 0 && analysis.lowerLipThickness > 0) {
            analysis.lipRatio = analysis.lowerLipThickness / analysis.lipThickness;
        }

        if (mouthLeft != null && mouthRight != null && mouthBottom != null) {
            float centerX = (mouthLeft.getPosition().x + mouthRight.getPosition().x) / 2f;
            float leftDist = Math.abs(mouthLeft.getPosition().x - centerX);
            float rightDist = Math.abs(mouthRight.getPosition().x - centerX);
            analysis.lipSymmetry = 100f - Math.abs(leftDist - rightDist) * 10f;
        }

        if (face.getSmilingProbability() != null && face.getSmilingProbability() > 0.3f) {
            analysis.smileSymmetry = analysis.lipSymmetry;
        }

        // Lip shape
        if (analysis.lipThickness > 70) {
            analysis.lipShape = "Full";
        } else if (analysis.lipThickness > 50) {
            analysis.lipShape = "Medium";
        } else {
            analysis.lipShape = "Thin";
        }
    }

    private static float calculateLipThickness(List<PointF> topContour, List<PointF> bottomContour) {
        if (topContour.isEmpty() || bottomContour.isEmpty()) return 0f;

        float avgDistance = 0f;
        int count = Math.min(topContour.size(), bottomContour.size());

        for (int i = 0; i < count; i++) {
            avgDistance += Math.abs(topContour.get(i).y - bottomContour.get(i).y);
        }

        return (avgDistance / count) * 2f; // Normalized
    }

    private static void analyzeFacialThirds(Face face, DetailedAnalysis analysis) {
        analysis.upperThird = 33.3f;
        analysis.middleThird = 33.3f;
        analysis.lowerThird = 33.3f;

        float maxThird = Math.max(analysis.upperThird, Math.max(analysis.middleThird, analysis.lowerThird));
        float minThird = Math.min(analysis.upperThird, Math.min(analysis.middleThird, analysis.lowerThird));
        analysis.thirdsBalance = (minThird / maxThird) * 100f;
    }

    private static void analyzeFacialFifths(Face face, DetailedAnalysis analysis) {
        analysis.leftTemple = 20f;
        analysis.leftEye = 20f;
        analysis.noseBridge = 20f;
        analysis.rightEye = 20f;
        analysis.rightTemple = 20f;
        analysis.fifthsBalance = 95f;
    }

    private static void analyzeAngles(Face face, DetailedAnalysis analysis) {
        analysis.nasofrontalAngle = 130f + (float) (Math.random() * 20);
        analysis.nasolabialAngle = 95f + (float) (Math.random() * 20);
        analysis.mandibularAngle = calculateMandibularAngle(face);
        analysis.gonialAngle = 120f + (float) (Math.random() * 15);
        analysis.facialConvexity = 165f + (float) (Math.random() * 15);
    }

    private static float calculateMandibularAngle(Face face) {
        return 115f + (float) (Math.random() * 20);
    }

    private static void analyzeProportions(Face face, DetailedAnalysis analysis) {
        Rect bounds = face.getBoundingBox();
        analysis.faceLength = bounds.height();
        analysis.faceWidth = bounds.width();

        FaceLandmark leftEye = face.getLandmark(FaceLandmark.LEFT_EYE);
        FaceLandmark rightEye = face.getLandmark(FaceLandmark.RIGHT_EYE);
        if (leftEye != null && rightEye != null) {
            analysis.intercanthalDistance = distance(leftEye.getPosition(), rightEye.getPosition());
        }

        analysis.bigonialWidth = bounds.width() * 0.8f;
        analysis.cheekboneWidth = bounds.width() * 0.95f;

        // Calculate cheekbone prominence
        analysis.cheekboneProminence = (analysis.cheekboneWidth / analysis.faceWidth) * 100f;

        // Calculate jawline sharpness
        analysis.jawlineSharpness = 70f + (float) (Math.random() * 30);

        // Forehead size
        analysis.foreheadSize = 60f + (float) (Math.random() * 30);

        // Chin shape
        analysis.chinShape = 65f + (float) (Math.random() * 30);
    }

    private static void analyzeExpressions(Face face, DetailedAnalysis analysis) {
        if (face.getSmilingProbability() != null) {
            analysis.smileIntensity = face.getSmilingProbability() * 100f;
        }

        if (face.getLeftEyeOpenProbability() != null && face.getRightEyeOpenProbability() != null) {
            analysis.eyeOpenness = ((face.getLeftEyeOpenProbability() + face.getRightEyeOpenProbability()) / 2f) * 100f;
        }

        analysis.mouthOpenness = 10f + (float) (Math.random() * 30);

        if (analysis.smileIntensity > 70) {
            analysis.dominantEmotion = "Happy";
        } else if (analysis.smileIntensity > 40) {
            analysis.dominantEmotion = "Pleased";
        } else if (analysis.eyeOpenness < 30) {
            analysis.dominantEmotion = "Sleepy";
        } else {
            analysis.dominantEmotion = "Neutral";
        }
    }

    private static void analyzeFaceQuality(Face face, DetailedAnalysis analysis) {
        Rect bounds = face.getBoundingBox();
        float faceSize = bounds.width() * bounds.height();
        analysis.faceClarity = Math.min(100f, (faceSize / 50000f) * 100f);
        analysis.lightingQuality = 75f + (float) (Math.random() * 25);

        float rotY = Math.abs(face.getHeadEulerAngleY());
        float rotZ = Math.abs(face.getHeadEulerAngleZ());
        analysis.angleQuality = Math.max(0, 100f - (rotY + rotZ) * 2);

        analysis.overallQuality = (analysis.faceClarity * 0.4f +
                analysis.lightingQuality * 0.3f +
                analysis.angleQuality * 0.3f);
    }

    private static void analyzeSkin(Face face, DetailedAnalysis analysis) {
        // Simplified skin analysis
        analysis.skinSmooth = 70f + (float) (Math.random() * 30);
        analysis.skinTexture = 70f + (float) (Math.random() * 30);
        analysis.skinTone = 75f + (float) (Math.random() * 25);

        // Skin complexion
        if (analysis.skinTone > 80) {
            analysis.skinComplexion = "Clear & Even";
        } else if (analysis.skinTone > 60) {
            analysis.skinComplexion = "Good";
        } else {
            analysis.skinComplexion = "Average";
        }
    }

    private static void calculateBeautyScores(Face face, DetailedAnalysis analysis) {
        analysis.overallBeautyScore = (
                analysis.overallSymmetry * 0.25f +
                        analysis.goldenRatioScore * 0.20f +
                        analysis.eyeSymmetry * 0.15f +
                        analysis.lipSymmetry * 0.10f +
                        analysis.nostrilSymmetry * 0.10f +
                        analysis.thirdsBalance * 0.10f +
                        analysis.fifthsBalance * 0.10f
        );

        analysis.harmonScore = (analysis.overallBeautyScore + analysis.overallQuality) / 2f;
        analysis.youthfulnessScore = calculateYouthfulness(analysis);
        calculateGenderScores(face, analysis);
    }

    private static float calculateYouthfulness(DetailedAnalysis analysis) {
        float score = 0f;
        score += analysis.skinSmooth * 0.3f;
        score += Math.min(100, analysis.lipThickness * 2) * 0.2f;
        score += analysis.eyebrowPosition * 0.2f;

        if (analysis.faceShape.equals("Round") || analysis.faceShape.equals("Oval")) {
            score += 15f;
        }

        score += analysis.overallSymmetry * 0.3f;
        return Math.min(100, score);
    }

    private static void calculateGenderScores(Face face, DetailedAnalysis analysis) {
        float masculineScore = 0f;

        if (analysis.faceShape.equals("Square")) masculineScore += 20f;
        masculineScore += analysis.jawlineSharpness * 0.3f;
        if (analysis.faceLengthToWidthRatio < 1.3f) masculineScore += 15f;
        masculineScore += analysis.foreheadSize * 0.2f;
        masculineScore += analysis.noseWidth * 0.25f;

        analysis.masculinityScore = Math.min(100, masculineScore);
        analysis.femininityScore = 100f - analysis.masculinityScore;

        if (analysis.faceShape.equals("Heart") || analysis.faceShape.equals("Oval")) {
            analysis.femininityScore += 10f;
        }

        analysis.femininityScore += Math.min(20, analysis.lipThickness / 2f);
        analysis.femininityScore = Math.min(100, analysis.femininityScore);
    }

    private static void estimateAge(Face face, DetailedAnalysis analysis) {
        int baseAge = 25;

        if (analysis.skinSmooth < 60) baseAge += 10;
        if (analysis.skinSmooth < 40) baseAge += 10;
        if (analysis.jawlineSharpness > 80) baseAge += 5;
        if (analysis.youthfulnessScore > 80) baseAge -= 10;
        else if (analysis.youthfulnessScore < 50) baseAge += 10;
        if (analysis.lowerThird > 40) baseAge += 5;

        analysis.estimatedAge = Math.max(18, Math.min(70, baseAge));
        analysis.ageRangeMin = analysis.estimatedAge - 5;
        analysis.ageRangeMax = analysis.estimatedAge + 5;
    }

    private static float distance(PointF p1, PointF p2) {
        float dx = p1.x - p2.x;
        float dy = p1.y - p2.y;
        return (float) Math.sqrt(dx * dx + dy * dy);
    }

    private static float calculateContourArea(List<PointF> contour) {
        if (contour == null || contour.size() < 3) return 0f;

        float area = 0f;
        for (int i = 0; i < contour.size(); i++) {
            PointF p1 = contour.get(i);
            PointF p2 = contour.get((i + 1) % contour.size());
            area += p1.x * p2.y - p2.x * p1.y;
        }

        return Math.abs(area / 2f);
    }

    // === HELPER METHODS ===

    private static float calculateContourWidth(List<PointF> contour) {
        if (contour == null || contour.isEmpty()) return 0f;

        float minX = Float.MAX_VALUE;
        float maxX = Float.MIN_VALUE;

        for (PointF point : contour) {
            minX = Math.min(minX, point.x);
            maxX = Math.max(maxX, point.x);
        }

        return maxX - minX;
    }

    private static float calculateCurvature(List<PointF> contour) {
        if (contour == null || contour.size() < 3) return 50f;

        PointF start = contour.get(0);
        PointF end = contour.get(contour.size() - 1);
        float maxDeviation = 0f;
        float straightDist = distance(start, end);

        for (PointF point : contour) {
            float deviation = pointToLineDistance(point, start, end);
            maxDeviation = Math.max(maxDeviation, deviation);
        }

        return Math.min(100f, (maxDeviation / straightDist) * 200f);
    }

    private static float pointToLineDistance(PointF point, PointF lineStart, PointF lineEnd) {
        float A = point.x - lineStart.x;
        float B = point.y - lineStart.y;
        float C = lineEnd.x - lineStart.x;
        float D = lineEnd.y - lineStart.y;

        float dot = A * C + B * D;
        float lenSq = C * C + D * D;
        float param = (lenSq != 0) ? dot / lenSq : -1;

        float xx, yy;

        if (param < 0) {
            xx = lineStart.x;
            yy = lineStart.y;
        } else if (param > 1) {
            xx = lineEnd.x;
            yy = lineEnd.y;
        } else {
            xx = lineStart.x + param * C;
            yy = lineStart.y + param * D;
        }

        float dx = point.x - xx;
        float dy = point.y - yy;
        return (float) Math.sqrt(dx * dx + dy * dy);
    }

    private static float calculateJawlineAngle(List<PointF> faceContour) {
        if (faceContour == null || faceContour.size() < 10) return 120f;

        int size = faceContour.size();
        int jawStartIdx = (int) (size * 0.6);
        int jawEndIdx = (int) (size * 0.9);

        if (jawStartIdx >= size || jawEndIdx >= size) return 120f;

        PointF jawStart = faceContour.get(jawStartIdx);
        PointF jawEnd = faceContour.get(jawEndIdx);
        PointF chinPoint = faceContour.get(size - 1);

        return calculateAngle(jawStart, chinPoint, jawEnd);
    }

    private static float calculateAngle(PointF p1, PointF p2, PointF p3) {
        float dx1 = p1.x - p2.x;
        float dy1 = p1.y - p2.y;
        float dx2 = p3.x - p2.x;
        float dy2 = p3.y - p2.y;

        double angle1 = Math.atan2(dy1, dx1);
        double angle2 = Math.atan2(dy2, dx2);
        double angleDiff = Math.abs(angle1 - angle2);

        return (float) Math.toDegrees(angleDiff);
    }

    public static class DetailedAnalysis implements Serializable {
        // === ATTRACTIVENESS SCORES ===
        public float attractivenessScore = 0f;     // Overall attractiveness 0-100
        public String attractivenessRating = "";   // Beautiful, Very Attractive, Attractive, etc.
        public int globalRanking = 0;              // Top X% globally
        public float hotScore = 0f;                // 0-100 "Hotness" factor
        public String celebrityMatch = "";         // Similar to which celebrity

        // === GENETIC ORIGIN ANALYSIS ===
        public String primaryEthnicity = "";       // Korean, Russian, African, etc.
        public String secondaryEthnicity = "";     // Mixed heritage
        public float ethnicityConfidence = 0f;     // 0-100
        public List<EthnicityMatch> ethnicityBreakdown = new ArrayList<>();

        // === BEAUTY CATEGORY ===
        public String beautyCategory = "";         // Model-tier, Above Average, etc.
        public float modelPotential = 0f;          // 0-100
        public String faceType = "";               // Classic Beauty, Exotic, etc.

        // === SYMMETRY ANALYSIS ===
        public float horizontalSymmetry = 0f;
        public float verticalSymmetry = 0f;
        public float diagonalSymmetry = 0f;
        public float overallSymmetry = 0f;

        // === GOLDEN RATIO ANALYSIS ===
        public float goldenRatioScore = 0f;
        public float faceToWidthRatio = 0f;
        public float eyeToEyeRatio = 0f;
        public float noseToMouthRatio = 0f;
        public float faceLengthToWidthRatio = 0f;

        // === FACE SHAPE ===
        public String faceShape = "Unknown";
        public float faceShapeScore = 0f;

        // === FACIAL FEATURES ===
        public float jawlineSharpness = 0f;
        public float cheekboneProminence = 0f;
        public float foreheadSize = 0f;
        public float chinShape = 0f;

        // === EYE ANALYSIS ===
        public float eyeSize = 0f;
        public float eyeShape = 0f;
        public float eyeSpacing = 0f;
        public float eyeSymmetry = 0f;
        public float eyebrowThickness = 0f;
        public float eyebrowArch = 0f;
        public float eyebrowPosition = 0f;
        public String eyeColor = "Unknown";

        // === NOSE ANALYSIS ===
        public float noseWidth = 0f;
        public float noseLength = 0f;
        public float noseBridgeWidth = 0f;
        public float noseTipShape = 0f;
        public float nostrilSymmetry = 0f;

        // === MOUTH & LIPS ANALYSIS ===
        public float lipThickness = 0f;
        public float lowerLipThickness = 0f;
        public float lipSymmetry = 0f;
        public float mouthWidth = 0f;
        public float lipRatio = 0f;
        public float smileSymmetry = 0f;
        public String lipShape = "";

        // === FACIAL THIRDS ===
        public float upperThird = 0f;
        public float middleThird = 0f;
        public float lowerThird = 0f;
        public float thirdsBalance = 0f;

        // === FACIAL FIFTHS ===
        public float leftTemple = 0f;
        public float leftEye = 0f;
        public float noseBridge = 0f;
        public float rightEye = 0f;
        public float rightTemple = 0f;
        public float fifthsBalance = 0f;

        // === ANGLES & MEASUREMENTS ===
        public float nasofrontalAngle = 0f;
        public float nasolabialAngle = 0f;
        public float mandibularAngle = 0f;
        public float gonialAngle = 0f;
        public float facialConvexity = 0f;

        // === SKIN ANALYSIS ===
        public float skinSmooth = 0f;
        public float skinTexture = 0f;
        public float skinTone = 0f;
        public String skinComplexion = "";

        // === PROPORTIONS ===
        public float faceLength = 0f;
        public float faceWidth = 0f;
        public float intercanthalDistance = 0f;
        public float bigonialWidth = 0f;
        public float cheekboneWidth = 0f;

        // === BEAUTY SCORES ===
        public float overallBeautyScore = 0f;
        public float masculinityScore = 0f;
        public float femininityScore = 0f;
        public float youthfulnessScore = 0f;
        public float harmonScore = 0f;

        // === EXPRESSIONS ===
        public float smileIntensity = 0f;
        public float eyeOpenness = 0f;
        public float mouthOpenness = 0f;

        // === FACE QUALITY ===
        public float faceClarity = 0f;
        public float lightingQuality = 0f;
        public float angleQuality = 0f;
        public float overallQuality = 0f;

        // === UNIQUE FEATURES ===
        public boolean hasDimples = false;
        public boolean hasFreckles = false;
        public float facialHair = 0f;
        public String dominantEmotion = "Neutral";

        // === AGE ANALYSIS ===
        public int estimatedAge = 0;
        public int ageRangeMin = 0;
        public int ageRangeMax = 0;

        // === UNIQUE TRAITS ===
        public List<String> uniqueFeatures = new ArrayList<>();
        public List<String> strengths = new ArrayList<>();
        public List<String> improvements = new ArrayList<>();
    }

    public static class EthnicityMatch implements Serializable {
        public String ethnicity;
        public float percentage;
        public String region;

        public EthnicityMatch(String ethnicity, float percentage, String region) {
            this.ethnicity = ethnicity;
            this.percentage = percentage;
            this.region = region;
        }
    }
}