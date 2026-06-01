package com.rafsan.growup099.GoogleFace;

import androidx.core.content.ContextCompat;

import android.animation.ValueAnimator;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.bumptech.glide.Glide;
import com.google.android.material.progressindicator.CircularProgressIndicator;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.rafsan.growup099.AiOnBording.AIChatOnboardingActivity;
import com.rafsan.growup099.LocalData.LocalScanManager;
import com.rafsan.growup099.R;
import com.rafsan.growup099.TaskDetails.CreateSevenDaysTaskActivity;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.TimeUnit;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

public class FaceResultOverviewActivity extends AppCompatActivity {

    private static final String TAG = "FaceResultOverview";

    private int COLOR_ACCENT, COLOR_GOLD, COLOR_TRACK, COLOR_TEXT_MID, COLOR_PURPLE, COLOR_TEAL;

    public static final String EXTRA_SCAN_ID    = "scanId";
    public static final String EXTRA_DAY_NUMBER = "dayNumber";

    private static final String GEMINI_API_KEY  = "AIzaSyDP1BDibH12cocwDUqI5lg-IKrXl0HF_dg";
    private static final String GEMINI_ENDPOINT =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + GEMINI_API_KEY;

    private static final String[] DAY_LABELS = {"M", "T", "W", "T", "F", "S", "S"};

    private String scanId;
    private int    dayNumber;
    private Map<String, Object> ca;
    private int cachedOverall   = 0;
    private int cachedPotential = 0;
    private int weakestScore    = 0;
    private String weakestLabel = "Skin";

    private LocalScanManager localScanManager;
    private FirebaseManager   firebaseManager;
    private FirebaseFirestore db;
    private OkHttpClient      httpClient;

    // ── Top bar ──────────────────────────────────────────────
    private View     btnBack;
    private TextView tvDayBadge, tvAvgScore;

    // ── Face photo ───────────────────────────────────────────
    private ImageView ivFacePhoto;

    // ── Urgency banner ───────────────────────────────────────
    private View cardUrgencyBanner;
    private TextView tvUrgencyTitle;

    // ── Overall ring ─────────────────────────────────────────
    private CircularProgressIndicator overallProgress;
    private TextView tvOverallScore, tvGradeLabel, tvCurrentLabel;

    // ── Potential ring ───────────────────────────────────────
    private CircularProgressIndicator potentialProgress;
    private TextView tvPotentialScore, tvPotentialGap, tvPotentialLabel;

    // ── Mini stat cards ───────────────────────────────────────
    private TextView tvMiniCurrentScore, tvMiniWeekChange;
    private TextView tvMiniPotentialScore, tvMiniGapPoints;

    // ── Metric cards ─────────────────────────────────────────
    private View cardQuality, cardSymmetry, cardSmile, cardEyes, cardJawline, cardNose;

    private CircularProgressIndicator progressQuality;
    private TextView valueQuality, labelQuality;

    private CircularProgressIndicator progressSymmetry;
    private TextView valueSymmetry, labelSymmetry;

    private CircularProgressIndicator progressSmile;
    private TextView valueSmile, labelSmile;

    private CircularProgressIndicator progressEyes;
    private TextView valueEyes, labelEyes;

    private CircularProgressIndicator progressJawline;
    private TextView valueJawline, labelJawline;

    private CircularProgressIndicator progressNose;
    private TextView valueNose, labelNose;

    // ── Personalised nudge CTA ───────────────────────────────
    private View cardNudgeCta;
    private TextView tvNudgeLabel, tvNudgeTitle, tvNudgeSub, btnNudgeCta;

    // ── Streak CTA ───────────────────────────────────────────
    private View cardStreakCta;
    private TextView tvStreakLabel, btnStreakCta;
    private LinearLayout llStreakDays;

    // ── Social proof CTA ─────────────────────────────────────
    private View cardSocialCta;
    private TextView tvRankPercentile;

    // ── AI insight ───────────────────────────────────────────
    private TextView tvGeminiInsight, geminiDoneIcon;
    private LinearLayout llTipsBullets;
    private CircularProgressIndicator geminiLoadingProgress;
    private View btnStartJourney;

    // ── Bottom buttons ───────────────────────────────────────
    private TextView  btnViewDetails;
    private CardView  btnCreateTask;
    private TextView  tvBtnGapBadge, tvBtnCreateTaskText;

    // ─────────────────────────────────────────────────────────
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_face_result_overview);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets sys = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(sys.left, sys.top, sys.right, sys.bottom);
            return insets;
        });

        scanId           = getIntent().getStringExtra(EXTRA_SCAN_ID);
        dayNumber        = getIntent().getIntExtra(EXTRA_DAY_NUMBER, 1);
        localScanManager = new LocalScanManager(this);
        firebaseManager  = new FirebaseManager();
        db               = FirebaseFirestore.getInstance();
        httpClient       = new OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .build();

        initColors();
        bindViews();
        new Handler(Looper.getMainLooper()).postDelayed(this::loadData, 300);
    }

    private void initColors() {
        COLOR_ACCENT   = ContextCompat.getColor(this, R.color.accent_glow);
        COLOR_GOLD     = ContextCompat.getColor(this, R.color.warning);
        COLOR_TRACK    = ContextCompat.getColor(this, R.color.outline_variant);
        COLOR_TEXT_MID = ContextCompat.getColor(this, R.color.on_surface_variant);
        COLOR_PURPLE   = COLOR_ACCENT;
        COLOR_TEAL     = ContextCompat.getColor(this, R.color.success);
    }

    // ── Bind every view ───────────────────────────────────────
    private void bindViews() {
        btnBack    = findViewById(R.id.btnBack);
        tvDayBadge = findViewById(R.id.tvDayBadge);
        tvAvgScore = findViewById(R.id.tvAvgScore);

        ivFacePhoto = findViewById(R.id.ivFacePhoto);

        cardUrgencyBanner = findViewById(0 /* R.id.cardUrgencyBanner */);
        tvUrgencyTitle    = findViewById(0 /* R.id.tvUrgencyTitle */);

        overallProgress = findViewById(R.id.overallProgress);
        tvOverallScore  = findViewById(R.id.tvOverallScore);
        tvGradeLabel    = findViewById(R.id.tvGradeLabel);
        tvCurrentLabel  = findViewById(0 /* R.id.tvCurrentLabel */);

        potentialProgress = findViewById(R.id.potentialProgress);
        tvPotentialScore  = findViewById(R.id.tvPotentialScore);
        tvPotentialGap    = findViewById(R.id.tvPotentialGap);
        tvPotentialLabel  = findViewById(0 /* R.id.tvPotentialLabel */);

        tvMiniCurrentScore   = findViewById(0 /* R.id.tvMiniCurrentScore */);
        tvMiniWeekChange     = findViewById(0 /* R.id.tvMiniWeekChange */);
        tvMiniPotentialScore = findViewById(0 /* R.id.tvMiniPotentialScore */);
        tvMiniGapPoints      = findViewById(0 /* R.id.tvMiniGapPoints */);

        cardQuality  = findViewById(R.id.cardSkin);
        cardSymmetry = findViewById(R.id.cardSymmetry);
        cardSmile    = findViewById(0 /* R.id.cardSmile */);
        cardEyes     = findViewById(R.id.cardEyes);
        cardJawline  = findViewById(R.id.cardJawline);
        cardNose     = findViewById(0 /* R.id.cardNose */);

        if (cardQuality != null) {
            progressQuality = cardQuality.findViewById(R.id.progressMetric);
            valueQuality    = cardQuality.findViewById(R.id.valueMetric);
            labelQuality    = cardQuality.findViewById(R.id.labelMetric);
        }
        if (cardSymmetry != null) {
            progressSymmetry = cardSymmetry.findViewById(R.id.progressMetric);
            valueSymmetry    = cardSymmetry.findViewById(R.id.valueMetric);
            labelSymmetry    = cardSymmetry.findViewById(R.id.labelMetric);
        }
        if (cardSmile != null) {
            progressSmile = cardSmile.findViewById(R.id.progressMetric);
            valueSmile    = cardSmile.findViewById(R.id.valueMetric);
            labelSmile    = cardSmile.findViewById(R.id.labelMetric);
        }
        if (cardEyes != null) {
            progressEyes = cardEyes.findViewById(R.id.progressMetric);
            valueEyes    = cardEyes.findViewById(R.id.valueMetric);
            labelEyes    = cardEyes.findViewById(R.id.labelMetric);
        }
        if (cardJawline != null) {
            progressJawline = cardJawline.findViewById(R.id.progressMetric);
            valueJawline    = cardJawline.findViewById(R.id.valueMetric);
            labelJawline    = cardJawline.findViewById(R.id.labelMetric);
        }
        if (cardNose != null) {
            progressNose = cardNose.findViewById(R.id.progressMetric);
            valueNose    = cardNose.findViewById(R.id.valueMetric);
            labelNose    = cardNose.findViewById(R.id.labelMetric);
        }

        cardNudgeCta  = findViewById(0 /* R.id.cardNudgeCta */);
        tvNudgeLabel  = findViewById(0 /* R.id.tvNudgeLabel */);
        tvNudgeTitle  = findViewById(0 /* R.id.tvNudgeTitle */);
        tvNudgeSub    = findViewById(0 /* R.id.tvNudgeSub */);
        btnNudgeCta   = findViewById(0 /* R.id.btnNudgeCta */);

        cardStreakCta = findViewById(0 /* R.id.cardStreakCta */);
        tvStreakLabel = findViewById(0 /* R.id.tvStreakLabel */);
        btnStreakCta  = findViewById(0 /* R.id.btnStreakCta */);
        llStreakDays  = findViewById(0 /* R.id.llStreakDays */);

        cardSocialCta     = findViewById(0 /* R.id.cardSocialCta */);
        tvRankPercentile  = findViewById(0 /* R.id.tvRankPercentile */);

        tvGeminiInsight       = findViewById(R.id.tvGeminiInsight);
        geminiDoneIcon        = findViewById(0 /* R.id.geminiDoneIcon */);
        llTipsBullets         = findViewById(R.id.llTipsBullets);
        geminiLoadingProgress = findViewById(0 /* R.id.geminiLoadingProgress */);

        btnViewDetails      = findViewById(R.id.btnViewDetails);
        btnCreateTask       = findViewById(R.id.btnCreateTask);
        tvBtnGapBadge       = findViewById(0 /* R.id.tvBtnGapBadge */);
        tvBtnCreateTaskText = findViewById(0 /* R.id.tvBtnCreateTaskText */);
        btnStartJourney     = findViewById(R.id.btnStartJourney);

        // Click listeners
        if (btnBack        != null) btnBack.setOnClickListener(v -> finish());
        if (btnViewDetails != null) btnViewDetails.setOnClickListener(v -> {
            Intent i = new Intent(this, DetailedResultsActivity.class);
            i.putExtra("scanId", scanId);
            startActivity(i);
        });
        if (btnCreateTask   != null) btnCreateTask.setOnClickListener(v -> checkAiProfileAndNavigate());
        if (btnNudgeCta     != null) btnNudgeCta.setOnClickListener(v -> checkAiProfileAndNavigate());
        if (btnStreakCta    != null) btnStreakCta.setOnClickListener(v -> checkAiProfileAndNavigate());
        if (btnStartJourney != null) btnStartJourney.setOnClickListener(v -> checkAiProfileAndNavigate());

        // Hide initially
        View[] animViews = {
                cardQuality, cardSymmetry, cardSmile, cardEyes, cardJawline, cardNose,
                btnViewDetails, btnCreateTask, cardUrgencyBanner,
                cardNudgeCta, cardStreakCta, cardSocialCta
        };
        for (View v : animViews) {
            if (v != null) { v.setAlpha(0f); v.setTranslationY(30f); }
        }
    }

    // ── Data loading ──────────────────────────────────────────
    private void loadData() {
        if (scanId == null || scanId.isEmpty()) { showErrorUI("No scan ID"); return; }
        JSONObject local = localScanManager.loadLocalScan(scanId);
        if (local != null) {
            try { processData(jsonToMap(local)); return; } catch (Exception ignored) {}
        }
        firebaseManager.loadScanById(scanId, new FirebaseManager.ScanLoadCallback() {
            @Override public void onSuccess(Map<String, Object> data) { runOnUiThread(() -> processData(data)); }
            @Override public void onFailure(String err)               { runOnUiThread(() -> showErrorUI(err)); }
        });
    }

    @SuppressWarnings("unchecked")
    private void processData(Map<String, Object> data) {
        try {
            ca = (Map<String, Object>) data.get("comprehensiveAnalysis");
            if (ca == null) { showErrorUI("Data missing"); return; }

            String path = (String) data.get("photoPath");
            String url  = (String) data.get("photoUrl");
            Object src  = (path != null && new File(path).exists()) ? new File(path) : url;
            if (src != null) {
                Glide.with(this).asBitmap().load(src).circleCrop()
                        .into(new com.bumptech.glide.request.target.CustomTarget<Bitmap>() {
                            @Override public void onResourceReady(@NonNull Bitmap b,
                                                                  com.bumptech.glide.request.transition.Transition<? super Bitmap> t) {
                                ivFacePhoto.setImageBitmap(b);
                            }
                            @Override public void onLoadCleared(android.graphics.drawable.Drawable p) {}
                        });
            }
            buildUI();
        } catch (Exception e) { showErrorUI(e.getMessage()); }
    }

    // ── Build full UI ─────────────────────────────────────────
    private void buildUI() {

        // Staggered entrance animations
        animateEntrance(cardUrgencyBanner, 200);

        View[] metricCards = {cardQuality, cardSymmetry, cardSmile, cardEyes, cardJawline, cardNose};
        for (int i = 0; i < metricCards.length; i++) animateEntrance(metricCards[i], 400 + i * 80);

        animateEntrance(btnViewDetails, 700);
        animateEntrance(btnCreateTask, 900);
        animateEntrance(cardNudgeCta, 1100);
        animateEntrance(cardStreakCta, 1250);
        animateEntrance(cardSocialCta, 1400);

        // Read metric scores
        int q  = (int) getData("skinQuality",     "skinSmooth",   "skinScore");
        int s  = (int) getData("overallSymmetry",  "symmetry",     "symScore");
        int sm = (int) getData("smileIntensity",   "smile",        "smileScore");
        int e  = (int) getData("eyeSize",          "eyeSizeScore", "eyes");
        int j  = (int) getData("jawlineSharpness", "jawlineScore", "jawline");
        int n  = (int) getData("noseTipShape",     "tipShape",     "noseTip");

        // Overall score
        float ov = getData("attractivenessScore", "overallScore", "overall");
        if (ov == 0f) ov = (q + s + sm + e + j + n) / 6f;
        cachedOverall = Math.round(ov);

        // Find weakest metric for personalised nudge
        int[] scores = {q, s, sm, e, j, n};
        String[] names = {"Skin", "Symmetry", "Smile", "Eyes", "Jawline", "Nose"};
        weakestScore = scores[0]; weakestLabel = names[0];
        for (int i = 1; i < scores.length; i++) {
            if (scores[i] < weakestScore) { weakestScore = scores[i]; weakestLabel = names[i]; }
        }

        // Header
        if (tvDayBadge != null) tvDayBadge.setText("Day " + dayNumber);
        if (tvAvgScore  != null) tvAvgScore.setText("Avg: " + ((q + s + sm + e + j + n) / 6) + "%");

        // Overall ring
        int colorUsed = COLOR_PURPLE;
        animateCircular(overallProgress, tvOverallScore, cachedOverall, 1500, colorUsed, false);
        if (tvGradeLabel   != null) { tvGradeLabel.setText(DetailedResultsActivity.ratingOf(cachedOverall)); tvGradeLabel.setTextColor(colorUsed); }
        if (tvCurrentLabel != null) tvCurrentLabel.setText(cachedOverall + "%");

        // Potential ring
        int gap = 16 + new Random().nextInt(10);
        cachedPotential = Math.min(98, cachedOverall + gap);
        animateCircular(potentialProgress, tvPotentialScore, cachedPotential, 1800, COLOR_GOLD, true);
        if (tvPotentialGap   != null) tvPotentialGap.setText("+" + (cachedPotential - cachedOverall) + "% possible!");
        if (tvPotentialLabel != null) tvPotentialLabel.setText(cachedPotential + "%");
        if (tvBtnGapBadge    != null) tvBtnGapBadge.setText("+" + (cachedPotential - cachedOverall) + "%");

        // Mini stat cards
        if (tvMiniCurrentScore   != null) tvMiniCurrentScore.setText(cachedOverall + "%");
        if (tvMiniPotentialScore != null) tvMiniPotentialScore.setText(cachedPotential + "%");
        if (tvMiniGapPoints      != null) tvMiniGapPoints.setText((cachedPotential - cachedOverall) + " pts to go");
        if (tvMiniWeekChange     != null) {
            tvMiniWeekChange.setText(dayNumber > 1 ? "+4% this week" : "First scan today");
        }

        // Metric labels
        if (labelQuality  != null) labelQuality.setText("Skin");
        if (labelSymmetry != null) labelSymmetry.setText("Symmetry");
        if (labelSmile    != null) labelSmile.setText("Smile");
        if (labelEyes     != null) labelEyes.setText("Eyes");
        if (labelJawline  != null) labelJawline.setText("Jaw");
        if (labelNose     != null) labelNose.setText("Nose");

        // Animate each metric ring
        delayRing(progressQuality,  valueQuality,  q,  1000);
        delayRing(progressSymmetry, valueSymmetry, s,  1100);
        delayRing(progressSmile,    valueSmile,    sm, 1200);
        delayRing(progressEyes,     valueEyes,     e,  1300);
        delayRing(progressJawline,  valueJawline,  j,  1400);
        delayRing(progressNose,     valueNose,     n,  1500);

        // Urgency banner
        if (tvUrgencyTitle != null)
            tvUrgencyTitle.setText("You're " + (cachedPotential - cachedOverall) + " pts from your best look");

        // Personalised nudge CTA
        buildNudgeCta();

        // Streak CTA
        buildStreakCta();

        // Social / rank CTA
        buildSocialCta();

        fetchAi(q, s, sm, e, j, n);
    }

    // ── Personalised nudge based on weakest metric ────────────
    private void buildNudgeCta() {
        if (cardNudgeCta == null) return;
        String emoji = "💧";
        String routine = "skin hydration routine";
        if (weakestLabel.equals("Symmetry"))  { emoji = "🎯"; routine = "face symmetry exercises"; }
        else if (weakestLabel.equals("Smile")) { emoji = "😁"; routine = "smile training routine"; }
        else if (weakestLabel.equals("Eyes"))  { emoji = "👁"; routine = "eye care routine"; }
        else if (weakestLabel.equals("Jawline")) { emoji = "💪"; routine = "jawline sculpting plan"; }
        else if (weakestLabel.equals("Nose"))  { emoji = "✨"; routine = "contouring tips"; }

        int improvePts = Math.min(15, 100 - weakestScore);
        if (tvNudgeLabel != null) tvNudgeLabel.setText(emoji + "  Biggest opportunity");
        if (tvNudgeTitle != null) tvNudgeTitle.setText("Your " + weakestLabel.toLowerCase() + " can improve the most");
        if (tvNudgeSub   != null)
            tvNudgeSub.setText("A targeted " + routine + " can add +" + improvePts + "% in 14 days. Get your personalised plan.");
        if (btnNudgeCta  != null) btnNudgeCta.setText("Get my " + weakestLabel.toLowerCase() + " routine →");
    }

    // ── Streak tracker ────────────────────────────────────────
    private void buildStreakCta() {
        if (cardStreakCta == null || llStreakDays == null) return;
        if (tvStreakLabel != null) tvStreakLabel.setText("Day " + dayNumber + " streak");

        llStreakDays.removeAllViews();
        int dpUnit = (int) (getResources().getDisplayMetrics().density);

        for (int i = 0; i < 7; i++) {
            TextView day = new TextView(this);
            day.setText(DAY_LABELS[i]);
            day.setGravity(android.view.Gravity.CENTER);
            day.setTextSize(10f);
            //day.setTextStyle(android.graphics.Typeface.BOLD);

            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0,
                    28 * dpUnit, 1f);
            lp.setMarginEnd(i < 6 ? 4 * dpUnit : 0);
            day.setLayoutParams(lp);
            day.setPadding(0, 0, 0, 0);

            if (i < dayNumber) {
                // completed day
                day.setBackgroundResource(R.drawable.streak_day_done_bg);
                day.setTextColor(COLOR_TEAL);
            } else if (i == dayNumber) {
                // today
                day.setBackgroundResource(R.drawable.streak_day_today_bg);
                day.setTextColor(COLOR_GOLD);
            } else {
                // future
                day.setBackgroundResource(R.drawable.streak_day_future_bg);
                day.setTextColor(0xFF2A4A6A);
            }
            llStreakDays.addView(day);
        }
    }

    // ── Social proof / rank CTA ───────────────────────────────
    private void buildSocialCta() {
        if (tvRankPercentile == null) return;
        // Simple percentile based on overall score
        int percentile = Math.max(5, 100 - cachedOverall);
        tvRankPercentile.setText("Top\n" + percentile + "%");
    }

    // ── Animate a card entrance ───────────────────────────────
    private void animateEntrance(View v, long delay) {
        if (v == null) return;
        v.animate().alpha(1f).translationY(0f).setDuration(500).setStartDelay(delay).start();
    }

    // ── Delay then animate a metric ring ─────────────────────
    private void delayRing(CircularProgressIndicator p, TextView label, int target, int delayMs) {
        new Handler(Looper.getMainLooper()).postDelayed(() ->
                        animateCircular(p, label, target, 1000, COLOR_PURPLE, false),
                delayMs);
    }

    // ── Animate circular progress ─────────────────────────────
    private void animateCircular(CircularProgressIndicator p, TextView label,
                                 int target, int duration, int color, boolean gold) {
        if (p == null || label == null) return;
        p.setIndicatorColor(color);
        p.setTrackColor(COLOR_TRACK);
        ValueAnimator anim = ValueAnimator.ofInt(0, target);
        anim.setDuration(duration);
        anim.setInterpolator(new AccelerateDecelerateInterpolator());
        anim.addUpdateListener(v -> {
            int val = (int) v.getAnimatedValue();
            p.setProgressCompat(val, true);
            label.setText(val + "%");
            label.setTextColor(gold ? COLOR_GOLD : 0xFFFFFFFF);
        });
        anim.start();
    }

    // ── Gemini AI fetch ───────────────────────────────────────
    private void fetchAi(int q, int s, int sm, int e, int j, int n) {
        if (GEMINI_API_KEY.contains("YOUR_GEMINI")) {
            renderAi("Looking great! Focus on your " + weakestLabel.toLowerCase()
                    + " to unlock your " + cachedPotential + "% potential.");
            return;
        }
        String prompt = "Face score " + cachedOverall + "%. "
                + "Skin:" + q + " Symmetry:" + s + " Smile:" + sm
                + " Eyes:" + e + " Jaw:" + j + " Nose:" + n + ". "
                + "Weakest: " + weakestLabel + " at " + weakestScore + "%. "
                + "Give 3 actionable improvement tips starting with *. Under 150 words. Be encouraging.";
        String body = "{\"contents\":[{\"parts\":[{\"text\":" + JSONObject.quote(prompt) + "}]}]}";
        Request req = new Request.Builder()
                .url(GEMINI_ENDPOINT)
                .post(RequestBody.create(body, MediaType.parse("application/json")))
                .build();
        httpClient.newCall(req).enqueue(new Callback() {
            @Override public void onFailure(@NonNull Call c, @NonNull IOException ex) {
                runOnUiThread(() -> renderAi("Connection issue. Try again later."));
            }
            @Override public void onResponse(@NonNull Call c, @NonNull Response res) throws IOException {
                try {
                    String text = new JSONObject(res.body().string())
                            .getJSONArray("candidates").getJSONObject(0)
                            .getJSONObject("content").getJSONArray("parts")
                            .getJSONObject(0).getString("text");
                    runOnUiThread(() -> renderAi(text));
                } catch (Exception ex) {
                    runOnUiThread(() -> renderAi("Analysis complete."));
                }
            }
        });
    }

    // ── Render AI insight ─────────────────────────────────────
    private void renderAi(String raw) {
        if (geminiLoadingProgress != null) geminiLoadingProgress.setVisibility(View.GONE);
        if (geminiDoneIcon        != null) geminiDoneIcon.setVisibility(View.VISIBLE);

        String[] pts = raw.split("\\*");
        if (tvGeminiInsight != null) {
            tvGeminiInsight.setText(pts[0].trim());
            tvGeminiInsight.setAlpha(1f);
        }
        if (pts.length > 1 && llTipsBullets != null) {
            llTipsBullets.setVisibility(View.VISIBLE);
            llTipsBullets.removeAllViews();
            for (int i = 1; i < pts.length; i++) {
                String tip = pts[i].trim();
                if (tip.isEmpty()) continue;
                TextView tv = new TextView(this);
                tv.setText("• " + tip);
                tv.setTextColor(COLOR_TEXT_MID);
                tv.setTextSize(13f);
                tv.setBackgroundResource(R.drawable.chip_bg_dark);
                tv.setPadding(30, 20, 30, 20);
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT);
                lp.setMargins(0, 8, 0, 0);
                tv.setLayoutParams(lp);
                llTipsBullets.addView(tv);
            }
        }
    }

    // ── Navigate based on AI profile ──────────────────────────
    private void checkAiProfileAndNavigate() {
        FirebaseUser u = FirebaseAuth.getInstance().getCurrentUser();
        if (u == null) return;
        if (tvBtnCreateTaskText != null) tvBtnCreateTaskText.setText("Checking...");
        db.collection("users").document(u.getUid())
                .collection("aiProfile").limit(1).get()
                .addOnSuccessListener(snap -> {
                    if (tvBtnCreateTaskText != null) tvBtnCreateTaskText.setText("Create Task Journey");
                    boolean hasProfile = snap != null && !snap.isEmpty();
                    Intent i = hasProfile
                            ? new Intent(this, CreateSevenDaysTaskActivity.class)
                            : new Intent(this, AIChatOnboardingActivity.class);
                    if (!hasProfile) {
                        i.putExtra("fromScan",  true);
                        i.putExtra("scanId",    scanId);
                        i.putExtra("dayNumber", dayNumber);
                    }
                    startActivity(i);
                })
                .addOnFailureListener(ex -> {
                    if (tvBtnCreateTaskText != null) tvBtnCreateTaskText.setText("Create Task Journey");
                });
    }

    // ── Error state ───────────────────────────────────────────
    private void showErrorUI(String reason) {
        if (tvGradeLabel          != null) tvGradeLabel.setText("N/A");
        if (tvGeminiInsight       != null) tvGeminiInsight.setText("Failed to load: " + reason);
        if (geminiLoadingProgress != null) geminiLoadingProgress.setVisibility(View.GONE);
    }

    // ── Safe multi-key data getter ────────────────────────────
    private float getData(String... keys) {
        if (ca == null) return 0f;
        for (String k : keys) {
            Object v = ca.get(k);
            if (v instanceof Number) return ((Number) v).floatValue();
        }
        return 0f;
    }

    // ── JSON → Map ────────────────────────────────────────────
    @SuppressWarnings("unchecked")
    private Map<String, Object> jsonToMap(JSONObject j) throws Exception {
        Map<String, Object> m = new HashMap<>();
        Iterator<String> it = j.keys();
        while (it.hasNext()) {
            String k = it.next(); Object v = j.get(k);
            if      (v instanceof JSONObject) v = jsonToMap((JSONObject) v);
            else if (v instanceof JSONArray)  v = jsonArrayToList((JSONArray) v);
            m.put(k, v);
        }
        return m;
    }

    private List<Object> jsonArrayToList(JSONArray a) throws Exception {
        List<Object> l = new ArrayList<>();
        for (int i = 0; i < a.length(); i++) {
            Object v = a.get(i);
            if      (v instanceof JSONObject) v = jsonToMap((JSONObject) v);
            else if (v instanceof JSONArray)  v = jsonArrayToList((JSONArray) v);
            l.add(v);
        }
        return l;
    }
}