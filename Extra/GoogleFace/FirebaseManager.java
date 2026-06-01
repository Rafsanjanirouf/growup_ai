package com.rafsan.growup099.GoogleFace;

import android.graphics.Bitmap;
import android.util.Log;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.google.firebase.firestore.SetOptions;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;

import java.io.ByteArrayOutputStream;
import java.lang.reflect.Field;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class FirebaseManager {

    private static final String TAG = "FirebaseManager";
    private static final String COLLECTION_USERS = "users";
    private static final String COLLECTION_FACE_SCANS = "face_scans";
    private static final String STORAGE_FACE_PHOTOS = "face_photos";
    private static final int PHOTO_QUALITY = 80;

    private final FirebaseFirestore firestore;
    private final FirebaseStorage storage;
    private final FirebaseAuth auth;

    public FirebaseManager() {
        this.firestore = FirebaseFirestore.getInstance();
        this.storage = FirebaseStorage.getInstance();
        this.auth = FirebaseAuth.getInstance();
    }

    // ════════════════════════════════════════════════════════
    //  MAIN SAVE  —  scanDocId = "face_Day_1", "face_Day_2"...
    //  ✅ Fixed document ID — no more random scan IDs
    //  ✅ .set() is idempotent — safe to call multiple times
    // ════════════════════════════════════════════════════════
    public void saveFaceScanResult(
            String scanDocId,                                         // ← "face_Day_N"
            RealFaceDataAnalyzer.RealFaceData faceData,
            ComprehensiveFaceAnalyzer.DetailedAnalysis detailedAnalysis,
            Bitmap photoBitmap,
            SaveResultCallback callback) {

        FirebaseUser currentUser = auth.getCurrentUser();
        if (currentUser == null) {
            callback.onFailure("User not authenticated");
            return;
        }

        String userId = currentUser.getUid();

        // Step 1: Upload photo (storage path uses scanDocId as filename)
        uploadCompressedPhoto(userId, scanDocId, photoBitmap, new PhotoUploadCallback() {
            @Override
            public void onSuccess(String photoUrl) {
                // Step 2: Save data to Firestore with fixed scanDocId
                saveScanDataToFirestore(userId, scanDocId, faceData, detailedAnalysis, photoUrl, callback);
            }

            @Override
            public void onFailure(String error) {
                callback.onFailure("Photo upload failed: " + error);
            }
        });
    }

    // ════════════════════════════════════════════════════════
    //  PHOTO UPLOAD
    //  Storage path: face_photos/{uid}/face_Day_1.jpg
    // ════════════════════════════════════════════════════════
    private void uploadCompressedPhoto(
            String userId,
            String scanDocId,
            Bitmap photoBitmap,
            PhotoUploadCallback callback) {
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            photoBitmap.compress(Bitmap.CompressFormat.JPEG, PHOTO_QUALITY, baos);
            byte[] photoData = baos.toByteArray();

            // ✅ File name = scanDocId  → "face_Day_1.jpg"
            StorageReference photoRef = storage.getReference()
                    .child(STORAGE_FACE_PHOTOS)
                    .child(userId)
                    .child(scanDocId + ".jpg");

            photoRef.putBytes(photoData)
                    .addOnSuccessListener(taskSnapshot ->
                            photoRef.getDownloadUrl()
                                    .addOnSuccessListener(uri -> {
                                        Log.d(TAG, "Photo uploaded: " + uri);
                                        callback.onSuccess(uri.toString());
                                    })
                                    .addOnFailureListener(e -> {
                                        Log.e(TAG, "Download URL failed: " + e.getMessage());
                                        callback.onFailure(e.getMessage());
                                    }))
                    .addOnFailureListener(e -> {
                        Log.e(TAG, "Upload failed: " + e.getMessage());
                        callback.onFailure(e.getMessage());
                    });

        } catch (Exception e) {
            Log.e(TAG, "Compress error: " + e.getMessage());
            callback.onFailure(e.getMessage());
        }
    }

    // ════════════════════════════════════════════════════════
    //  FIRESTORE SAVE
    //  Path: users/{uid}/face_scans/{scanDocId}
    //  e.g.  users/abc123/face_scans/face_Day_1
    // ════════════════════════════════════════════════════════
    private void saveScanDataToFirestore(
            String userId,
            String scanDocId,
            RealFaceDataAnalyzer.RealFaceData faceData,
            ComprehensiveFaceAnalyzer.DetailedAnalysis detailedAnalysis,
            String photoUrl,
            SaveResultCallback callback) {
        try {
            // Extract day number from ID: "face_Day_7" → 7
            int dayNumber = extractDayNumber(scanDocId);

            Map<String, Object> scanData = new HashMap<>();
            scanData.put("userId", userId);
            scanData.put("scanId", scanDocId);       // "face_Day_1"
            scanData.put("dayNumber", dayNumber);       // 1, 2, 3 ...
            scanData.put("photoUrl", photoUrl);
            scanData.put("timestamp", System.currentTimeMillis());
            scanData.put("dateCreated",
                    new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
                            .format(new Date()));

            // Real face data from ML Kit
            scanData.put("realFaceData", faceData.toMap());

            // Comprehensive analysis
            scanData.put("comprehensiveAnalysis",
                    convertDetailedAnalysisToMap(detailedAnalysis));

            // ✅ .document(scanDocId) → fixed ID, not auto-generated
            // ✅ .set() → overwrites safely (idempotent)
            firestore.collection(COLLECTION_USERS)
                    .document(userId)
                    .collection(COLLECTION_FACE_SCANS)
                    .document(scanDocId)
                    .set(scanData)
                    .addOnSuccessListener(unused -> {
                        Log.d(TAG, "Scan saved: " + scanDocId);
                        updateUserProfile(userId, scanDocId, faceData, detailedAnalysis);
                        callback.onSuccess(scanDocId, photoUrl);
                    })
                    .addOnFailureListener(e -> {
                        Log.e(TAG, "Firestore save failed: " + e.getMessage());
                        callback.onFailure("Database error: " + e.getMessage());
                    });

        } catch (Exception e) {
            Log.e(TAG, "Error preparing scan data: " + e.getMessage());
            callback.onFailure(e.getMessage());
        }
    }

    // ════════════════════════════════════════════════════════
    //  Helper: "face_Day_7" → 7
    // ════════════════════════════════════════════════════════
    private int extractDayNumber(String scanDocId) {
        try {
            return Integer.parseInt(scanDocId.replace("face_Day_", ""));
        } catch (Exception e) {
            return 0;
        }
    }

    // ════════════════════════════════════════════════════════
    //  Convert DetailedAnalysis → Map (reflection)
    // ════════════════════════════════════════════════════════
    private Map<String, Object> convertDetailedAnalysisToMap(
            ComprehensiveFaceAnalyzer.DetailedAnalysis analysis) {
        Map<String, Object> map = new HashMap<>();
        try {
            Field[] fields = ComprehensiveFaceAnalyzer.DetailedAnalysis.class.getDeclaredFields();
            for (Field field : fields) {
                field.setAccessible(true);
                Object value = field.get(analysis);
                if (value == null) continue;

                if (value instanceof List) {
                    List<?> list = (List<?>) value;
                    if (!list.isEmpty() && list.get(0) instanceof ComprehensiveFaceAnalyzer.EthnicityMatch) {
                        List<Map<String, Object>> out = new ArrayList<>();
                        for (Object item : list) {
                            ComprehensiveFaceAnalyzer.EthnicityMatch m =
                                    (ComprehensiveFaceAnalyzer.EthnicityMatch) item;
                            Map<String, Object> em = new HashMap<>();
                            em.put("ethnicity", m.ethnicity);
                            em.put("percentage", m.percentage);
                            em.put("region", m.region);
                            out.add(em);
                        }
                        map.put(field.getName(), out);
                    } else {
                        map.put(field.getName(), value);
                    }
                } else {
                    map.put(field.getName(), value);
                }
            }
        } catch (IllegalAccessException e) {
            Log.e(TAG, "convertDetailedAnalysis: " + e.getMessage());
        }
        return map;
    }

    // ════════════════════════════════════════════════════════
    //  Update user profile doc with latest scan summary
    // ════════════════════════════════════════════════════════
    private void updateUserProfile(
            String userId,
            String scanDocId,
            RealFaceDataAnalyzer.RealFaceData faceData,
            ComprehensiveFaceAnalyzer.DetailedAnalysis detailedAnalysis) {

        Map<String, Object> profileUpdate = new HashMap<>();
        profileUpdate.put("latestScanId", scanDocId);
        profileUpdate.put("lastScanTimestamp", System.currentTimeMillis());
        profileUpdate.put("totalScans", FieldValue.increment(1));

        Map<String, Object> latestStats = new HashMap<>();
        latestStats.put("attractivenessScore", detailedAnalysis.attractivenessScore);
        latestStats.put("attractivenessRating", detailedAnalysis.attractivenessRating);
        latestStats.put("globalRanking", detailedAnalysis.globalRanking);
        latestStats.put("primaryEthnicity", detailedAnalysis.primaryEthnicity);
        latestStats.put("beautyCategory", detailedAnalysis.beautyCategory);
        latestStats.put("overallSymmetry", detailedAnalysis.overallSymmetry);
        if (faceData.hasSmilingProbability)
            latestStats.put("smilingProbability", faceData.smilingProbability);

        profileUpdate.put("latestStats", latestStats);

        firestore.collection(COLLECTION_USERS).document(userId)
                .set(profileUpdate, SetOptions.merge())
                .addOnSuccessListener(unused -> Log.d(TAG, "Profile updated"))
                .addOnFailureListener(e -> Log.e(TAG, "Profile update failed: " + e.getMessage()));
    }

    // ════════════════════════════════════════════════════════
    //  LOAD SCAN BY ID
    // ════════════════════════════════════════════════════════
    public void loadScanById(String scanId, ScanLoadCallback callback) {
        FirebaseUser currentUser = auth.getCurrentUser();
        if (currentUser == null) {
            callback.onFailure("User not authenticated");
            return;
        }

        firestore.collection(COLLECTION_USERS)
                .document(currentUser.getUid())
                .collection(COLLECTION_FACE_SCANS)
                .document(scanId)
                .get()
                .addOnSuccessListener(doc -> {
                    if (doc.exists() && doc.getData() != null)
                        callback.onSuccess(doc.getData());
                    else
                        callback.onFailure("Scan not found");
                })
                .addOnFailureListener(e -> callback.onFailure("Load failed: " + e.getMessage()));
    }

    // ════════════════════════════════════════════════════════
    //  SCAN HISTORY
    // ════════════════════════════════════════════════════════
    public void getUserScanHistory(String userId, ScanHistoryCallback callback) {
        firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_FACE_SCANS)
                .orderBy("timestamp", Query.Direction.DESCENDING)
                .limit(20)
                .get()
                .addOnSuccessListener(qs -> callback.onSuccess(qs.getDocuments()))
                .addOnFailureListener(e -> callback.onFailure(e.getMessage()));
    }

    // ════════════════════════════════════════════════════════
    //  DELETE SCAN
    // ════════════════════════════════════════════════════════
    public void deleteScan(String scanId, String photoUrl, DeleteCallback callback) {
        FirebaseUser currentUser = auth.getCurrentUser();
        if (currentUser == null) {
            callback.onFailure("User not authenticated");
            return;
        }

        String userId = currentUser.getUid();
        try {
            storage.getReferenceFromUrl(photoUrl).delete()
                    .addOnSuccessListener(unused -> deleteFirestoreDocument(userId, scanId, callback))
                    .addOnFailureListener(e -> deleteFirestoreDocument(userId, scanId, callback));
        } catch (Exception e) {
            callback.onFailure(e.getMessage());
        }
    }

    private void deleteFirestoreDocument(String userId, String scanId, DeleteCallback callback) {
        firestore.collection(COLLECTION_USERS).document(userId)
                .collection(COLLECTION_FACE_SCANS).document(scanId)
                .delete()
                .addOnSuccessListener(unused -> callback.onSuccess())
                .addOnFailureListener(e -> callback.onFailure(e.getMessage()));
    }

    // ════════════════════════════════════════════════════════
    //  CALLBACKS
    // ════════════════════════════════════════════════════════
    public interface SaveResultCallback {
        void onSuccess(String scanId, String photoUrl);

        void onFailure(String error);
    }

    public interface PhotoUploadCallback {
        void onSuccess(String photoUrl);

        void onFailure(String error);
    }

    public interface ScanHistoryCallback {
        void onSuccess(List<DocumentSnapshot> scans);

        void onFailure(String error);
    }

    public interface ScanLoadCallback {
        void onSuccess(Map<String, Object> scanData);

        void onFailure(String error);
    }

    public interface DeleteCallback {
        void onSuccess();

        void onFailure(String error);
    }
}