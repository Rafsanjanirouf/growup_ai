package com.rafsan.growup099.GoogleFace;


import android.graphics.PointF;
import android.graphics.Rect;
import android.os.Parcel;
import android.os.Parcelable;
import android.util.Log;

import com.google.mlkit.vision.face.Face;
import com.google.mlkit.vision.face.FaceContour;
import com.google.mlkit.vision.face.FaceLandmark;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Real Face Data Analyzer - Only stores actual detected values from ML Kit
 * NO calculations, NO estimations, ONLY real detected data
 */
public class RealFaceDataAnalyzer {

    private static final String TAG = "RealFaceDataAnalyzer";

    /**
     * Extract all real detected data from Face object
     */
    public static RealFaceData extractRealData(Face face, float imageWidth, float imageHeight) {
        RealFaceData data = new RealFaceData();

        try {
            // === BOUNDING BOX DATA ===
            Rect bounds = face.getBoundingBox();
            if (bounds != null) {
                data.boundingBoxLeft = bounds.left;
                data.boundingBoxTop = bounds.top;
                data.boundingBoxRight = bounds.right;
                data.boundingBoxBottom = bounds.bottom;
                data.boundingBoxWidth = bounds.width();
                data.boundingBoxHeight = bounds.height();
                data.boundingBoxCenterX = bounds.centerX();
                data.boundingBoxCenterY = bounds.centerY();
            }

            // === HEAD ROTATION ANGLES ===
            data.headEulerAngleX = face.getHeadEulerAngleX(); // Pitch (up/down)
            data.headEulerAngleY = face.getHeadEulerAngleY(); // Yaw (left/right)
            data.headEulerAngleZ = face.getHeadEulerAngleZ(); // Roll (tilt)

            // === SMILE PROBABILITY ===
            Float smileProb = face.getSmilingProbability();
            if (smileProb != null) {
                data.smilingProbability = smileProb;
                data.hasSmilingProbability = true;
            }

            // === EYE OPEN PROBABILITIES ===
            Float leftEyeProb = face.getLeftEyeOpenProbability();
            if (leftEyeProb != null) {
                data.leftEyeOpenProbability = leftEyeProb;
                data.hasLeftEyeOpenProbability = true;
            }

            Float rightEyeProb = face.getRightEyeOpenProbability();
            if (rightEyeProb != null) {
                data.rightEyeOpenProbability = rightEyeProb;
                data.hasRightEyeOpenProbability = true;
            }

            // === TRACKING ID ===
            Integer trackingId = face.getTrackingId();
            if (trackingId != null) {
                data.trackingId = trackingId;
            }

            // === FACE LANDMARKS (KEY POINTS) ===
            data.landmarks = extractLandmarks(face);

            // === FACE CONTOURS (OUTLINES) ===
            data.contours = extractContours(face);

            // === IMAGE DIMENSIONS ===
            data.imageWidth = imageWidth;
            data.imageHeight = imageHeight;

            // === DETECTION TIMESTAMP ===
            data.detectionTimestamp = System.currentTimeMillis();

        } catch (Exception e) {
            Log.e(TAG, "Error extracting real face data: " + e.getMessage(), e);
        }

        return data;
    }

    /**
     * Extract all facial landmarks (key points like eyes, nose, mouth)
     */
    private static List<LandmarkData> extractLandmarks(Face face) {
        List<LandmarkData> landmarks = new ArrayList<>();

        // Left eye
        addLandmark(landmarks, face, FaceLandmark.LEFT_EYE, "LEFT_EYE");

        // Right eye
        addLandmark(landmarks, face, FaceLandmark.RIGHT_EYE, "RIGHT_EYE");

        // Left ear
        addLandmark(landmarks, face, FaceLandmark.LEFT_EAR, "LEFT_EAR");

        // Right ear
        addLandmark(landmarks, face, FaceLandmark.RIGHT_EAR, "RIGHT_EAR");

        // Left cheek
        addLandmark(landmarks, face, FaceLandmark.LEFT_CHEEK, "LEFT_CHEEK");

        // Right cheek
        addLandmark(landmarks, face, FaceLandmark.RIGHT_CHEEK, "RIGHT_CHEEK");

        // Nose base
        addLandmark(landmarks, face, FaceLandmark.NOSE_BASE, "NOSE_BASE");

        // Mouth left
        addLandmark(landmarks, face, FaceLandmark.MOUTH_LEFT, "MOUTH_LEFT");

        // Mouth right
        addLandmark(landmarks, face, FaceLandmark.MOUTH_RIGHT, "MOUTH_RIGHT");

        // Mouth bottom
        addLandmark(landmarks, face, FaceLandmark.MOUTH_BOTTOM, "MOUTH_BOTTOM");

        return landmarks;
    }

    private static void addLandmark(List<LandmarkData> list, Face face, int landmarkType, String name) {
        FaceLandmark landmark = face.getLandmark(landmarkType);
        if (landmark != null) {
            PointF position = landmark.getPosition();
            if (position != null) {
                list.add(new LandmarkData(name, position.x, position.y));
            }
        }
    }

    /**
     * Extract all face contours (outline points)
     */
    private static List<ContourData> extractContours(Face face) {
        List<ContourData> contours = new ArrayList<>();

        // Face oval
        addContour(contours, face, FaceContour.FACE, "FACE");

        // Left eyebrow top
        addContour(contours, face, FaceContour.LEFT_EYEBROW_TOP, "LEFT_EYEBROW_TOP");

        // Left eyebrow bottom
        addContour(contours, face, FaceContour.LEFT_EYEBROW_BOTTOM, "LEFT_EYEBROW_BOTTOM");

        // Right eyebrow top
        addContour(contours, face, FaceContour.RIGHT_EYEBROW_TOP, "RIGHT_EYEBROW_TOP");

        // Right eyebrow bottom
        addContour(contours, face, FaceContour.RIGHT_EYEBROW_BOTTOM, "RIGHT_EYEBROW_BOTTOM");

        // Left eye
        addContour(contours, face, FaceContour.LEFT_EYE, "LEFT_EYE");

        // Right eye
        addContour(contours, face, FaceContour.RIGHT_EYE, "RIGHT_EYE");

        // Upper lip top
        addContour(contours, face, FaceContour.UPPER_LIP_TOP, "UPPER_LIP_TOP");

        // Upper lip bottom
        addContour(contours, face, FaceContour.UPPER_LIP_BOTTOM, "UPPER_LIP_BOTTOM");

        // Lower lip top
        addContour(contours, face, FaceContour.LOWER_LIP_TOP, "LOWER_LIP_TOP");

        // Lower lip bottom
        addContour(contours, face, FaceContour.LOWER_LIP_BOTTOM, "LOWER_LIP_BOTTOM");

        // Nose bridge
        addContour(contours, face, FaceContour.NOSE_BRIDGE, "NOSE_BRIDGE");

        // Nose bottom
        addContour(contours, face, FaceContour.NOSE_BOTTOM, "NOSE_BOTTOM");

        return contours;
    }

    private static void addContour(List<ContourData> list, Face face, int contourType, String name) {
        FaceContour contour = face.getContour(contourType);
        if (contour != null) {
            List<PointF> points = contour.getPoints();
            if (points != null && !points.isEmpty()) {
                list.add(new ContourData(name, points));
            }
        }
    }

    // ==================== DATA CLASSES ====================

    /**
     * Main data class containing all real detected face data
     */
    public static class RealFaceData implements Parcelable, Serializable {
        public static final Creator<RealFaceData> CREATOR = new Creator<RealFaceData>() {
            @Override
            public RealFaceData createFromParcel(Parcel in) {
                return new RealFaceData(in);
            }

            @Override
            public RealFaceData[] newArray(int size) {
                return new RealFaceData[size];
            }
        };
        // Bounding box
        public int boundingBoxLeft;
        public int boundingBoxTop;
        public int boundingBoxRight;
        public int boundingBoxBottom;
        public int boundingBoxWidth;
        public int boundingBoxHeight;
        public int boundingBoxCenterX;
        public int boundingBoxCenterY;
        // Head rotation angles (in degrees)
        public float headEulerAngleX; // Pitch (nodding up/down)
        public float headEulerAngleY; // Yaw (shaking left/right)
        public float headEulerAngleZ; // Roll (tilting)
        // Smile detection
        public float smilingProbability = -1f;
        public boolean hasSmilingProbability = false;
        // Eye detection
        public float leftEyeOpenProbability = -1f;
        public boolean hasLeftEyeOpenProbability = false;
        public float rightEyeOpenProbability = -1f;
        public boolean hasRightEyeOpenProbability = false;
        // Tracking
        public int trackingId = -1;
        // Landmarks (key facial points)
        public List<LandmarkData> landmarks = new ArrayList<>();
        // Contours (facial outlines)
        public List<ContourData> contours = new ArrayList<>();
        // Image info
        public float imageWidth;
        public float imageHeight;
        // Detection time
        public long detectionTimestamp;

        public RealFaceData() {
        }

        // Parcelable implementation
        protected RealFaceData(Parcel in) {
            boundingBoxLeft = in.readInt();
            boundingBoxTop = in.readInt();
            boundingBoxRight = in.readInt();
            boundingBoxBottom = in.readInt();
            boundingBoxWidth = in.readInt();
            boundingBoxHeight = in.readInt();
            boundingBoxCenterX = in.readInt();
            boundingBoxCenterY = in.readInt();
            headEulerAngleX = in.readFloat();
            headEulerAngleY = in.readFloat();
            headEulerAngleZ = in.readFloat();
            smilingProbability = in.readFloat();
            hasSmilingProbability = in.readByte() != 0;
            leftEyeOpenProbability = in.readFloat();
            hasLeftEyeOpenProbability = in.readByte() != 0;
            rightEyeOpenProbability = in.readFloat();
            hasRightEyeOpenProbability = in.readByte() != 0;
            trackingId = in.readInt();
            landmarks = in.createTypedArrayList(LandmarkData.CREATOR);
            contours = in.createTypedArrayList(ContourData.CREATOR);
            imageWidth = in.readFloat();
            imageHeight = in.readFloat();
            detectionTimestamp = in.readLong();
        }

        @Override
        public void writeToParcel(Parcel dest, int flags) {
            dest.writeInt(boundingBoxLeft);
            dest.writeInt(boundingBoxTop);
            dest.writeInt(boundingBoxRight);
            dest.writeInt(boundingBoxBottom);
            dest.writeInt(boundingBoxWidth);
            dest.writeInt(boundingBoxHeight);
            dest.writeInt(boundingBoxCenterX);
            dest.writeInt(boundingBoxCenterY);
            dest.writeFloat(headEulerAngleX);
            dest.writeFloat(headEulerAngleY);
            dest.writeFloat(headEulerAngleZ);
            dest.writeFloat(smilingProbability);
            dest.writeByte((byte) (hasSmilingProbability ? 1 : 0));
            dest.writeFloat(leftEyeOpenProbability);
            dest.writeByte((byte) (hasLeftEyeOpenProbability ? 1 : 0));
            dest.writeFloat(rightEyeOpenProbability);
            dest.writeByte((byte) (hasRightEyeOpenProbability ? 1 : 0));
            dest.writeInt(trackingId);
            dest.writeTypedList(landmarks);
            dest.writeTypedList(contours);
            dest.writeFloat(imageWidth);
            dest.writeFloat(imageHeight);
            dest.writeLong(detectionTimestamp);
        }

        @Override
        public int describeContents() {
            return 0;
        }

        /**
         * Convert to Map for Firestore storage
         */
        public Map<String, Object> toMap() {
            Map<String, Object> map = new HashMap<>();

            // Bounding box
            Map<String, Object> boundingBox = new HashMap<>();
            boundingBox.put("left", boundingBoxLeft);
            boundingBox.put("top", boundingBoxTop);
            boundingBox.put("right", boundingBoxRight);
            boundingBox.put("bottom", boundingBoxBottom);
            boundingBox.put("width", boundingBoxWidth);
            boundingBox.put("height", boundingBoxHeight);
            boundingBox.put("centerX", boundingBoxCenterX);
            boundingBox.put("centerY", boundingBoxCenterY);
            map.put("boundingBox", boundingBox);

            // Head rotation
            Map<String, Object> headRotation = new HashMap<>();
            headRotation.put("eulerX", headEulerAngleX);
            headRotation.put("eulerY", headEulerAngleY);
            headRotation.put("eulerZ", headEulerAngleZ);
            map.put("headRotation", headRotation);

            // Smile
            if (hasSmilingProbability) {
                map.put("smilingProbability", smilingProbability);
            }

            // Eyes
            if (hasLeftEyeOpenProbability) {
                map.put("leftEyeOpenProbability", leftEyeOpenProbability);
            }
            if (hasRightEyeOpenProbability) {
                map.put("rightEyeOpenProbability", rightEyeOpenProbability);
            }

            // Tracking
            if (trackingId != -1) {
                map.put("trackingId", trackingId);
            }

            // Landmarks
            List<Map<String, Object>> landmarkMaps = new ArrayList<>();
            for (LandmarkData landmark : landmarks) {
                landmarkMaps.add(landmark.toMap());
            }
            map.put("landmarks", landmarkMaps);

            // Contours
            List<Map<String, Object>> contourMaps = new ArrayList<>();
            for (ContourData contour : contours) {
                contourMaps.add(contour.toMap());
            }
            map.put("contours", contourMaps);

            // Image dimensions
            map.put("imageWidth", imageWidth);
            map.put("imageHeight", imageHeight);

            // Timestamp
            map.put("detectionTimestamp", detectionTimestamp);

            return map;
        }
    }

    /**
     * Landmark data (single facial point)
     */
    public static class LandmarkData implements Parcelable {
        public static final Creator<LandmarkData> CREATOR = new Creator<LandmarkData>() {
            @Override
            public LandmarkData createFromParcel(Parcel in) {
                return new LandmarkData(in);
            }

            @Override
            public LandmarkData[] newArray(int size) {
                return new LandmarkData[size];
            }
        };
        public String name;
        public float x;
        public float y;

        public LandmarkData(String name, float x, float y) {
            this.name = name;
            this.x = x;
            this.y = y;
        }

        protected LandmarkData(Parcel in) {
            name = in.readString();
            x = in.readFloat();
            y = in.readFloat();
        }

        @Override
        public void writeToParcel(Parcel dest, int flags) {
            dest.writeString(name);
            dest.writeFloat(x);
            dest.writeFloat(y);
        }

        @Override
        public int describeContents() {
            return 0;
        }

        public Map<String, Object> toMap() {
            Map<String, Object> map = new HashMap<>();
            map.put("name", name);
            map.put("x", x);
            map.put("y", y);
            return map;
        }
    }

    /**
     * Contour data (facial outline with multiple points)
     */
    public static class ContourData implements Parcelable {
        public static final Creator<ContourData> CREATOR = new Creator<ContourData>() {
            @Override
            public ContourData createFromParcel(Parcel in) {
                return new ContourData(in);
            }

            @Override
            public ContourData[] newArray(int size) {
                return new ContourData[size];
            }
        };
        public String name;
        public List<PointF> points;

        public ContourData(String name, List<PointF> points) {
            this.name = name;
            this.points = new ArrayList<>(points);
        }

        protected ContourData(Parcel in) {
            name = in.readString();
            points = new ArrayList<>();
            int size = in.readInt();
            for (int i = 0; i < size; i++) {
                float x = in.readFloat();
                float y = in.readFloat();
                points.add(new PointF(x, y));
            }
        }

        @Override
        public void writeToParcel(Parcel dest, int flags) {
            dest.writeString(name);
            dest.writeInt(points.size());
            for (PointF point : points) {
                dest.writeFloat(point.x);
                dest.writeFloat(point.y);
            }
        }

        @Override
        public int describeContents() {
            return 0;
        }

        public Map<String, Object> toMap() {
            Map<String, Object> map = new HashMap<>();
            map.put("name", name);

            List<Map<String, Float>> pointMaps = new ArrayList<>();
            for (PointF point : points) {
                Map<String, Float> pointMap = new HashMap<>();
                pointMap.put("x", point.x);
                pointMap.put("y", point.y);
                pointMaps.add(pointMap);
            }
            map.put("points", pointMaps);
            map.put("pointCount", points.size());

            return map;
        }
    }
}