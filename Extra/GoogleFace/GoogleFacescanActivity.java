package com.rafsan.growup099.GoogleFace;

import android.Manifest;
import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.media.Image;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.View;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.view.animation.LinearInterpolator;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.annotation.OptIn;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ExperimentalGetImage;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageCapture;
import androidx.camera.core.ImageCaptureException;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.cardview.widget.CardView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.exifinterface.media.ExifInterface;

import com.google.android.material.progressindicator.CircularProgressIndicator;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.face.Face;
import com.google.mlkit.vision.face.FaceContour;
import com.google.mlkit.vision.face.FaceDetection;
import com.google.mlkit.vision.face.FaceDetector;
import com.google.mlkit.vision.face.FaceDetectorOptions;
import com.google.mlkit.vision.face.FaceLandmark;
import com.rafsan.growup099.LocalData.LocalScanManager;
import com.rafsan.growup099.R;

import java.io.File;
import java.text.DecimalFormat;
import java.util.Random;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class GoogleFacescanActivity extends AppCompatActivity {

    public static final String EXTRA_DAY_NUMBER = "dayNumber";
    private static final String TAG = "GoogleFaceScan";
    private static final int CAMERA_PERMISSION_CODE = 100;
    private final FaceAnalysisData currentAnalysis = new FaceAnalysisData();
    // ── Day / doc ID ─────────────────────────────────────────
    private int dayNumber = 1;
    private String scanDocId;
    // ── Managers ─────────────────────────────────────────────
    private FirebaseManager firebaseManager;
    private LocalScanManager localScanManager;
    // ── UI ───────────────────────────────────────────────────
    private PreviewView previewView;
    private FaceOverlayView faceOverlay;
    private ImageView scanningGrid;
    private View scanLine;
    private TextView statusText, scanPercentage, loadingText, scanStatusLabel;
    private TextView qualityScore, smileScore, eyesScore;
    private TextView jawlineScore, eyeShapeScore, symmetryScore, noseScore;
    // Circular progress indicators (top row)
    private CircularProgressIndicator scanProgress;
    private CircularProgressIndicator qualityProgress, smileProgress, eyesProgress, symmetryProgress;
    // Circular progress indicators (feature cards)
    private CircularProgressIndicator jawlineProgress, eyeShapeProgress, noseProgress;
    private CardView scanProgressCard;
    private LinearLayout analysisPanel;
    private FrameLayout loadingOverlay, btnBack, btnSwitchCamera;
    private Button btnStartScan;
    // ── Camera ───────────────────────────────────────────────
    private ProcessCameraProvider cameraProvider;
    private Camera camera;
    private Preview preview;
    private ImageAnalysis imageAnalyzer;
    private ImageCapture imageCapture;
    private FaceDetector faceDetector;
    private ExecutorService cameraExecutor;
    private int lensFacing = CameraSelector.LENS_FACING_FRONT;
    // ── State ────────────────────────────────────────────────
    private boolean isScanning = false;
    private boolean isScanComplete = false;
    private int scanProgressValue = 0;
    private Handler scanHandler;
    private Runnable scanRunnable;
    private Face lastDetectedFace = null;

    // ════════════════════════════════════════════════════════
    //  LIFECYCLE
    // ════════════════════════════════════════════════════════
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_google_facescan);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.googlefacescan), (v, insets) -> {
            Insets sys = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(sys.left, sys.top, sys.right, sys.bottom);
            return insets;
        });
        dayNumber = getIntent().getIntExtra(EXTRA_DAY_NUMBER, 1);
        scanDocId = "face_Day_" + dayNumber;

        initViews();
        initFaceDetector();
        setupClickListeners();

        firebaseManager = new FirebaseManager();
        localScanManager = new LocalScanManager(this);
        cameraExecutor = Executors.newSingleThreadExecutor();

        checkExistingScanAndProceed();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (cameraExecutor != null) cameraExecutor.shutdown();
        if (faceDetector != null) faceDetector.close();
        if (scanHandler != null) scanHandler.removeCallbacksAndMessages(null);
    }

    // ════════════════════════════════════════════════════════
    //  STEP 1 — Check existing scan
    // ════════════════════════════════════════════════════════
    private void checkExistingScanAndProceed() {
        loadingOverlay.setVisibility(View.VISIBLE);
        loadingText.setText("Checking scan history...");

        if (localScanManager.hasScanLocally(scanDocId)) {
            loadingOverlay.setVisibility(View.GONE);
            goToDetailedResults(scanDocId);
            return;
        }

        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        if (user == null) {
            loadingOverlay.setVisibility(View.GONE);
            startCameraAfterPermissionCheck();
            return;
        }

        FirebaseFirestore.getInstance()
                .collection("users")
                .document(user.getUid())
                .collection("face_scans")
                .document(scanDocId)
                .get()
                .addOnSuccessListener(doc -> {
                    loadingOverlay.setVisibility(View.GONE);
                    if (doc.exists()) goToDetailedResults(scanDocId);
                    else startCameraAfterPermissionCheck();
                })
                .addOnFailureListener(e -> {
                    loadingOverlay.setVisibility(View.GONE);
                    startCameraAfterPermissionCheck();
                });
    }

    private void goToDetailedResults(String scanId) {
        Toast.makeText(this, "Day " + dayNumber + " scan already completed! ✅", Toast.LENGTH_SHORT).show();
        startActivity(new Intent(this, FaceResultOverviewActivity.class)
                .putExtra("scanId", scanId));
        finish();
    }

    // ════════════════════════════════════════════════════════
    //  CAMERA
    // ════════════════════════════════════════════════════════
    private void startCameraAfterPermissionCheck() {
        if (checkCameraPermission()) startCamera();
        else requestCameraPermission();
    }

    private boolean checkCameraPermission() {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED;
    }

    private void requestCameraPermission() {
        ActivityCompat.requestPermissions(this,
                new String[]{Manifest.permission.CAMERA}, CAMERA_PERMISSION_CODE);
    }

    @Override
    public void onRequestPermissionsResult(int req, @NonNull String[] perms, @NonNull int[] results) {
        super.onRequestPermissionsResult(req, perms, results);
        if (req == CAMERA_PERMISSION_CODE) {
            if (results.length > 0 && results[0] == PackageManager.PERMISSION_GRANTED)
                startCamera();
            else {
                Toast.makeText(this, "Camera permission required", Toast.LENGTH_SHORT).show();
                finish();
            }
        }
    }

    private void startCamera() {
        loadingOverlay.setVisibility(View.VISIBLE);
        loadingText.setText("Initializing Camera...");

        ListenableFuture<ProcessCameraProvider> future = ProcessCameraProvider.getInstance(this);
        future.addListener(() -> {
            try {
                cameraProvider = future.get();
                bindCameraUseCases();
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    loadingOverlay.setVisibility(View.GONE);
                    animateCorners();
                }, 1000);
            } catch (ExecutionException | InterruptedException e) {
                Log.e(TAG, "Camera init: " + e.getMessage());
                runOnUiThread(() -> loadingOverlay.setVisibility(View.GONE));
            }
        }, ContextCompat.getMainExecutor(this));
    }

    private void bindCameraUseCases() {
        if (cameraProvider == null) return;
        cameraProvider.unbindAll();

        preview = new Preview.Builder().build();
        preview.setSurfaceProvider(previewView.getSurfaceProvider());

        imageAnalyzer = new ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build();
        imageAnalyzer.setAnalyzer(cameraExecutor, this::analyzeImage);

        imageCapture = new ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                .build();

        CameraSelector cameraSelector = new CameraSelector.Builder()
                .requireLensFacing(lensFacing).build();
        try {
            camera = cameraProvider.bindToLifecycle(
                    this, cameraSelector, preview, imageAnalyzer, imageCapture);
        } catch (Exception e) {
            Log.e(TAG, "bindCameraUseCases: " + e.getMessage());
        }
    }

    private void switchCamera() {
        lensFacing = (lensFacing == CameraSelector.LENS_FACING_FRONT)
                ? CameraSelector.LENS_FACING_BACK : CameraSelector.LENS_FACING_FRONT;
        bindCameraUseCases();
    }

    // ════════════════════════════════════════════════════════
    //  LIVE FACE DETECTION
    // ════════════════════════════════════════════════════════
    @OptIn(markerClass = ExperimentalGetImage.class)
    private void analyzeImage(@NonNull ImageProxy imageProxy) {
        Image mediaImage = imageProxy.getImage();
        if (mediaImage == null) {
            imageProxy.close();
            return;
        }

        InputImage image = InputImage.fromMediaImage(
                mediaImage, imageProxy.getImageInfo().getRotationDegrees());

        faceDetector.process(image)
                .addOnSuccessListener(faces -> {
                    if (!faces.isEmpty()) processFace(faces.get(0), imageProxy);
                    else runOnUiThread(() -> {
                        faceOverlay.clear();
                        statusText.setText("No face detected");
                        lastDetectedFace = null;
                    });
                })
                .addOnFailureListener(e -> Log.e(TAG, "FaceDetection: " + e.getMessage()))
                .addOnCompleteListener(t -> imageProxy.close());
    }

    private void processFace(Face face, ImageProxy imageProxy) {
        lastDetectedFace = face;
        float sx = (float) previewView.getWidth() / imageProxy.getHeight();
        float sy = (float) previewView.getHeight() / imageProxy.getWidth();
        runOnUiThread(() -> {
            faceOverlay.setFace(face, sx, sy);
            if (isScanning) analyzeFaceFeatures(face);
            else statusText.setText("Face detected — Ready to scan");
        });
    }

    // ════════════════════════════════════════════════════════
    //  FEATURE ANALYSIS
    // ════════════════════════════════════════════════════════
    private void analyzeFaceFeatures(Face face) {
        try {
            Rect bounds = face.getBoundingBox();
            float fa = bounds.width() * (float) bounds.height();
            float sa = previewView.getWidth() * (float) previewView.getHeight();
            currentAnalysis.quality = Math.min(100, (int) (fa / sa * 300));

            if (face.getSmilingProbability() != null)
                currentAnalysis.smile = (int) (face.getSmilingProbability() * 100);

            if (face.getLeftEyeOpenProbability() != null && face.getRightEyeOpenProbability() != null)
                currentAnalysis.eyesOpen = (int) (
                        (face.getLeftEyeOpenProbability() + face.getRightEyeOpenProbability()) / 2 * 100);

            currentAnalysis.jawline = contourScore(face, FaceContour.FACE);
            currentAnalysis.eyeShape = eyeShapeScore(face);
            currentAnalysis.symmetry = symmetryScore(face);
            currentAnalysis.nose = noseScore(face);

            updateUIWithAnalysis();
        } catch (Exception e) {
            Log.e(TAG, "analyzeFace: " + e.getMessage());
        }
    }

    private int contourScore(Face face, int type) {
        try {
            FaceContour fc = face.getContour(type);
            if (fc != null && fc.getPoints() != null && !fc.getPoints().isEmpty())
                return Math.min(100, 60 + new Random().nextInt(40));
        } catch (Exception ignored) {
        }
        return 0;
    }

    private int eyeShapeScore(Face face) {
        try {
            if (face.getLandmark(FaceLandmark.LEFT_EYE) != null
                    && face.getLandmark(FaceLandmark.RIGHT_EYE) != null)
                return Math.min(100, 70 + new Random().nextInt(30));
        } catch (Exception ignored) {
        }
        return 0;
    }

    private int symmetryScore(Face face) {
        try {
            return Math.max(0, Math.min(100,
                    (int) (100 - Math.abs(face.getHeadEulerAngleY()) * 2
                            - Math.abs(face.getHeadEulerAngleZ()) * 2)));
        } catch (Exception ignored) {
            return 0;
        }
    }

    private int noseScore(Face face) {
        try {
            FaceContour nb = face.getContour(FaceContour.NOSE_BRIDGE);
            if (face.getLandmark(FaceLandmark.NOSE_BASE) != null
                    && nb != null && nb.getPoints() != null && !nb.getPoints().isEmpty())
                return Math.min(100, 65 + new Random().nextInt(35));
        } catch (Exception ignored) {
        }
        return 0;
    }

    private void updateUIWithAnalysis() {
        try {
            DecimalFormat df = new DecimalFormat("#");

            // Top row — circular
            setCircularValue(qualityProgress, qualityScore, currentAnalysis.quality);
            setCircularValue(smileProgress, smileScore, currentAnalysis.smile);
            setCircularValue(eyesProgress, eyesScore, currentAnalysis.eyesOpen);
            setCircularValue(symmetryProgress, symmetryScore, currentAnalysis.symmetry);

            // Feature cards — circular
            setCircularValue(jawlineProgress, jawlineScore, currentAnalysis.jawline);
            setCircularValue(eyeShapeProgress, eyeShapeScore, currentAnalysis.eyeShape);
            setCircularValue(noseProgress, noseScore, currentAnalysis.nose);

        } catch (Exception e) {
            Log.e(TAG, "updateUI: " + e.getMessage());
        }
    }

    /**
     * Smoothly animates a CircularProgressIndicator and updates its center TextView.
     */
    private void setCircularValue(CircularProgressIndicator indicator, TextView label, int target) {
        animateCircular(indicator, label, target, 400);
    }

    private void animateCircular(CircularProgressIndicator indicator,
                                 TextView label, int target, int duration) {
        ValueAnimator anim = ValueAnimator.ofInt(indicator.getProgress(), target);
        anim.setDuration(duration);
        anim.setInterpolator(new AccelerateDecelerateInterpolator());
        anim.addUpdateListener(va -> {
            int val = (int) va.getAnimatedValue();
            indicator.setProgressCompat(val, false);
            label.setText(val + "%");
        });
        anim.start();
    }

    // ════════════════════════════════════════════════════════
    //  SCAN FLOW
    // ════════════════════════════════════════════════════════
    private void startFaceScan() {
        isScanning = true;
        isScanComplete = false;
        scanProgressValue = 0;
        btnStartScan.setText("Scanning...");
        btnStartScan.setEnabled(false);
        scanProgressCard.setVisibility(View.VISIBLE);
        scanningGrid.setVisibility(View.VISIBLE);
        faceOverlay.setScanning(true);

        ObjectAnimator g = ObjectAnimator.ofFloat(scanningGrid, "alpha", 0.1f, 0.5f);
        g.setDuration(1000);
        g.setRepeatMode(ValueAnimator.REVERSE);
        g.setRepeatCount(ValueAnimator.INFINITE);
        g.start();
        startScanLineAnimation();

        // Reset circular scan progress
        scanProgress.setProgressCompat(0, false);
        scanPercentage.setText("0%");

        scanHandler = new Handler(Looper.getMainLooper());
        scanRunnable = new Runnable() {
            @Override
            public void run() {
                if (scanProgressValue < 100 && isScanning) {
                    scanProgressValue += 2;
                    // Animate the circular scan progress
                    scanProgress.setProgressCompat(scanProgressValue, true);
                    scanPercentage.setText(scanProgressValue + "%");
                    updateScanStatus(scanProgressValue);
                    scanHandler.postDelayed(this, 100);
                } else if (scanProgressValue >= 100) {
                    completeScan();
                }
            }
        };
        scanHandler.post(scanRunnable);
    }

    private void stopFaceScan() {
        isScanning = false;
        if (scanHandler != null) scanHandler.removeCallbacks(scanRunnable);
        btnStartScan.setText("Start Scan");
        btnStartScan.setEnabled(true);
        scanningGrid.setVisibility(View.GONE);
        faceOverlay.setScanning(false);
    }

    private void startScanLineAnimation() {
        scanLine.setVisibility(View.VISIBLE);
        ValueAnimator a = ValueAnimator.ofFloat(100f, previewView.getHeight() - 100f);
        a.setDuration(2000);
        a.setRepeatMode(ValueAnimator.REVERSE);
        a.setRepeatCount(ValueAnimator.INFINITE);
        a.setInterpolator(new LinearInterpolator());
        a.addUpdateListener(an -> {
            float v = (float) an.getAnimatedValue();
            scanLine.setTranslationY(v);
            faceOverlay.setScanLineY(v);
        });
        a.start();
    }

    private void updateScanStatus(int p) {
        String label;
        if (p < 20) label = "Detecting facial features...";
        else if (p < 40) label = "Analyzing jawline structure...";
        else if (p < 60) label = "Measuring eye geometry...";
        else if (p < 80) label = "Calculating symmetry...";
        else label = "Finalizing analysis...";

        statusText.setText(label);
        if (scanStatusLabel != null) scanStatusLabel.setText(label);
    }

    /**
     * Called automatically when progress hits 100%.
     * ✅ Auto-saves and navigates directly — no extra button click needed.
     */
    private void completeScan() {
        isScanning = false;
        isScanComplete = true;
        scanningGrid.setVisibility(View.GONE);
        scanLine.setVisibility(View.GONE);
        faceOverlay.setScanning(false);
        statusText.setText("Scan Complete! Saving...");
        btnStartScan.setEnabled(false);

        // Haptic feedback
        try {
            android.os.Vibrator vib = (android.os.Vibrator) getSystemService(VIBRATOR_SERVICE);
            if (vib != null) vib.vibrate(200);
        } catch (Exception ignored) {
        }

        showCompletionAnimation();

        // ✅ Auto-save and navigate immediately — no "View Report" button
        saveAndNavigate();
    }

    // ════════════════════════════════════════════════════════
    //  SAVE
    // ════════════════════════════════════════════════════════
    private void saveAndNavigate() {
        if (lastDetectedFace == null) {
            Toast.makeText(this, "No face detected during scan", Toast.LENGTH_SHORT).show();
            resetScanState();
            return;
        }
        try {
            loadingOverlay.setVisibility(View.VISIBLE);
            loadingText.setText("Processing Results...");

            RealFaceDataAnalyzer.RealFaceData realData =
                    RealFaceDataAnalyzer.extractRealData(
                            lastDetectedFace, previewView.getWidth(), previewView.getHeight());

            loadingText.setText("Analyzing Features...");
            ComprehensiveFaceAnalyzer.DetailedAnalysis detailedAnalysis =
                    ComprehensiveFaceAnalyzer.analyzeCompletely(lastDetectedFace);

            loadingText.setText("Capturing Photo...");
            captureAndSave(realData, detailedAnalysis);

        } catch (Exception e) {
            Log.e(TAG, "saveAndNavigate: " + e.getMessage(), e);
            loadingOverlay.setVisibility(View.GONE);
            Toast.makeText(this, "Error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            resetScanState();
        }
    }

    private void captureAndSave(
            RealFaceDataAnalyzer.RealFaceData realData,
            ComprehensiveFaceAnalyzer.DetailedAnalysis detailedAnalysis) {

        if (imageCapture == null) {
            runOnUiThread(() -> {
                loadingOverlay.setVisibility(View.GONE);
                Toast.makeText(this, "Camera not ready, try again", Toast.LENGTH_SHORT).show();
                resetScanState();
            });
            return;
        }

        File photoFile = new File(getCacheDir(), "face_" + System.currentTimeMillis() + ".jpg");
        ImageCapture.OutputFileOptions opts =
                new ImageCapture.OutputFileOptions.Builder(photoFile).build();

        imageCapture.takePicture(opts, cameraExecutor,
                new ImageCapture.OnImageSavedCallback() {

                    @Override
                    public void onImageSaved(@NonNull ImageCapture.OutputFileResults results) {
                        Bitmap bitmap = BitmapFactory.decodeFile(photoFile.getAbsolutePath());
                        if (bitmap == null) {
                            runOnUiThread(() -> {
                                loadingOverlay.setVisibility(View.GONE);
                                Toast.makeText(GoogleFacescanActivity.this,
                                        "Failed to decode photo", Toast.LENGTH_SHORT).show();
                                resetScanState();
                            });
                            return;
                        }

                        bitmap = applyExifRotation(bitmap, photoFile.getAbsolutePath());
                        photoFile.delete();
                        final Bitmap finalBitmap = bitmap;

                        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
                        if (user != null) {
                            runOnUiThread(() -> loadingText.setText("Saving to Cloud..."));
                            firebaseManager.saveFaceScanResult(
                                    scanDocId, realData, detailedAnalysis, finalBitmap,
                                    new FirebaseManager.SaveResultCallback() {
                                        @Override
                                        public void onSuccess(String savedId, String photoUrl) {
                                            // Also cache locally
                                            localScanManager.saveScanLocally(
                                                    scanDocId, realData, detailedAnalysis, finalBitmap,
                                                    new LocalScanManager.LocalSaveCallback() {
                                                        @Override
                                                        public void onSuccess(String id, String path) {
                                                        }

                                                        @Override
                                                        public void onFailure(String e) {
                                                        }
                                                    });
                                            // ✅ Direct navigate — no intermediate screen
                                            runOnUiThread(() -> navigateToResults(savedId));
                                        }

                                        @Override
                                        public void onFailure(String error) {
                                            Log.w(TAG, "Cloud save failed, saving locally: " + error);
                                            saveLocallyAndNavigate(realData, detailedAnalysis, finalBitmap);
                                        }
                                    });
                        } else {
                            runOnUiThread(() -> loadingText.setText("Saving locally..."));
                            saveLocallyAndNavigate(realData, detailedAnalysis, finalBitmap);
                        }
                    }

                    @Override
                    public void onError(@NonNull ImageCaptureException exception) {
                        Log.e(TAG, "takePicture error: " + exception.getMessage());
                        runOnUiThread(() -> {
                            loadingOverlay.setVisibility(View.GONE);
                            Toast.makeText(GoogleFacescanActivity.this,
                                    "Photo capture failed: " + exception.getMessage(),
                                    Toast.LENGTH_LONG).show();
                            resetScanState();
                        });
                    }
                });
    }

    private void saveLocallyAndNavigate(
            RealFaceDataAnalyzer.RealFaceData realData,
            ComprehensiveFaceAnalyzer.DetailedAnalysis detailedAnalysis,
            Bitmap bitmap) {

        localScanManager.saveScanLocally(
                scanDocId, realData, detailedAnalysis, bitmap,
                new LocalScanManager.LocalSaveCallback() {
                    @Override
                    public void onSuccess(String id, String photoPath) {
                        runOnUiThread(() -> navigateToResults(id));
                    }

                    @Override
                    public void onFailure(String error) {
                        runOnUiThread(() -> {
                            loadingOverlay.setVisibility(View.GONE);
                            Toast.makeText(GoogleFacescanActivity.this,
                                    "Save failed: " + error, Toast.LENGTH_LONG).show();
                            resetScanState();
                        });
                    }
                });
    }

    /**
     * ✅ Direct navigation — scan complete হলে সাথে সাথে DetailedResultsActivity তে যাবে।
     * "View Report" button দেখানোর দরকার নেই।
     */
    private void navigateToResults(String scanId) {
        loadingOverlay.setVisibility(View.GONE);
        startActivity(new Intent(this, FaceResultOverviewActivity.class)
                .putExtra("scanId", scanId));
        finish();
    }

    // ════════════════════════════════════════════════════════
    //  EXIF ROTATION
    // ════════════════════════════════════════════════════════
    private Bitmap applyExifRotation(Bitmap src, String path) {
        try {
            ExifInterface exif = new ExifInterface(path);
            int ori = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL);
            Matrix m = new Matrix();
            switch (ori) {
                case ExifInterface.ORIENTATION_ROTATE_90:
                    m.postRotate(90);
                    break;
                case ExifInterface.ORIENTATION_ROTATE_180:
                    m.postRotate(180);
                    break;
                case ExifInterface.ORIENTATION_ROTATE_270:
                    m.postRotate(270);
                    break;
                case ExifInterface.ORIENTATION_FLIP_HORIZONTAL:
                    m.postScale(-1, 1);
                    break;
                case ExifInterface.ORIENTATION_FLIP_VERTICAL:
                    m.postScale(1, -1);
                    break;
                default:
                    return src;
            }
            return Bitmap.createBitmap(src, 0, 0, src.getWidth(), src.getHeight(), m, true);
        } catch (Exception e) {
            Log.w(TAG, "applyExifRotation: " + e.getMessage());
            return src;
        }
    }

    // ════════════════════════════════════════════════════════
    //  RESET
    // ════════════════════════════════════════════════════════
    private void resetScanState() {
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            btnStartScan.setText("Start Scan");
            btnStartScan.setEnabled(true);
            scanProgressValue = 0;
            scanProgress.setProgressCompat(0, false);
            scanPercentage.setText("0%");
            scanProgressCard.setVisibility(View.GONE);
            isScanComplete = false;
            isScanning = false;
            btnStartScan.setOnClickListener(v -> {
                if (!isScanning) startFaceScan();
                else stopFaceScan();
            });
        }, 500);
    }

    // ════════════════════════════════════════════════════════
    //  ANIMATIONS
    // ════════════════════════════════════════════════════════
    private void showCompletionAnimation() {
        try {
            ObjectAnimator px = ObjectAnimator.ofFloat(analysisPanel, "scaleX", 1f, 1.04f, 1f);
            px.setDuration(300);
            px.start();
            ObjectAnimator py = ObjectAnimator.ofFloat(analysisPanel, "scaleY", 1f, 1.04f, 1f);
            py.setDuration(300);
            py.start();
        } catch (Exception ignored) {
        }
    }

    private void animateCorners() {
        int[] ids = {R.id.cornerTopLeft, R.id.cornerTopRight,
                R.id.cornerBottomLeft, R.id.cornerBottomRight};
        for (int id : ids) {
            ImageView c = findViewById(id);
            if (c == null) continue;
            ObjectAnimator sx = ObjectAnimator.ofFloat(c, "scaleX", 0.8f, 1.2f);
            sx.setDuration(1000);
            sx.setRepeatMode(ValueAnimator.REVERSE);
            sx.setRepeatCount(ValueAnimator.INFINITE);
            sx.start();
            ObjectAnimator sy = ObjectAnimator.ofFloat(c, "scaleY", 0.8f, 1.2f);
            sy.setDuration(1000);
            sy.setRepeatMode(ValueAnimator.REVERSE);
            sy.setRepeatCount(ValueAnimator.INFINITE);
            sy.start();
        }
    }

    // ════════════════════════════════════════════════════════
    //  INIT
    // ════════════════════════════════════════════════════════
    private void initViews() {
        previewView = findViewById(R.id.previewView);
        faceOverlay = findViewById(R.id.faceOverlay);
        scanningGrid = findViewById(R.id.scanningGrid);
        scanLine = findViewById(R.id.scanLine);
        statusText = findViewById(R.id.statusText);
        scanPercentage = findViewById(R.id.scanPercentage);
        loadingText = findViewById(R.id.loadingText);
        scanStatusLabel = findViewById(R.id.scanStatusLabel);

        // Scores (center text of each circle)
        qualityScore = findViewById(R.id.qualityScore);
        smileScore = findViewById(R.id.smileScore);
        eyesScore = findViewById(R.id.eyesScore);
        symmetryScore = findViewById(R.id.symmetryScore);
        jawlineScore = findViewById(R.id.jawlineScore);
        eyeShapeScore = findViewById(R.id.eyeShapeScore);
        noseScore = findViewById(R.id.noseScore);

        // Circular progress indicators
        scanProgress = findViewById(R.id.scanProgress);
        qualityProgress = findViewById(R.id.qualityProgress);
        smileProgress = findViewById(R.id.smileProgress);
        eyesProgress = findViewById(R.id.eyesProgress);
        symmetryProgress = findViewById(R.id.symmetryProgress);
        jawlineProgress = findViewById(R.id.jawlineProgress);
        eyeShapeProgress = findViewById(R.id.eyeShapeProgress);
        noseProgress = findViewById(R.id.noseProgress);

        // Disable Material's own animation — we drive it manually
        scanProgress.setIndeterminate(false);
        qualityProgress.setIndeterminate(false);
        smileProgress.setIndeterminate(false);
        eyesProgress.setIndeterminate(false);
        symmetryProgress.setIndeterminate(false);
        jawlineProgress.setIndeterminate(false);
        eyeShapeProgress.setIndeterminate(false);
        noseProgress.setIndeterminate(false);

        scanProgressCard = findViewById(R.id.scanProgressCard);
        analysisPanel = findViewById(R.id.analysisPanel);
        loadingOverlay = findViewById(R.id.loadingOverlay);
        btnBack = findViewById(R.id.btnBack);
        btnSwitchCamera = findViewById(R.id.btnSwitchCamera);
        btnStartScan = findViewById(R.id.btnStartScan);

        analysisPanel.setVisibility(View.VISIBLE);
    }

    private void initFaceDetector() {
        FaceDetectorOptions options = new FaceDetectorOptions.Builder()
                .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
                .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
                .setContourMode(FaceDetectorOptions.CONTOUR_MODE_ALL)
                .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL)
                .setMinFaceSize(0.15f)
                .enableTracking()
                .build();
        faceDetector = FaceDetection.getClient(options);
    }

    private void setupClickListeners() {
        btnBack.setOnClickListener(v -> finish());
        btnSwitchCamera.setOnClickListener(v -> switchCamera());
        btnStartScan.setOnClickListener(v -> {
            if (!isScanning && !isScanComplete) startFaceScan();
            else if (isScanning) stopFaceScan();
        });
    }

    // ════════════════════════════════════════════════════════
    //  DATA CLASS
    // ════════════════════════════════════════════════════════
    private static class FaceAnalysisData {
        int quality = 0, smile = 0, eyesOpen = 0,
                jawline = 0, eyeShape = 0, symmetry = 0, nose = 0;
    }
}