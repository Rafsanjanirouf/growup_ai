package com.rafsan.growup099.GoogleFace;

import androidx.core.content.ContextCompat;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.OvershootInterpolator;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import androidx.core.content.FileProvider;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.bumptech.glide.Glide;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.QuerySnapshot;
import com.makeramen.roundedimageview.RoundedImageView;
import com.rafsan.growup099.AiOnBording.AIChatOnboardingActivity;
import com.rafsan.growup099.LocalData.LocalScanManager;
import com.rafsan.growup099.PremiumUser.OfferDialog;
import com.rafsan.growup099.PremiumUser.PremiumManager;
import com.rafsan.growup099.R;
import com.rafsan.growup099.TaskDetails.CreateSevenDaysTaskActivity;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;

public class DetailedResultsActivity extends AppCompatActivity {

    private static final String TAG = "DetailedResults";

    private final DecimalFormat df = new DecimalFormat("#.#");
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final List<CardPage> cardPages = new ArrayList<>();
    // ── Data ──────────────────────────────────
    private boolean isPremium = false;
    private String scanId;
    private Map<String, Object> scanData;
    private Map<String, Object> ca;
    private Bitmap faceBitmap;
    private String photoUrl;
    // ── Navigation views (activity layout) ───
    private FrameLayout cardFlipContainer;
    private LinearLayout cardDotIndicator;
    private LinearLayout cardIconStrip;
    private TextView cardPageLabel;
    private TextView cardSectionIcon;
    private TextView cardSectionTitle;
    private View btnCardPrev;
    private View btnCardNext;
    private CardView ctaCardView;
    private LinearLayout btnCta;
    private TextView btnCtaText;
    // ── Card pager state ──────────────────────
    private int currentCardIndex = 0;
    private boolean isFlipping = false;
    // ── Firebase / Storage ───────────────────
    private OkHttpClient httpClient;
    private FirebaseFirestore db;
    private FirebaseManager firebaseManager;
    private LocalScanManager localScanManager;

    // ── Colors ────────────────────────────────
    private int COLOR_ACCENT;
    private int COLOR_SUCCESS;
    private int COLOR_BLUE;
    private int COLOR_WARNING;
    private int COLOR_ERROR;
    private int COLOR_SURFACE_HIGH;

    // ═════════════════════════════════════════
    //  DATA CLASSES
    // ═════════════════════════════════════════

    /**
     * @noinspection unused
     */
    public static String ratingOf(float s) {
        if (s >= 90) return "Exceptional";
        if (s >= 80) return "Very Attractive";
        if (s >= 70) return "Attractive";
        if (s >= 60) return "Above Average";
        if (s >= 50) return "Average";
        return "Below Average";
    }

    private void initColors() {
        COLOR_ACCENT = ContextCompat.getColor(this, R.color.accent_glow);
        COLOR_SUCCESS = ContextCompat.getColor(this, R.color.success);
        COLOR_BLUE = ContextCompat.getColor(this, R.color.secondary);
        COLOR_WARNING = ContextCompat.getColor(this, R.color.warning);
        COLOR_ERROR = ContextCompat.getColor(this, R.color.error_color);
        COLOR_SURFACE_HIGH = ContextCompat.getColor(this, R.color.surface_container_highest);
    }

    public static int colorFor(android.content.Context context, float v) {
        if (v >= 90) return androidx.core.content.ContextCompat.getColor(context, R.color.success);
        if (v >= 80) return androidx.core.content.ContextCompat.getColor(context, R.color.secondary);
        if (v >= 65) return androidx.core.content.ContextCompat.getColor(context, R.color.warning);
        return androidx.core.content.ContextCompat.getColor(context, R.color.error_color);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_detailed_results);
        initColors();
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.rootLayout), (v, insets) -> {
            Insets sys = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(sys.left, sys.top, sys.right, sys.bottom);
            return insets;
        });

        scanId = getIntent().getStringExtra("scanId");
        if (scanId == null || scanId.isEmpty()) {
            Toast.makeText(this, "Error: No scan ID", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        isPremium = PremiumManager.isPremium();
        PremiumManager.checkPremium(this, new PremiumManager.PremiumCallback() {
            @Override
            public void onResult(boolean premiumStatus, String planType) {
                if (isPremium != premiumStatus) {
                    isPremium = premiumStatus;
                    runOnUiThread(() -> {
                        showCard(currentCardIndex, false);
                        updateCtaButton();
                    });
                }
            }

            @Override
            public void onError(String error) {
                Log.w(TAG, "Premium: " + error);
            }
        });

        httpClient = new OkHttpClient.Builder()
                .connectTimeout(30, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS).build();

        db = FirebaseFirestore.getInstance();
        firebaseManager = new FirebaseManager();
        localScanManager = new LocalScanManager(this);

        initViews();
        registerBackHandler();
        loadData();
    }

    // ═════════════════════════════════════════
    //  LIFECYCLE
    // ═════════════════════════════════════════

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mainHandler.removeCallbacksAndMessages(null);
        if (httpClient != null) httpClient.dispatcher().executorService().shutdown();
    }

    private void registerBackHandler() {
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (currentCardIndex > 0) {
                    navigateCard(-1);
                    return;
                }
                setEnabled(false);
                getOnBackPressedDispatcher().onBackPressed();
            }
        });
    }

    // ═════════════════════════════════════════
    //  BACK HANDLER
    // ═════════════════════════════════════════

    private void initViews() {
        TextView dateText = findViewById(R.id.dateText);
        if (dateText != null)
            dateText.setText(new SimpleDateFormat("MMM dd, yyyy", Locale.US).format(new Date()));

        cardFlipContainer = findViewById(R.id.cardFlipContainer);
        cardDotIndicator = findViewById(R.id.cardDotIndicator);
        cardIconStrip = findViewById(R.id.cardIconStrip);
        cardPageLabel = findViewById(R.id.cardPageLabel);
        cardSectionIcon = findViewById(R.id.cardSectionIcon);
        cardSectionTitle = findViewById(R.id.cardSectionTitle);
        btnCardPrev = findViewById(R.id.btnCardPrev);
        btnCardNext = findViewById(R.id.btnCardNext);
        ctaCardView = findViewById(R.id.ctaCardView);
        btnCta = findViewById(R.id.btnCta);
        btnCtaText = findViewById(R.id.btnCtaText);

        View btnClose = findViewById(R.id.btnClose);
        if (btnClose != null) btnClose.setOnClickListener(v -> finishWithAnimation());

        if (btnCardPrev != null) btnCardPrev.setOnClickListener(v -> {
            bounceView(v);
            mainHandler.postDelayed(() -> navigateCard(-1), 80);
        });
        if (btnCardNext != null) btnCardNext.setOnClickListener(v -> {
            bounceView(v);
            mainHandler.postDelayed(() -> navigateCard(1), 80);
        });
        if (btnCta != null) btnCta.setOnClickListener(v -> {
            pulseView(ctaCardView);
            mainHandler.postDelayed(this::handleCtaTap, 150);
        });
    }

    // ═════════════════════════════════════════
    //  INIT VIEWS  (activity layout only)
    // ═════════════════════════════════════════

    private boolean isLockedCard() {
        return !isPremium && currentCardIndex > 0;
    }

    // ═════════════════════════════════════════
    //  CTA LOGIC
    // ═════════════════════════════════════════

    private void handleCtaTap() {
        if (isLockedCard()) {
            OfferDialog.show(this);
            return;
        }
        if (currentCardIndex < cardPages.size() - 1) navigateCard(1);
        else checkAiProfileAndNavigate();
    }

    private void updateCtaButton() {
        if (btnCtaText == null || cardPages.isEmpty()) return;
        btnCtaText.animate().alpha(0f).setDuration(120).withEndAction(() -> {
            if (isLockedCard()) {
                btnCtaText.setText("🔒  Unlock Full Report");
                btnCtaText.setTextColor(ContextCompat.getColor(this, R.color.on_background));
                if (ctaCardView != null) ctaCardView.setCardBackgroundColor(COLOR_ACCENT);
            } else if (currentCardIndex == cardPages.size() - 1) {
                btnCtaText.setText("✨  See AI Report");
                btnCtaText.setTextColor(ContextCompat.getColor(this, R.color.on_background));
                if (ctaCardView != null) ctaCardView.setCardBackgroundColor(COLOR_ACCENT);
            } else {
                CardPage next = cardPages.get(currentCardIndex + 1);
                btnCtaText.setText("Next: " + next.sectionIcon + "  " + next.sectionTitle + "  →");
                btnCtaText.setTextColor(ContextCompat.getColor(this, R.color.on_surface));
                if (ctaCardView != null) ctaCardView.setCardBackgroundColor(COLOR_SURFACE_HIGH);
            }
            btnCtaText.animate().alpha(1f).setDuration(180).start();
        }).start();
    }

    private void openAiReportAnalysis() {
        if (!isPremium) {
            OfferDialog.show(this);
        }
    }

    // ═════════════════════════════════════════
    //  AI REPORT NAVIGATION
    // ═════════════════════════════════════════

    private void checkAiProfileAndNavigate() {
        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        if (user == null) {
            Toast.makeText(this, "Please login first", Toast.LENGTH_SHORT).show();
            return;
        }
        if (btnCtaText != null) btnCtaText.setText("⏳  Checking...");
        db.collection("users").document(user.getUid()).collection("aiProfile").limit(1).get()
                .addOnSuccessListener((QuerySnapshot snap) -> {
                    if (btnCtaText != null) btnCtaText.setText("✨  See AI Report");
                    if (snap != null && !snap.isEmpty()) {
                        Intent i = new Intent(this, CreateSevenDaysTaskActivity.class);
                        i.putExtra("scanId", scanId);
                        startActivity(i);
                    } else {
                        Intent i = new Intent(this, AIChatOnboardingActivity.class);
                        i.putExtra("scanId", scanId);
                        i.putExtra("fromScan", true);
                        startActivity(i);
                    }
                })
                .addOnFailureListener(e -> {
                    if (btnCtaText != null) btnCtaText.setText("✨  See AI Report");
                    Toast.makeText(this, "Error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                });
    }

    private void loadData() {
        JSONObject local = localScanManager.loadLocalScan(scanId);
        if (local != null) {
            try {
                onDataLoaded(jsonToMap(local));
                return;
            } catch (Exception e) {
                Log.w(TAG, "local parse: " + e.getMessage());
            }
        }
        firebaseManager.loadScanById(scanId, new FirebaseManager.ScanLoadCallback() {
            @Override
            public void onSuccess(Map<String, Object> data) {
                runOnUiThread(() -> onDataLoaded(data));
            }

            @Override
            public void onFailure(String err) {
                runOnUiThread(() -> {
                    Toast.makeText(DetailedResultsActivity.this, err, Toast.LENGTH_LONG).show();
                    finish();
                });
            }
        });
    }

    // ═════════════════════════════════════════
    //  DATA LOAD
    // ═════════════════════════════════════════

    private void onDataLoaded(Map<String, Object> data) {
        try {
            scanData = data;
            ca = (Map<String, Object>) data.get("comprehensiveAnalysis");
            if (ca == null) {
                finish();
                return;
            }
            photoUrl = (String) scanData.get("photoUrl");
            String photoPath = (String) scanData.get("photoPath");
            String dateCreated = (String) scanData.get("dateCreated");
            if (dateCreated != null) {
                TextView dt = findViewById(R.id.dateText);
                if (dt != null) dt.setText(dateCreated.split(" ")[0].replace("-", "/"));
            }
            if (photoPath != null && new File(photoPath).exists()) {
                Glide.with(this).asBitmap().load(new File(photoPath))
                        .into(new com.bumptech.glide.request.target.CustomTarget<Bitmap>() {
                            @Override
                            public void onResourceReady(Bitmap b, com.bumptech.glide.request.transition.Transition<? super Bitmap> t) {
                                faceBitmap = b;
                                buildUI();
                            }

                            @Override
                            public void onLoadCleared(android.graphics.drawable.Drawable p) {
                            }
                        });
            } else if (photoUrl != null && !photoUrl.isEmpty()) {
                Glide.with(this).asBitmap().load(photoUrl)
                        .into(new com.bumptech.glide.request.target.CustomTarget<Bitmap>() {
                            @Override
                            public void onResourceReady(Bitmap b, com.bumptech.glide.request.transition.Transition<? super Bitmap> t) {
                                faceBitmap = b;
                                buildUI();
                            }

                            @Override
                            public void onLoadCleared(android.graphics.drawable.Drawable p) {
                            }
                        });
            } else {
                buildUI();
            }
        } catch (Exception e) {
            Log.e(TAG, "onDataLoaded", e);
            finish();
        }
    }

    private void buildUI() {
        buildCardPages();
        buildDotIndicators();
        buildIconStrip();
        showCard(0, true);
        runEntranceAnimations();
        updateCtaButton();
    }

    // ═════════════════════════════════════════
    //  BUILD UI
    // ═════════════════════════════════════════

    private void buildCardPages() {
        cardPages.clear();

        CardPage p1 = new CardPage("📊", "Overview");
        p1.metrics.add(new MetricItem("🏆", "Model Potential", gf("modelPotential", "modelScore", "potential"), descFor("model", gf("modelPotential", "modelScore", "potential"))));
        p1.metrics.add(new MetricItem("🔺", "Jawline", gf("jawlineSharpness", "jawlineScore", "jawline"), descFor("jawline", gf("jawlineSharpness", "jawlineScore", "jawline"))));
        p1.metrics.add(new MetricItem("💎", "Cheekbones", gf("cheekboneProminence", "cheekboneScore", "cheekbones"), descFor("cheekbones", gf("cheekboneProminence", "cheekboneScore", "cheekbones"))));
        p1.metrics.add(new MetricItem("💪", "Masculinity", gf("masculinityScore", "masculinity", "maleScore"), descFor("masculinity", gf("masculinityScore", "masculinity", "maleScore"))));
        p1.metrics.add(new MetricItem("✨", "Skin Quality", gf("skinSmooth", "skinQuality", "skinScore"), descFor("skin", gf("skinSmooth", "skinQuality", "skinScore"))));
        p1.metrics.add(new MetricItem("🔥", "Hot Score", gf("hotScore", "hotness", "attractionScore"), descFor("hot", gf("hotScore", "hotness", "attractionScore"))));
        p1.infos.add(new InfoItem("Face Shape", gs("faceShape", "shape", "faceForm")));
        p1.infos.add(new InfoItem("Global Rank", "Top " + gi("globalRanking", "ranking", "percentile") + "%"));
        p1.infos.add(new InfoItem("Beauty Category", ratingOf(gf("attractivenessScore", "overallScore", "overall"))));
        cardPages.add(p1);

        CardPage p2 = new CardPage("⚖️", "Symmetry");
        p2.metrics.add(new MetricItem("⚖️", "Overall Sym", gf("overallSymmetry", "symmetry", "symScore"), descFor("symmetry", gf("overallSymmetry", "symmetry", "symScore"))));
        p2.metrics.add(new MetricItem("↔️", "Horizontal", gf("horizontalSymmetry", "hSymmetry", "symH"), descFor("symmetry", gf("horizontalSymmetry", "hSymmetry", "symH"))));
        p2.metrics.add(new MetricItem("↕️", "Vertical", gf("verticalSymmetry", "vSymmetry", "symV"), descFor("symmetry", gf("verticalSymmetry", "vSymmetry", "symV"))));
        p2.metrics.add(new MetricItem("✕", "Diagonal", gf("diagonalSymmetry", "dSymmetry", "symD"), descFor("symmetry", gf("diagonalSymmetry", "dSymmetry", "symD"))));
        p2.metrics.add(new MetricItem("👁️", "Eye Sym", gf("eyeSymmetry", "eyeSymScore", "eyeSym"), descFor("symmetry", gf("eyeSymmetry", "eyeSymScore", "eyeSym"))));
        p2.metrics.add(new MetricItem("📐", "Golden Ratio", gf("goldenRatioScore", "goldenRatio", "goldenScore"), descFor("ratio", gf("goldenRatioScore", "goldenRatio", "goldenScore"))));
        p2.infos.add(new InfoItem("Face L:W Ratio", df.format(gf("faceLengthToWidthRatio", "faceRatio", "lengthWidthRatio")) + " : 1"));
        p2.infos.add(new InfoItem("Harmony Score", df.format(gf("harmonyScore", "harmonScore", "harmony")) + " / 100"));
        p2.infos.add(new InfoItem("Celebrity Match", gs("celebrityMatch", "celebrity", "lookalike")));
        p2.infos.add(new InfoItem("Youthfulness", df.format(gf("youthfulnessScore", "youthScore", "youth")) + " / 100"));
        p2.infos.add(new InfoItem("Femininity", df.format(gf("femininityScore", "femininity", "femScore")) + " / 100"));
        cardPages.add(p2);

        CardPage p3 = new CardPage("👁️", "Face & Eyes");
        p3.metrics.add(new MetricItem("💠", "Shape Score", gf("faceShapeScore", "shapeScore", "faceScore"), descFor("overall", gf("faceShapeScore", "shapeScore", "faceScore"))));
        p3.metrics.add(new MetricItem("👁️", "Eye Size", gf("eyeSize", "eyeSizeScore", "eyes"), descFor("eye", gf("eyeSize", "eyeSizeScore", "eyes"))));
        p3.metrics.add(new MetricItem("👁️", "Eye Shape", gf("eyeShape", "eyeShapeScore", "eyeForm"), descFor("eye", gf("eyeShape", "eyeShapeScore", "eyeForm"))));
        p3.metrics.add(new MetricItem("⚖️", "Eye Sym", gf("eyeSymmetry", "eyeSymScore", "eyeSym"), descFor("symmetry", gf("eyeSymmetry", "eyeSymScore", "eyeSym"))));
        p3.metrics.add(new MetricItem("🌿", "Brow Arch", gf("eyebrowArch", "browArch", "eyebrow"), descFor("eyebrow", gf("eyebrowArch", "browArch", "eyebrow"))));
        p3.metrics.add(new MetricItem("📏", "Brow Thick", gf("eyebrowThickness", "browThickness", "eyebrowT"), descFor("eyebrow", gf("eyebrowThickness", "browThickness", "eyebrowT"))));
        p3.infos.add(new InfoItem("Face Shape", gs("faceShape", "shape", "faceForm")));
        p3.infos.add(new InfoItem("Eye Color", gs("eyeColor", "irisColor", "eyeColour")));
        p3.infos.add(new InfoItem("Gonial Angle", df.format(gf("gonialAngle", "jawAngle", "gAngle")) + "°"));
        p3.infos.add(new InfoItem("Mandibular Angle", df.format(gf("mandibularAngle", "mandAngle")) + "°"));
        p3.infos.add(new InfoItem("Eye Spacing", df.format(gf("eyeSpacing", "eyeGap", "icd")) + " px"));
        cardPages.add(p3);

        CardPage p4 = new CardPage("👃", "Nose & Lips");
        p4.metrics.add(new MetricItem("👃", "Nose Tip", gf("noseTipShape", "tipShape", "noseTip"), descFor("nose", gf("noseTipShape", "tipShape", "noseTip"))));
        p4.metrics.add(new MetricItem("↔️", "Nose Width", gf("noseWidth", "nWidth", "nose"), descFor("nose", gf("noseWidth", "nWidth", "nose"))));
        p4.metrics.add(new MetricItem("↕️", "Nose Length", gf("noseLength", "nLength", "noseSize"), descFor("nose", gf("noseLength", "nLength", "noseSize"))));
        p4.metrics.add(new MetricItem("⚖️", "Nostril Sym", Math.abs(gf("nostrilSymmetry", "nSymmetry", "nostril")), descFor("symmetry", Math.abs(gf("nostrilSymmetry", "nSymmetry", "nostril")))));
        p4.metrics.add(new MetricItem("💋", "Lip Thick", gf("lipThickness", "lThickness", "lips"), descFor("lip", gf("lipThickness", "lThickness", "lips"))));
        p4.metrics.add(new MetricItem("⚖️", "Lip Sym", gf("lipSymmetry", "lSymmetry", "lipSym"), descFor("symmetry", gf("lipSymmetry", "lSymmetry", "lipSym"))));
        p4.infos.add(new InfoItem("Lip Shape", gs("lipShape", "lShape", "lipForm")));
        p4.infos.add(new InfoItem("Smile Score", df.format(gf("smileIntensity", "smile", "smileScore")) + " / 100"));
        p4.infos.add(new InfoItem("Smile Sym", df.format(gf("smileSymmetry", "smileSym", "sSym")) + " / 100"));
        p4.infos.add(new InfoItem("Overall Beauty", df.format(gf("overallBeautyScore", "beautyScore", "beauty")) + " / 100"));
        p4.infos.add(new InfoItem("Nasolabial Angle", df.format(gf("nasolabialAngle", "nlAngle")) + "°"));
        cardPages.add(p4);

        CardPage p5 = new CardPage("✨", "Skin & Age");
        p5.metrics.add(new MetricItem("✨", "Skin Smooth", gf("skinSmooth", "skinQuality", "skinScore"), descFor("skin", gf("skinSmooth", "skinQuality", "skinScore"))));
        p5.metrics.add(new MetricItem("🔬", "Skin Texture", gf("skinTexture", "texture", "skinTex"), descFor("skin", gf("skinTexture", "texture", "skinTex"))));
        p5.metrics.add(new MetricItem("🎨", "Skin Tone", gf("skinTone", "tone", "skinToneScore"), descFor("skin", gf("skinTone", "tone", "skinToneScore"))));
        p5.metrics.add(new MetricItem("💡", "Lighting", gf("lightingQuality", "lighting", "lightScore"), descFor("overall", gf("lightingQuality", "lighting", "lightScore"))));
        p5.metrics.add(new MetricItem("🔍", "Clarity", gf("faceClarity", "clarity", "sharpness"), descFor("overall", gf("faceClarity", "clarity", "sharpness"))));
        p5.metrics.add(new MetricItem("🌟", "Youthfulness", gf("youthfulnessScore", "youthScore", "youth"), descFor("youth", gf("youthfulnessScore", "youthScore", "youth"))));
        p5.infos.add(new InfoItem("Complexion", gs("skinComplexion", "complexion", "skinType")));
        p5.infos.add(new InfoItem("Estimated Age", gi("estimatedAge", "age", "ageEstimate") + " years"));
        p5.infos.add(new InfoItem("Age Range", gi("ageRangeMin", "minAge", "ageMin") + " – " + gi("ageRangeMax", "maxAge", "ageMax") + " yrs"));
        p5.infos.add(new InfoItem("Emotion", gs("dominantEmotion", "emotion", "mood")));
        p5.infos.add(new InfoItem("Ethnicity", gs("primaryEthnicity", "ethnicity", "origin")));
        p5.infos.add(new InfoItem("Eth. Confidence", df.format(gf("ethnicityConfidence", "confidence", "ethnicityScore")) + "%"));
        try {
            List<Map<String, Object>> bd = (List<Map<String, Object>>) ca.get("ethnicityBreakdown");
            if (bd != null) for (Map<String, Object> m : bd)
                try {
                    p5.infos.add(new InfoItem("🌍 " + m.get("ethnicity"), df.format(((Number) m.get("percentage")).floatValue()) + "%"));
                } catch (Exception ignored) {
                }
        } catch (Exception ignored) {
        }
        cardPages.add(p5);
    }

    // ═════════════════════════════════════════
    //  BUILD CARD PAGES
    // ═════════════════════════════════════════

    private void buildDotIndicators() {
        if (cardDotIndicator == null) return;
        cardDotIndicator.removeAllViews();
        for (int i = 0; i < cardPages.size(); i++) {
            View dot = new View(this);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(dp(6), dp(6));
            lp.setMarginEnd(dp(5));
            dot.setLayoutParams(lp);
            dot.setBackground(makeRoundRect(i == 0 ? COLOR_ACCENT : COLOR_SURFACE_HIGH, dp(3)));
            cardDotIndicator.addView(dot);
        }
    }

    // ═════════════════════════════════════════
    //  DOT INDICATORS + ICON STRIP
    // ═════════════════════════════════════════

    private void buildIconStrip() {
        if (cardIconStrip == null) return;
        cardIconStrip.removeAllViews();
        for (int i = 0; i < cardPages.size(); i++) {
            final int idx = i;
            TextView tv = new TextView(this);
            tv.setText(cardPages.get(i).sectionIcon);
            tv.setTextSize(i == 0 ? 16f : 12f);
            tv.setAlpha(i == 0 ? 1f : 0.35f);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            lp.setMarginEnd(dp(6));
            tv.setLayoutParams(lp);
            tv.setClickable(true);
            tv.setFocusable(true);
            tv.setOnClickListener(v -> {
                currentCardIndex = idx;
                showCard(currentCardIndex, false);
                updateDotIndicators();
                updateIconStrip();
                updateCtaButton();
                updateSectionHeader();
            });
            cardIconStrip.addView(tv);
        }
        TextView lbl = new TextView(this);
        lbl.setTag("__pl__");
        lbl.setText("1/" + cardPages.size());
        lbl.setTextColor(0xFF1E3A5A);
        lbl.setTextSize(10f);
        lbl.setTypeface(null, Typeface.BOLD);
        LinearLayout.LayoutParams plp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        plp.setMarginStart(dp(4));
        lbl.setLayoutParams(plp);
        cardIconStrip.addView(lbl);
    }

    private void updateDotIndicators() {
        if (cardDotIndicator == null) return;
        for (int i = 0; i < cardDotIndicator.getChildCount(); i++) {
            View dot = cardDotIndicator.getChildAt(i);
            LinearLayout.LayoutParams lp = (LinearLayout.LayoutParams) dot.getLayoutParams();
            int toW = (i == currentCardIndex) ? dp(18) : dp(6);
            if (lp.width != toW) {
                ValueAnimator wa = ValueAnimator.ofInt(lp.width, toW);
                wa.setDuration(220).setInterpolator(new OvershootInterpolator(1.5f));
                wa.addUpdateListener(a -> {
                    lp.width = (int) a.getAnimatedValue();
                    dot.setLayoutParams(lp);
                });
                wa.start();
            }
            dot.setBackground(makeRoundRect(i == currentCardIndex ? COLOR_ACCENT : COLOR_SURFACE_HIGH, dp(3)));
        }
        if (cardPageLabel != null)
            cardPageLabel.setText((currentCardIndex + 1) + " / " + cardPages.size());
        if (btnCardPrev != null)
            btnCardPrev.animate().alpha(currentCardIndex == 0 ? 0.3f : 1f).setDuration(200).start();
        if (btnCardNext != null)
            btnCardNext.animate().alpha(currentCardIndex == cardPages.size() - 1 ? 0.3f : 1f).setDuration(200).start();
    }

    private void updateIconStrip() {
        if (cardIconStrip == null) return;
        int tvIdx = 0;
        for (int i = 0; i < cardIconStrip.getChildCount(); i++) {
            View child = cardIconStrip.getChildAt(i);
            if ("__pl__".equals(child.getTag())) {
                ((TextView) child).setText((currentCardIndex + 1) + "/" + cardPages.size());
                continue;
            }
            if (child instanceof TextView) {
                boolean active = (tvIdx == currentCardIndex);
                child.animate().alpha(active ? 1f : 0.35f).setDuration(200).start();
                ((TextView) child).setTextSize(active ? 16f : 12f);
                tvIdx++;
            }
        }
    }

    private void updateSectionHeader() {
        if (cardPages.isEmpty()) return;
        CardPage page = cardPages.get(currentCardIndex);
        if (cardSectionIcon != null)
            cardSectionIcon.animate().alpha(0f).setDuration(100).withEndAction(() -> {
                cardSectionIcon.setText(page.sectionIcon);
                cardSectionIcon.animate().alpha(1f).setDuration(150).start();
            }).start();
        if (cardSectionTitle != null)
            cardSectionTitle.animate().alpha(0f).setDuration(100).withEndAction(() -> {
                cardSectionTitle.setText(page.sectionTitle.toUpperCase(Locale.US));
                cardSectionTitle.animate().alpha(1f).setDuration(150).start();
            }).start();
    }

    private void navigateCard(int dir) {
        int next = currentCardIndex + dir;
        if (next < 0 || next >= cardPages.size() || isFlipping) return;
        isFlipping = true;
        cardFlipContainer.setCameraDistance(8000 * getResources().getDisplayMetrics().density);
        ObjectAnimator out = ObjectAnimator.ofFloat(cardFlipContainer, "rotationY", 0f, dir > 0 ? 90f : -90f);
        out.setDuration(200).setInterpolator(new AccelerateDecelerateInterpolator());
        out.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator a) {
                currentCardIndex = next;
                showCard(currentCardIndex, false);
                updateDotIndicators();
                updateIconStrip();
                updateCtaButton();
                updateSectionHeader();
                cardFlipContainer.setRotationY(dir > 0 ? -90f : 90f);
                ObjectAnimator in = ObjectAnimator.ofFloat(cardFlipContainer, "rotationY", dir > 0 ? -90f : 90f, 0f);
                in.setDuration(200).setInterpolator(new AccelerateDecelerateInterpolator());
                in.addListener(new AnimatorListenerAdapter() {
                    @Override
                    public void onAnimationEnd(Animator a2) {
                        isFlipping = false;
                    }
                });
                in.start();
            }
        });
        out.start();
    }

    // ═════════════════════════════════════════
    //  CARD NAVIGATION
    // ═════════════════════════════════════════

    private void showCard(int index, boolean animateMetrics) {
        if (cardFlipContainer == null || index >= cardPages.size()) return;
        cardFlipContainer.removeAllViews();

        CardPage page = cardPages.get(index);
        float overallScore = gf("attractivenessScore", "overallScore", "overall");
        int overallColor = colorFor(this, overallScore);

        View cardView = LayoutInflater.from(this)
                .inflate(R.layout.item_analysis_card, cardFlipContainer, false);
        populateCardContent(cardView, page, overallScore, overallColor, animateMetrics, index);

        FrameLayout builtInOverlay = cardView.findViewById(R.id.premiumOverlay);
        if (builtInOverlay != null) builtInOverlay.setVisibility(View.GONE);

        cardView.setAlpha(0f);
        cardView.setScaleX(0.96f);
        cardView.setScaleY(0.96f);
        cardFlipContainer.addView(cardView);
        cardView.animate().alpha(1f).scaleX(1f).scaleY(1f)
                .setDuration(280).setInterpolator(new OvershootInterpolator(1.2f)).start();

        if (!isPremium && index > 0) applyPremiumBlurOverlay(cardFlipContainer);
    }

    // ═════════════════════════════════════════
    //  SHOW CARD
    // ═════════════════════════════════════════

    private void applyPremiumBlurOverlay(FrameLayout container) {
        // Blur / dim the card behind
        View cardChild = container.getChildAt(0);
        if (cardChild != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                cardChild.setRenderEffect(android.graphics.RenderEffect.createBlurEffect(
                        22f, 22f, android.graphics.Shader.TileMode.CLAMP));
            } else {
                cardChild.setAlpha(0.12f);
            }
        }

        FrameLayout overlay = new FrameLayout(this);
        overlay.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        // Deep dark gradient background
        View dimBg = new View(this) {
            @Override
            protected void onDraw(Canvas canvas) {
                android.graphics.drawable.GradientDrawable grad =
                        new android.graphics.drawable.GradientDrawable(
                                android.graphics.drawable.GradientDrawable.Orientation.TOP_BOTTOM,
                                new int[]{
                                        ContextCompat.getColor(DetailedResultsActivity.this, R.id.main == 0 ? R.color.surface : R.color.surface),
                                        ContextCompat.getColor(DetailedResultsActivity.this, R.color.surface_dim),
                                        ContextCompat.getColor(DetailedResultsActivity.this, R.color.surface_container_lowest)
                                });
                grad.setBounds(0, 0, getWidth(), getHeight());
                grad.draw(canvas);
            }
        };
        dimBg.setWillNotDraw(false);
        dimBg.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        overlay.addView(dimBg);

        // ── Center premium card ──
        LinearLayout centerCard = new LinearLayout(this);
        centerCard.setOrientation(LinearLayout.VERTICAL);
        centerCard.setGravity(android.view.Gravity.CENTER);
        FrameLayout.LayoutParams cp = new FrameLayout.LayoutParams(dp(290), FrameLayout.LayoutParams.WRAP_CONTENT);
        cp.gravity = android.view.Gravity.CENTER;
        centerCard.setLayoutParams(cp);
        centerCard.setPadding(dp(24), dp(28), dp(24), dp(28));

        // Card background: dark navy with gold border
        android.graphics.drawable.GradientDrawable cardBg = new android.graphics.drawable.GradientDrawable();
        cardBg.setShape(android.graphics.drawable.GradientDrawable.RECTANGLE);
        cardBg.setCornerRadius(dp(20));
        cardBg.setColor(COLOR_SURFACE_HIGH);
        cardBg.setStroke(dp(1), COLOR_ACCENT); // accent border
        centerCard.setBackground(cardBg);

        // Crown icon
        TextView crownIcon = new TextView(this);
        crownIcon.setText("👑");
        crownIcon.setTextSize(44f);
        crownIcon.setGravity(android.view.Gravity.CENTER);
        crownIcon.setPadding(0, 0, 0, dp(6));
        // Crown bounce animation
        ValueAnimator crownAnim = ValueAnimator.ofFloat(1f, 1.18f, 1f);
        crownAnim.setDuration(1800);
        crownAnim.setRepeatCount(ValueAnimator.INFINITE);
        crownAnim.setInterpolator(new AccelerateDecelerateInterpolator());
        crownAnim.addUpdateListener(a -> {
            float s = (float) a.getAnimatedValue();
            crownIcon.setScaleX(s);
            crownIcon.setScaleY(s);
        });
        crownAnim.start();
        centerCard.addView(crownIcon);

        // "PREMIUM" gold badge
        TextView premiumBadge = new TextView(this);
        premiumBadge.setText("P R E M I U M");
        premiumBadge.setTextSize(10f);
        premiumBadge.setTypeface(null, Typeface.BOLD);
        premiumBadge.setLetterSpacing(0.22f);
        premiumBadge.setGravity(android.view.Gravity.CENTER);
        android.graphics.drawable.GradientDrawable badgeBg = new android.graphics.drawable.GradientDrawable();
        badgeBg.setShape(android.graphics.drawable.GradientDrawable.RECTANGLE);
        badgeBg.setCornerRadius(dp(20));
        badgeBg.setColor(ContextCompat.getColor(this, R.color.warning) & 0x33FFFFFF | 0x1A000000); // Muted warning bg
        badgeBg.setStroke(1, COLOR_WARNING);
        premiumBadge.setBackground(badgeBg);
        premiumBadge.setTextColor(COLOR_WARNING);
        premiumBadge.setPadding(dp(16), dp(5), dp(16), dp(5));
        LinearLayout.LayoutParams badgeLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        badgeLp.gravity = android.view.Gravity.CENTER_HORIZONTAL;
        badgeLp.bottomMargin = dp(14);
        premiumBadge.setLayoutParams(badgeLp);
        centerCard.addView(premiumBadge);

        // Title
        TextView title = new TextView(this);
        title.setText("Unlock Full Analysis");
        title.setTextColor(ContextCompat.getColor(this, R.color.on_surface));
        title.setTextSize(19f);
        title.setTypeface(null, Typeface.BOLD);
        title.setGravity(android.view.Gravity.CENTER);
        LinearLayout.LayoutParams titleLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        titleLp.bottomMargin = dp(6);
        title.setLayoutParams(titleLp);
        centerCard.addView(title);

        // Subtitle
        TextView subtitle = new TextView(this);
        subtitle.setText("Get your complete face report\nwith deep AI insights");
        subtitle.setTextColor(ContextCompat.getColor(this, R.color.on_surface_variant));
        subtitle.setTextSize(12f);
        subtitle.setGravity(android.view.Gravity.CENTER);
        LinearLayout.LayoutParams subLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        subLp.bottomMargin = dp(20);
        subtitle.setLayoutParams(subLp);
        centerCard.addView(subtitle);

        // ── Feature list with gold checkmarks ──
        String[][] features = {
                {"⚖️", "Symmetry & Golden Ratio"},
                {"👁️", "Eyes, Face & Structure"},
                {"💋", "Nose & Lips Analysis"},
                {"✨", "Skin Health & Age Score"},
                {"🤖", "AI Personalized Report"},
                {"📅", "7-Day Glow-Up Plan"}
        };
        LinearLayout featureBox = new LinearLayout(this);
        featureBox.setOrientation(LinearLayout.VERTICAL);
        android.graphics.drawable.GradientDrawable featureBg = new android.graphics.drawable.GradientDrawable();
        featureBg.setShape(android.graphics.drawable.GradientDrawable.RECTANGLE);
        featureBg.setCornerRadius(dp(12));
        featureBg.setColor(ContextCompat.getColor(this, R.color.surface_container));
        featureBox.setBackground(featureBg);
        featureBox.setPadding(dp(16), dp(12), dp(16), dp(12));
        LinearLayout.LayoutParams fbLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        fbLp.bottomMargin = dp(20);
        featureBox.setLayoutParams(fbLp);

        for (int i = 0; i < features.length; i++) {
            LinearLayout row = new LinearLayout(this);
            row.setOrientation(LinearLayout.HORIZONTAL);
            row.setGravity(android.view.Gravity.CENTER_VERTICAL);
            LinearLayout.LayoutParams rowLp = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            rowLp.bottomMargin = (i < features.length - 1) ? dp(8) : 0;
            row.setLayoutParams(rowLp);

            // Gold check dot
            View dot = new View(this);
            android.graphics.drawable.GradientDrawable dotBg = new android.graphics.drawable.GradientDrawable();
            dotBg.setShape(android.graphics.drawable.GradientDrawable.OVAL);
            dotBg.setColor(COLOR_WARNING);
            dot.setBackground(dotBg);
            LinearLayout.LayoutParams dotLp = new LinearLayout.LayoutParams(dp(6), dp(6));
            dotLp.setMarginEnd(dp(10));
            dotLp.gravity = android.view.Gravity.CENTER_VERTICAL;
            dot.setLayoutParams(dotLp);
            row.addView(dot);

            TextView emoji = new TextView(this);
            emoji.setText(features[i][0] + " ");
            emoji.setTextSize(13f);
            LinearLayout.LayoutParams eLp = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            emoji.setLayoutParams(eLp);
            row.addView(emoji);

            TextView feat = new TextView(this);
            feat.setText(features[i][1]);
            feat.setTextColor(0xFFAABBCC);
            feat.setTextSize(12f);
            row.addView(feat);

            featureBox.addView(row);
        }
        centerCard.addView(featureBox);

        // ── Unlock button — gold gradient effect ──
        CardView unlockBtn = new CardView(this);
        LinearLayout.LayoutParams btnLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(52));
        btnLp.bottomMargin = dp(12);
        unlockBtn.setLayoutParams(btnLp);
        unlockBtn.setCardBackgroundColor(Color.TRANSPARENT);
        unlockBtn.setRadius(dp(26));
        unlockBtn.setCardElevation(dp(10));
        unlockBtn.setClickable(true);
        unlockBtn.setFocusable(true);
        unlockBtn.setOnClickListener(v -> {
            pulseView(unlockBtn);
            mainHandler.postDelayed(() -> OfferDialog.show(this), 150);
        });

        // Gold gradient background for button
        View btnGradBg = new View(this) {
            @Override
            protected void onDraw(Canvas canvas) {
                android.graphics.LinearGradient grad = new android.graphics.LinearGradient(
                        0, 0, getWidth(), 0,
                        new int[]{0xFFF5C842, 0xFFE8A020, 0xFFF5C842},
                        null, android.graphics.Shader.TileMode.CLAMP);
                Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
                p.setShader(grad);
                canvas.drawRoundRect(new RectF(0, 0, getWidth(), getHeight()), dp(26), dp(26), p);
            }
        };
        btnGradBg.setWillNotDraw(false);
        btnGradBg.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        LinearLayout btnInner = new LinearLayout(this);
        btnInner.setOrientation(LinearLayout.HORIZONTAL);
        btnInner.setGravity(android.view.Gravity.CENTER);
        FrameLayout.LayoutParams biLp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
        btnInner.setLayoutParams(biLp);

        TextView lockEmoji = new TextView(this);
        lockEmoji.setText("🔓  ");
        lockEmoji.setTextSize(15f);
        btnInner.addView(lockEmoji);

        TextView btnText = new TextView(this);
        btnText.setText("Unlock Full Report");
        btnText.setTextColor(0xFF000000);
        btnText.setTextSize(14f);
        btnText.setTypeface(null, Typeface.BOLD);
        btnInner.addView(btnText);

        FrameLayout btnFrame = new FrameLayout(this);
        btnFrame.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        btnFrame.addView(btnGradBg);
        btnFrame.addView(btnInner);
        unlockBtn.addView(btnFrame);
        centerCard.addView(unlockBtn);

        // "Maybe later" link
        TextView laterLink = new TextView(this);
        laterLink.setText("Maybe later");
        laterLink.setTextColor(0xFF1E3A5A);
        laterLink.setTextSize(11f);
        laterLink.setGravity(android.view.Gravity.CENTER);
        laterLink.setPadding(0, dp(2), 0, 0);
        laterLink.setClickable(true);
        laterLink.setFocusable(true);
        laterLink.setOnClickListener(v -> {
            // Navigate back to first card (Overview)
            currentCardIndex = 0;
            showCard(0, false);
            updateDotIndicators();
            updateIconStrip();
            updateCtaButton();
            updateSectionHeader();
        });
        centerCard.addView(laterLink);

        overlay.addView(centerCard);

        // ── Shimmer top accent line ──
        View shimmerLine = new View(this) {
            @Override
            protected void onDraw(Canvas canvas) {
                android.graphics.LinearGradient shimmer = new android.graphics.LinearGradient(
                        0, 0, getWidth(), 0,
                        new int[]{Color.TRANSPARENT, 0xFFC9A84C, 0xFFFFE566, 0xFFC9A84C, Color.TRANSPARENT},
                        null, android.graphics.Shader.TileMode.CLAMP);
                Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
                p.setShader(shimmer);
                canvas.drawRect(0, 0, getWidth(), getHeight(), p);
            }
        };
        shimmerLine.setWillNotDraw(false);
        FrameLayout.LayoutParams slp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, dp(2));
        slp.gravity = android.view.Gravity.TOP;
        shimmerLine.setLayoutParams(slp);
        overlay.addView(shimmerLine);

        overlay.setAlpha(0f);
        container.addView(overlay);
        overlay.animate().alpha(1f).setDuration(350).setInterpolator(new DecelerateInterpolator()).start();

        // Subtle scale-in for center card
        centerCard.setScaleX(0.88f);
        centerCard.setScaleY(0.88f);
        centerCard.setAlpha(0f);
        centerCard.animate().scaleX(1f).scaleY(1f).alpha(1f)
                .setDuration(420).setStartDelay(80)
                .setInterpolator(new OvershootInterpolator(1.4f)).start();
    }

    // ═════════════════════════════════════════
    //  PREMIUM BLUR OVERLAY  (cards 2–5)
    //  ✦ Beautiful premium gate with gold accents
    // ═════════════════════════════════════════

    private void populateCardContent(View cardView, CardPage page, float overallScore,
                                     int overallColor, boolean animateMetrics, int index) {

        // ── Header ──────────────────────────────
        TextView titleIcon = cardView.findViewById(R.id.cardTitleIcon);
        TextView titleText = cardView.findViewById(R.id.cardTitleText);
        if (titleIcon != null) titleIcon.setText(page.sectionIcon);
        if (titleText != null) titleText.setText(page.sectionTitle.toUpperCase(Locale.US));

        // "✨ AI Report" button (top-right)
        View btnViewAi = cardView.findViewById(R.id.btnViewAiAnalysis);
        if (btnViewAi != null) btnViewAi.setOnClickListener(v -> openAiReportAnalysis());

        // Hide legacy share icon
        ImageView btnShareTop = cardView.findViewById(R.id.btnCardShare);
        if (btnShareTop != null) btnShareTop.setVisibility(View.GONE);

        // ── Overview Section ─────────────────────
        RoundedImageView heroImg = cardView.findViewById(R.id.heroFaceImageCard);
        if (heroImg != null) {
            if (faceBitmap != null) heroImg.setImageBitmap(faceBitmap);
            else if (photoUrl != null) Glide.with(this).load(photoUrl).circleCrop().into(heroImg);
        }

        View ringView = cardView.findViewById(R.id.overallRingView);
        if (ringView != null)
            ringView.post(() -> drawCircularRing(ringView, overallScore, overallColor));

        TextView heroScoreView = cardView.findViewById(R.id.heroScoreCard);
        if (heroScoreView != null) {
            heroScoreView.setTextColor(overallColor);
            ValueAnimator va = ValueAnimator.ofFloat(0f, overallScore);
            va.setDuration(animateMetrics ? 1400 : 0).setInterpolator(new AccelerateDecelerateInterpolator());
            va.addUpdateListener(a -> heroScoreView.setText(String.valueOf((int) (float) a.getAnimatedValue())));
            va.start();
        }

        TextView heroRatingView = cardView.findViewById(R.id.heroRatingCard);
        if (heroRatingView != null) {
            heroRatingView.setText(ratingOf(overallScore));
            heroRatingView.setTextColor(overallColor);
        }

        TextView cardOvRank = cardView.findViewById(R.id.ovGlobalRank);
        if (cardOvRank != null)
            cardOvRank.setText("Top " + gi("globalRanking", "ranking", "percentile") + "%");

        TextView cardOvShape = cardView.findViewById(R.id.ovFaceShape);
        if (cardOvShape != null) cardOvShape.setText(gs("faceShape", "shape", "faceForm"));

        TextView cardOvAge = cardView.findViewById(R.id.ovAge);
        if (cardOvAge != null) cardOvAge.setText(gi("estimatedAge", "age", "ageEstimate") + " yrs");

        TextView cardOvEthnicity = cardView.findViewById(R.id.ovEthnicity);
        if (cardOvEthnicity != null)
            cardOvEthnicity.setText(gs("primaryEthnicity", "ethnicity", "origin"));

        TextView cardOvCelebrity = cardView.findViewById(R.id.ovCelebrity);
        if (cardOvCelebrity != null)
            cardOvCelebrity.setText(gs("celebrityMatch", "celebrity", "lookalike"));

        TextView cardOvEmotion = cardView.findViewById(R.id.ovEmotion);
        if (cardOvEmotion != null) cardOvEmotion.setText(gs("dominantEmotion", "emotion", "mood"));

        // ── Metrics Grid ─────────────────────────
        LinearLayout metricsContainer = cardView.findViewById(R.id.metricsGridContainer);
        if (metricsContainer != null) {
            metricsContainer.removeAllViews();
            int cols = 3;
            for (int i = 0; i < page.metrics.size(); i += cols) {
                LinearLayout row = new LinearLayout(this);
                row.setOrientation(LinearLayout.HORIZONTAL);
                LinearLayout.LayoutParams rlp = new LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
                rlp.bottomMargin = dp(8);
                row.setLayoutParams(rlp);
                for (int j = i; j < Math.min(i + cols, page.metrics.size()); j++) {
                    row.addView(buildMetricCell(page.metrics.get(j), animateMetrics ? j * 120L : 0L));
                    if (j < Math.min(i + cols, page.metrics.size()) - 1) {
                        View gap = new View(this);
                        gap.setLayoutParams(new LinearLayout.LayoutParams(dp(8), 1));
                        row.addView(gap);
                    }
                }
                metricsContainer.addView(row);
            }
        }

        // ── Info Rows ────────────────────────────
        LinearLayout infoContainer = cardView.findViewById(R.id.infoRowsContainer);
        if (infoContainer != null) {
            infoContainer.removeAllViews();
            for (int i = 0; i < page.infos.size(); i++) {
                View infoRow = buildInfoRow(page.infos.get(i).label, page.infos.get(i).value);
                infoRow.setAlpha(0f);
                infoRow.setTranslationX(20f);
                final long delay = animateMetrics ? 600L + i * 60L : i * 30L;
                infoRow.animate().alpha(1f).translationX(0f).setStartDelay(delay).setDuration(300)
                        .setInterpolator(new DecelerateInterpolator()).start();
                infoContainer.addView(infoRow);
            }
            if (index == cardPages.size() - 1) {
                addTextListToContainer(infoContainer, "uniqueFeatures", "✨", "Unique Feature");
                addTextListToContainer(infoContainer, "strengths", "💪", "Strength");
                addTextListToContainer(infoContainer, "improvements", "💡", "Suggestion");
            }
        }

        // ── Social Share Strip ───────────────────
        LinearLayout shareStrip = cardView.findViewById(R.id.socialShareStrip);
        if (shareStrip != null) {
            shareStrip.removeAllViews();
            addSocialShareButton(shareStrip, "instagram", page);
            addSocialShareButton(shareStrip, "facebook", page);
            addSocialShareButton(shareStrip, "whatsapp", page);
            addSocialShareButton(shareStrip, "more", page);
        }
    }

    // ═════════════════════════════════════════
    //  POPULATE CARD CONTENT
    // ═════════════════════════════════════════

    private void addSocialShareButton(LinearLayout container, String platform, CardPage page) {
        LinearLayout btn = new LinearLayout(this);
        btn.setOrientation(LinearLayout.VERTICAL);
        btn.setGravity(android.view.Gravity.CENTER);
        btn.setLayoutParams(new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        btn.setClickable(true);
        btn.setFocusable(true);

        FrameLayout iconCircle = new FrameLayout(this);
        int sz = dp(42);
        FrameLayout.LayoutParams clp = new FrameLayout.LayoutParams(sz, sz);
        clp.gravity = android.view.Gravity.CENTER_HORIZONTAL;
        iconCircle.setLayoutParams(clp);

        String emoji;
        int bgColor;
        String label;
        switch (platform) {
            case "instagram":
                emoji = "📸";
                bgColor = 0xFF833AB4;
                label = "Instagram";
                break;
            case "facebook":
                emoji = "👍";
                bgColor = 0xFF1877F2;
                label = "Facebook";
                break;
            case "whatsapp":
                emoji = "💬";
                bgColor = 0xFF25D366;
                label = "WhatsApp";
                break;
            default:
                emoji = "⋯";
                bgColor = 0xFF1C2B3A;
                label = "More";
                break;
        }

        android.graphics.drawable.GradientDrawable circleBg = new android.graphics.drawable.GradientDrawable();
        circleBg.setShape(android.graphics.drawable.GradientDrawable.OVAL);
        circleBg.setColor(bgColor);
        iconCircle.setBackground(circleBg);

        TextView emojiView = new TextView(this);
        emojiView.setText(emoji);
        emojiView.setTextSize(18f);
        emojiView.setGravity(android.view.Gravity.CENTER);
        emojiView.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        iconCircle.addView(emojiView);

        TextView labelView = new TextView(this);
        labelView.setText(label);
        labelView.setTextColor(0xFF8899AA);
        labelView.setTextSize(9f);
        labelView.setGravity(android.view.Gravity.CENTER);
        LinearLayout.LayoutParams llp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        llp.topMargin = dp(4);
        labelView.setLayoutParams(llp);

        btn.addView(iconCircle);
        btn.addView(labelView);
        btn.setOnClickListener(v -> {
            bounceView(iconCircle);
            mainHandler.postDelayed(() -> shareCardToPlatform(page, platform), 120);
        });
        container.addView(btn);
    }

    // ═════════════════════════════════════════
    //  SOCIAL SHARE BUTTONS
    // ═════════════════════════════════════════

    private void shareCardToPlatform(CardPage page, String platform) {
        // Find the live card view currently shown in cardFlipContainer
        if (cardFlipContainer == null || cardFlipContainer.getChildCount() == 0) return;
        View cardView = cardFlipContainer.getChildAt(0);

        // Find the @+id/CreateShareImage LinearLayout inside the card
        View shareTarget = cardView.findViewById(R.id.CreateShareImage);
        if (shareTarget == null) {
            Toast.makeText(this, "Share view not found", Toast.LENGTH_SHORT).show();
            return;
        }

        Toast.makeText(this, "Generating image…", Toast.LENGTH_SHORT).show();

        // Wait one frame so the view is fully drawn, then capture
        shareTarget.post(() -> {
            try {
                // Capture the view as-is into a Bitmap
                shareTarget.setDrawingCacheEnabled(false);
                Bitmap bmp = Bitmap.createBitmap(
                        shareTarget.getWidth(), shareTarget.getHeight(),
                        Bitmap.Config.ARGB_8888);
                Canvas canvas = new Canvas(bmp);
                canvas.drawColor(0xFF060C18);
                shareTarget.draw(canvas);

                // Subtle watermark at bottom
                drawWatermarkOnBitmap(canvas, bmp.getWidth(), bmp.getHeight());

                // Save to cache
                java.io.File file = new java.io.File(getCacheDir(),
                        "growup_share_" + System.currentTimeMillis() + ".jpg");
                java.io.FileOutputStream fos = new java.io.FileOutputStream(file);
                bmp.compress(Bitmap.CompressFormat.JPEG, 95, fos);
                fos.close();
                bmp.recycle();

                // Fire share intent
                Uri uri = FileProvider.getUriForFile(this, getPackageName() + ".provider", file);
                float score = gf("attractivenessScore", "overallScore", "overall");
                String text = "My " + page.sectionTitle + " Analysis 🔥\n"
                        + "Score: " + (int) score + "/100  •  " + ratingOf(score) + "\n"
                        + "#GrowUpAI #FaceAnalysis #AIBeauty";

                Intent si = new Intent(Intent.ACTION_SEND);
                si.setType("image/jpeg");
                si.putExtra(Intent.EXTRA_STREAM, uri);
                si.putExtra(Intent.EXTRA_TEXT, text);
                si.setClipData(android.content.ClipData.newUri(
                        getContentResolver(), "GrowUp AI", uri));
                si.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

                switch (platform) {
                    case "instagram":
                        si.setPackage("com.instagram.android");
                        break;
                    case "facebook":
                        si.setPackage("com.facebook.katana");
                        break;
                    case "whatsapp":
                        si.setPackage("com.whatsapp");
                        break;
                }
                try {
                    startActivity(si);
                } catch (android.content.ActivityNotFoundException e) {
                    si.setPackage(null);
                    startActivity(Intent.createChooser(si, "Share via"));
                }

            } catch (Exception e) {
                Toast.makeText(this, "Share failed: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }

    // ═════════════════════════════════════════
    //  SHARE TO PLATFORM
    // ═════════════════════════════════════════

    // ── Subtle watermark drawn on the captured bitmap ──────────────
    private void drawWatermarkOnBitmap(Canvas canvas, int w, int h) {
        int padH = dp(14), padV = dp(10), logoSz = dp(18);

        // Semi-transparent bottom strip
        Paint bgP = new Paint(Paint.ANTI_ALIAS_FLAG);
        bgP.setColor(0xBB060C18);
        canvas.drawRect(0, h - logoSz - padV * 2, w, h, bgP);

        // Thin separator line
        Paint lineP = new Paint(Paint.ANTI_ALIAS_FLAG);
        lineP.setColor(0xFF0D2540);
        lineP.setStrokeWidth(dp(1));
        canvas.drawLine(0, h - logoSz - padV * 2, w, h - logoSz - padV * 2, lineP);

        // App icon
        try {
            android.graphics.drawable.Drawable icon =
                    androidx.core.content.ContextCompat.getDrawable(this, R.mipmap.ic_launcher_round);
            if (icon != null) {
                Bitmap iconBmp = Bitmap.createBitmap(logoSz, logoSz, Bitmap.Config.ARGB_8888);
                icon.setBounds(0, 0, logoSz, logoSz);
                icon.setAlpha(70);
                icon.draw(new Canvas(iconBmp));
                Paint iconP = new Paint(Paint.ANTI_ALIAS_FLAG);
                iconP.setAlpha(70);
                canvas.drawBitmap(iconBmp, padH, h - logoSz - padV, iconP);
                iconBmp.recycle();
            }
        } catch (Exception ignored) {
        }

        // "GrowUp AI  •  growup.ai" text
        Paint textP = new Paint(Paint.ANTI_ALIAS_FLAG);
        textP.setColor(0x55AABBCC);
        textP.setTextSize(dp(11));
        textP.setTypeface(Typeface.DEFAULT_BOLD);
        textP.setLetterSpacing(0.05f);
        float textX = padH + logoSz + dp(7);
        float textY = h - padV - (logoSz / 2f)
                + (-textP.ascent() - textP.descent()) / 2f;
        canvas.drawText("GrowUp AI  •  growup.ai", textX, textY, textP);
    }

    private View buildMetricCell(MetricItem m, long startDelay) {
        View cell = LayoutInflater.from(this).inflate(R.layout.item_circular_metric, null);
        cell.setLayoutParams(new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        int color = colorFor(this, m.score);
        TextView valueView = cell.findViewById(R.id.metricValue);
        TextView labelView = cell.findViewById(R.id.metricLabel);
        TextView descView = cell.findViewById(R.id.metricDesc);
        if (labelView != null) labelView.setText(m.label);
        if (descView != null) descView.setText(m.desc);
        if (valueView != null) valueView.setTextColor(color);
        View ringBg = cell.findViewById(R.id.metricRingBg);
        View ringFg = cell.findViewById(R.id.metricRingFg);
        if (ringBg != null)
            ringBg.post(() -> ringBg.setBackground(buildRingDrawable(100f, 0xFF1C2B3A, false)));
        if (ringFg != null && valueView != null) {
            ringFg.post(() -> {
                ValueAnimator va = ValueAnimator.ofFloat(0f, m.score);
                va.setStartDelay(startDelay);
                va.setDuration(900);
                va.setInterpolator(new AccelerateDecelerateInterpolator());
                va.addUpdateListener(a -> {
                    float v = (float) a.getAnimatedValue();
                    valueView.setText(String.valueOf((int) v));
                    ringFg.setBackground(buildRingDrawable(v, color, true));
                });
                va.start();
            });
        }
        cell.setAlpha(0f);
        cell.setScaleX(0.7f);
        cell.setScaleY(0.7f);
        cell.animate().alpha(1f).scaleX(1f).scaleY(1f)
                .setStartDelay(startDelay).setDuration(400).setInterpolator(new OvershootInterpolator(1.8f)).start();
        return cell;
    }

    // ═════════════════════════════════════════
    //  METRIC CELL
    // ═════════════════════════════════════════

    private android.graphics.drawable.Drawable buildRingDrawable(float progress, int color, boolean arc) {
        return new android.graphics.drawable.Drawable() {
            @Override
            public void draw(Canvas canvas) {
                android.graphics.Rect b = getBounds();
                float cx = b.width() / 2f, cy = b.height() / 2f, stroke = dp(7);
                float r = Math.min(cx, cy) - stroke / 2f - dp(1);
                RectF oval = new RectF(cx - r, cy - r, cx + r, cy + r);
                Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
                p.setStyle(Paint.Style.STROKE);
                p.setStrokeWidth(stroke);
                p.setStrokeCap(Paint.Cap.ROUND);
                p.setColor(color);
                if (!arc) canvas.drawArc(oval, 0f, 360f, false, p);
                else canvas.drawArc(oval, -90f, (progress / 100f) * 360f, false, p);
            }

            @Override
            public void setAlpha(int a) {
            }

            @Override
            public void setColorFilter(android.graphics.ColorFilter cf) {
            }

            @Override
            public int getOpacity() {
                return android.graphics.PixelFormat.TRANSLUCENT;
            }
        };
    }

    // ═════════════════════════════════════════
    //  RING DRAWABLE
    // ═════════════════════════════════════════

    private void drawCircularRing(View view, float progress, int color) {
        int size = view.getWidth();
        if (size == 0) {
            view.post(() -> drawCircularRing(view, progress, color));
            return;
        }
        Bitmap bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bmp);
        float cx = size / 2f, cy = size / 2f, stroke = dp(5), r = Math.min(cx, cy) - stroke / 2f;
        RectF oval = new RectF(cx - r, cy - r, cx + r, cy + r);
        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        p.setStyle(Paint.Style.STROKE);
        p.setStrokeWidth(stroke);
        p.setStrokeCap(Paint.Cap.ROUND);
        ValueAnimator va = ValueAnimator.ofFloat(0f, progress);
        va.setDuration(1400).setInterpolator(new AccelerateDecelerateInterpolator());
        va.addUpdateListener(a -> {
            float v = (float) a.getAnimatedValue();
            bmp.eraseColor(Color.TRANSPARENT);
            p.setColor(0xFF1C2B3A);
            canvas.drawArc(oval, 0f, 360f, false, p);
            p.setColor(color);
            canvas.drawArc(oval, -90f, (v / 100f) * 360f, false, p);
            view.setBackground(new android.graphics.drawable.BitmapDrawable(getResources(), bmp));
        });
        va.start();
    }

    private View buildInfoRow(String label, String value) {
        View row = LayoutInflater.from(this).inflate(R.layout.item_info_row, null, false);
        TextView lv = row.findViewById(R.id.infoLabel);
        TextView vv = row.findViewById(R.id.infoValue);
        TextView ev = row.findViewById(R.id.infoEmoji);
        if (ev != null) ev.setVisibility(View.GONE);
        if (lv != null) lv.setText(label);
        if (vv != null) vv.setText((value == null || value.isEmpty()) ? "—" : value);
        return row;
    }

    // ═════════════════════════════════════════
    //  INFO ROW
    // ═════════════════════════════════════════

    @SuppressWarnings("unchecked")
    private void addTextListToContainer(LinearLayout c, String key, String em, String lb) {
        try {
            List<String> items = (List<String>) ca.get(key);
            if (items == null) return;
            for (String it : items) c.addView(buildInfoRow(lb, it));
        } catch (Exception e) {
            Log.w(TAG, key, e);
        }
    }

    private void runEntranceAnimations() {
        View topBar = findViewById(R.id.topBarLayout);
        if (topBar != null) {
            topBar.setAlpha(0f);
            topBar.setTranslationY(-20f);
            topBar.animate().alpha(1f).translationY(0f).setDuration(450).setStartDelay(80)
                    .setInterpolator(new AccelerateDecelerateInterpolator()).start();
        }
        View navHeader = findViewById(R.id.cardNavHeader);
        if (navHeader != null) {
            navHeader.setAlpha(0f);
            navHeader.animate().alpha(1f).setDuration(350).setStartDelay(200).start();
        }
        View bottomNav = findViewById(R.id.bottomNavBar);
        if (bottomNav != null) {
            bottomNav.setAlpha(0f);
            bottomNav.setTranslationY(40f);
            bottomNav.animate().alpha(1f).translationY(0f).setDuration(480).setStartDelay(320)
                    .setInterpolator(new DecelerateInterpolator(2f)).start();
        }
    }

    // ═════════════════════════════════════════
    //  ENTRANCE ANIMATIONS
    // ═════════════════════════════════════════

    private void bounceView(View v) {
        v.animate().scaleX(0.88f).scaleY(0.88f).setDuration(80).withEndAction(() ->
                v.animate().scaleX(1f).scaleY(1f).setDuration(250)
                        .setInterpolator(new OvershootInterpolator(3f)).start()).start();
    }

    // ═════════════════════════════════════════
    //  MICRO-ANIMATIONS
    // ═════════════════════════════════════════

    private void pulseView(View v) {
        v.animate().scaleX(0.95f).scaleY(0.95f).setDuration(100).withEndAction(() ->
                v.animate().scaleX(1f).scaleY(1f).setDuration(100).start()).start();
    }

    private void finishWithAnimation() {
        View root = findViewById(R.id.rootLayout);
        if (root != null)
            root.animate().translationY(root.getHeight()).setDuration(350)
                    .setInterpolator(new AccelerateDecelerateInterpolator())
                    .withEndAction(this::finish).start();
        else finish();
    }

    private float gf(String... keys) {
        if (ca == null) return 0f;
        for (String k : keys) {
            try {
                Object v = ca.get(k);
                if (v == null) continue;
                float f = ((Number) v).floatValue();
                if (f != 0f) return f;
            } catch (Exception ignored) {
            }
        }
        String[] low = new String[keys.length];
        for (int i = 0; i < keys.length; i++) low[i] = keys[i].toLowerCase();
        for (String ck : ca.keySet()) {
            String kl = ck.toLowerCase();
            for (String t : low) {
                if (kl.contains(t) || t.contains(kl)) {
                    try {
                        Object v = ca.get(ck);
                        if (v == null) continue;
                        float f = ((Number) v).floatValue();
                        if (f != 0f) return f;
                    } catch (Exception ignored) {
                    }
                }
            }
        }
        return 0f;
    }

    // ═════════════════════════════════════════
    //  DATA HELPERS
    // ═════════════════════════════════════════

    private int gi(String... keys) {
        if (ca == null) return 0;
        for (String k : keys) {
            try {
                Object v = ca.get(k);
                if (v != null) {
                    int i = ((Number) v).intValue();
                    if (i != 0) return i;
                }
            } catch (Exception ignored) {
            }
        }
        return 0;
    }

    private String gs(String... keys) {
        if (ca == null) return "";
        for (String k : keys) {
            try {
                Object v = ca.get(k);
                if (v != null && !v.toString().isEmpty()) return v.toString();
            } catch (Exception ignored) {
            }
        }
        return "";
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> jsonToMap(JSONObject json) throws Exception {
        Map<String, Object> map = new HashMap<>();
        Iterator<String> keys = json.keys();
        while (keys.hasNext()) {
            String k = keys.next();
            Object v = json.get(k);
            if (v instanceof JSONObject) map.put(k, jsonToMap((JSONObject) v));
            else if (v instanceof JSONArray) map.put(k, jsonArrayToList((JSONArray) v));
            else map.put(k, v);
        }
        return map;
    }

    private List<Object> jsonArrayToList(JSONArray arr) throws Exception {
        List<Object> list = new ArrayList<>();
        for (int i = 0; i < arr.length(); i++) {
            Object v = arr.get(i);
            if (v instanceof JSONObject) list.add(jsonToMap((JSONObject) v));
            else if (v instanceof JSONArray) list.add(jsonArrayToList((JSONArray) v));
            else list.add(v);
        }
        return list;
    }

    private int dp(int v) {
        return (int) (v * getResources().getDisplayMetrics().density);
    }

    // ═════════════════════════════════════════
    //  UI HELPERS
    // ═════════════════════════════════════════

    private android.graphics.drawable.Drawable makeRoundRect(int color, int r) {
        android.graphics.drawable.GradientDrawable gd = new android.graphics.drawable.GradientDrawable();
        gd.setShape(android.graphics.drawable.GradientDrawable.RECTANGLE);
        gd.setCornerRadius(r);
        gd.setColor(color);
        return gd;
    }

    private String descFor(String k, float s) {
        switch (k) {
            case "jawline":
                return s >= 85 ? "Sharp & Defined" : s >= 70 ? "Strong" : s >= 55 ? "Moderate" : "Rounded";
            case "cheekbones":
                return s >= 90 ? "High & Prominent" : s >= 75 ? "Well Defined" : s >= 55 ? "Moderate" : "Flat";
            case "masculinity":
                return s >= 80 ? "Very Masculine" : s >= 65 ? "Masculine" : s >= 50 ? "Moderate" : "Soft";
            case "skin":
                return s >= 85 ? "Excellent" : s >= 70 ? "Smooth & Clear" : s >= 55 ? "Average" : "Needs Work";
            case "hot":
                return s >= 85 ? "Extremely Hot 🔥" : s >= 70 ? "Very Attractive" : s >= 55 ? "Attractive" : "Average";
            case "symmetry":
                return s >= 90 ? "Near Perfect" : s >= 75 ? "Well Balanced" : s >= 55 ? "Slight Asym." : "Asymmetric";
            case "ratio":
                return s >= 85 ? "Golden" : s >= 70 ? "Near Ideal" : s >= 55 ? "Average" : "Below Avg";
            case "eye":
                return s >= 85 ? "Captivating" : s >= 70 ? "Expressive" : s >= 55 ? "Well Shaped" : "Average";
            case "eyebrow":
                return s >= 85 ? "Well Arched" : s >= 70 ? "Defined" : "Average";
            case "nose":
                return s >= 80 ? "Well Proportioned" : s >= 65 ? "Balanced" : "Average";
            case "lip":
                return s >= 80 ? "Full & Defined" : s >= 65 ? "Well Shaped" : "Average";
            case "model":
                return s >= 80 ? "High Potential" : s >= 65 ? "Good Potential" : "Average";
            case "youth":
                return s >= 85 ? "Very Youthful" : s >= 70 ? "Youthful" : "Average";
            default:
                return s >= 80 ? "Excellent" : s >= 65 ? "Good" : s >= 50 ? "Average" : "Below Avg";
        }
    }

    private static class CardPage {
        String sectionTitle, sectionIcon;
        List<MetricItem> metrics = new ArrayList<>();
        List<InfoItem> infos = new ArrayList<>();

        CardPage(String icon, String title) {
            sectionIcon = icon;
            sectionTitle = title;
        }
    }

    // ════════════════════════════════════════════════════════
    //  ✦ STATIC — used by both this class and CreateShareImage
    // ════════════════════════════════════════════════════════

    private static class MetricItem {
        String emoji, label, desc;
        float score;

        MetricItem(String e, String l, float s, String d) {
            emoji = e;
            label = l;
            score = s;
            desc = d;
        }
    }

    private static class InfoItem {
        String label, value;

        InfoItem(String l, String v) {
            label = l;
            value = v;
        }
    }
}