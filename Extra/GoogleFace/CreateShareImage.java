package com.rafsan.growup099.GoogleFace;

import android.content.ClipData;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.view.LayoutInflater;
import android.view.View;
import androidx.core.content.ContextCompat;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.FileProvider;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;
import com.makeramen.roundedimageview.RoundedImageView;
import com.rafsan.growup099.R;

import java.io.File;
import java.io.FileOutputStream;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * CreateShareImage
 * ─────────────────────────────────────────────────────
 * item_analysis_card.xml inflate করে, data fill করে,
 * bitmap বানিয়ে bottom-এ subtle watermark আঁকে,
 * তারপর share intent fire করে।
 * <p>
 * Usage:
 * new CreateShareImage(activity, ca, faceBitmap, photoUrl, scanId)
 * .share(cardPage, "instagram");
 * ─────────────────────────────────────────────────────
 */
public class CreateShareImage {

    // Card render width — portrait, fits all screens
    private static final int CARD_W = 1080;
    private static final int CARD_H = 1920;
    private static final int JPEG_QUALITY = 95;

    private final AppCompatActivity activity;
    private final Map<String, Object> ca;
    private final Bitmap faceBitmap;
    private final String photoUrl;
    private final String scanId;
    private final DecimalFormat df = new DecimalFormat("#.#");
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    // ─────────────────────────────────────────
    //  Constructor
    // ─────────────────────────────────────────

    public CreateShareImage(AppCompatActivity activity,
                            Map<String, Object> comprehensiveAnalysis,
                            Bitmap faceBitmap,
                            String photoUrl,
                            String scanId) {
        this.activity = activity;
        this.ca = comprehensiveAnalysis;
        this.faceBitmap = faceBitmap;
        this.photoUrl = photoUrl;
        this.scanId = scanId;
    }

    // ─────────────────────────────────────────
    //  Public entry-point
    // ─────────────────────────────────────────

    public void share(CardPage page, String platform) {
        Toast.makeText(activity, "Generating image…", Toast.LENGTH_SHORT).show();

        if (faceBitmap != null) {
            doGenerate(page, platform, faceBitmap);
        } else if (photoUrl != null && !photoUrl.isEmpty()) {
            Glide.with(activity).asBitmap().load(photoUrl)
                    .into(new CustomTarget<Bitmap>() {
                        @Override
                        public void onResourceReady(Bitmap b, Transition<? super Bitmap> t) {
                            doGenerate(page, platform, b);
                        }

                        @Override
                        public void onLoadCleared(android.graphics.drawable.Drawable p) {
                        }
                    });
        } else {
            doGenerate(page, platform, null);
        }
    }

    // ─────────────────────────────────────────
    //  Core: inflate item_analysis_card → fill
    //        → measure/layout → draw → watermark
    //        → save → share
    // ─────────────────────────────────────────

    private void doGenerate(CardPage page, String platform, Bitmap face) {
        // UI work must stay on main thread
        try {
            float overallScore = gf("attractivenessScore", "overallScore", "overall");
            int overallColor = DetailedResultsActivity.colorFor(activity, overallScore);

            // 1. Inflate item_analysis_card (same XML the live UI uses)
            View cardView = LayoutInflater.from(activity)
                    .inflate(R.layout.item_analysis_card, null, false);

            // 2. Fill every view — mirrors populateCardContent() in DetailedResultsActivity
            fillCard(cardView, page, face, overallScore, overallColor);

            // 3. Measure + layout at fixed size
            cardView.measure(
                    View.MeasureSpec.makeMeasureSpec(CARD_W, View.MeasureSpec.EXACTLY),
                    View.MeasureSpec.makeMeasureSpec(CARD_H, View.MeasureSpec.EXACTLY));
            cardView.layout(0, 0, CARD_W, CARD_H);

            // Force all children to layout too
            forceLayout(cardView);

            // 4. Draw to Bitmap
            Bitmap bmp = Bitmap.createBitmap(CARD_W, CARD_H, Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(bmp);
            canvas.drawColor(0xFF060C18);   // same bg as activity
            cardView.draw(canvas);

            // 5. Draw score ring manually (plain View has no onDraw override)
            View ringView = cardView.findViewById(R.id.overallRingView);
            if (ringView != null) {
                drawRingOnCanvas(canvas,
                        ringView.getLeft(), ringView.getTop(),
                        ringView.getWidth(), ringView.getHeight(),
                        overallScore, overallColor);
            }

            // 6. Stamp subtle watermark at bottom
            drawWatermark(canvas, bmp.getWidth(), bmp.getHeight());

            // 7. Save off main thread
            executor.execute(() -> {
                try {
                    String stamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
                    File file = new File(activity.getCacheDir(), "growup_" + stamp + ".jpg");
                    FileOutputStream fos = new FileOutputStream(file);
                    bmp.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, fos);
                    fos.close();
                    bmp.recycle();
                    mainHandler.post(() -> fireShareIntent(file, page, platform));
                } catch (Exception e) {
                    mainHandler.post(() ->
                            Toast.makeText(activity, "Save failed: " + e.getMessage(),
                                    Toast.LENGTH_SHORT).show());
                }
            });

        } catch (Exception e) {
            Toast.makeText(activity, "Share failed: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    // ─────────────────────────────────────────
    //  Fill item_analysis_card views
    // ─────────────────────────────────────────

    private void fillCard(View card, CardPage page, Bitmap face,
                          float overallScore, int overallColor) {

        // ── Card header ──────────────────────
        setText(card, R.id.cardTitleIcon, page.sectionIcon);
        setText(card, R.id.cardTitleText, page.sectionTitle.toUpperCase(Locale.US));

        // Hide AI-report button & legacy share icon
        setGone(card, R.id.btnViewAiAnalysis);
        setGone(card, R.id.btnCardShare);

        // Hide premium overlay
        setGone(card, R.id.premiumOverlay);

        // ── Face photo ───────────────────────
        RoundedImageView heroImg = card.findViewById(R.id.heroFaceImageCard);
        if (heroImg != null && face != null) heroImg.setImageBitmap(face);

        // ── Score badge ──────────────────────
        TextView heroScore = card.findViewById(R.id.heroScoreCard);
        if (heroScore != null) {
            heroScore.setText(String.valueOf((int) overallScore));
            heroScore.setTextColor(overallColor);
        }

        // ── Rating badge ─────────────────────
        TextView heroRating = card.findViewById(R.id.heroRatingCard);
        if (heroRating != null) {
            heroRating.setText(DetailedResultsActivity.ratingOf(overallScore));
            heroRating.setTextColor(overallColor);
        }

        // ── Overview stats ───────────────────
        setText(card, R.id.ovGlobalRank, "Top " + gi("globalRanking", "ranking", "percentile") + "%");
        setText(card, R.id.ovFaceShape, gs("faceShape", "shape", "faceForm"));
        setText(card, R.id.ovAge, gi("estimatedAge", "age", "ageEstimate") + " yrs");
        setText(card, R.id.ovEthnicity, gs("primaryEthnicity", "ethnicity", "origin"));
        setText(card, R.id.ovCelebrity, gs("celebrityMatch", "celebrity", "lookalike"));
        setText(card, R.id.ovEmotion, gs("dominantEmotion", "emotion", "mood"));

        // ── Metrics grid (3 per row) ─────────
        LinearLayout metricsContainer = card.findViewById(R.id.metricsGridContainer);
        if (metricsContainer != null) {
            metricsContainer.removeAllViews();
            int cols = 3;
            for (int i = 0; i < page.metrics.size(); i += cols) {
                LinearLayout row = makeRow();
                for (int j = i; j < Math.min(i + cols, page.metrics.size()); j++) {
                    row.addView(buildMetricCell(page.metrics.get(j)));
                    if (j < Math.min(i + cols, page.metrics.size()) - 1) {
                        View gap = new View(activity);
                        gap.setLayoutParams(new LinearLayout.LayoutParams(dp(8), 1));
                        row.addView(gap);
                    }
                }
                metricsContainer.addView(row);
            }
        }

        // ── Info rows ────────────────────────
        LinearLayout infoContainer = card.findViewById(R.id.infoRowsContainer);
        if (infoContainer != null) {
            infoContainer.removeAllViews();
            for (CardPage.InfoItem info : page.infos) {
                infoContainer.addView(buildInfoRow(info.label, info.value));
            }
        }

        // ── Hide social share strip (not needed in image) ──
        View shareStrip = card.findViewById(R.id.socialShareStrip);
        if (shareStrip != null) shareStrip.setVisibility(View.GONE);

        // Hide bottom share text button
        setGone(card, R.id.btnShareCardBottom);
    }

    // ─────────────────────────────────────────
    //  Metric cell — compact, crisp for bitmap
    // ─────────────────────────────────────────

    private View buildMetricCell(CardPage.MetricItem m) {
        LinearLayout cell = new LinearLayout(activity);
        cell.setOrientation(LinearLayout.VERTICAL);
        cell.setGravity(android.view.Gravity.CENTER);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        lp.setMargins(0, 0, 0, dp(6));
        cell.setLayoutParams(lp);
        cell.setPadding(dp(6), dp(10), dp(6), dp(10));

        android.graphics.drawable.GradientDrawable bg =
                new android.graphics.drawable.GradientDrawable();
        bg.setShape(android.graphics.drawable.GradientDrawable.RECTANGLE);
        bg.setCornerRadius(dp(10));
        bg.setColor(0xFF07101F);
        bg.setStroke(1, 0xFF0D1E33);
        cell.setBackground(bg);

        int color = DetailedResultsActivity.colorFor(activity, m.score);

        // Emoji
        TextView emTv = new TextView(activity);
        emTv.setText(m.emoji);
        emTv.setTextSize(16f);
        emTv.setGravity(android.view.Gravity.CENTER);
        cell.addView(emTv);

        // Score
        TextView scTv = new TextView(activity);
        scTv.setText(String.valueOf((int) m.score));
        scTv.setTextColor(color);
        scTv.setTextSize(20f);
        scTv.setTypeface(null, Typeface.BOLD);
        scTv.setGravity(android.view.Gravity.CENTER);
        cell.addView(scTv);

        // Label
        TextView lbTv = new TextView(activity);
        lbTv.setText(m.label);
        lbTv.setTextColor(0xFF7A8FA8);
        lbTv.setTextSize(9f);
        lbTv.setGravity(android.view.Gravity.CENTER);
        lbTv.setMaxLines(1);
        lbTv.setEllipsize(android.text.TextUtils.TruncateAt.END);
        cell.addView(lbTv);

        // Desc
        if (m.desc != null && !m.desc.isEmpty()) {
            TextView deTv = new TextView(activity);
            deTv.setText(m.desc);
            deTv.setTextColor(color);
            deTv.setTextSize(8f);
            deTv.setGravity(android.view.Gravity.CENTER);
            deTv.setMaxLines(1);
            deTv.setEllipsize(android.text.TextUtils.TruncateAt.END);
            cell.addView(deTv);
        }

        return cell;
    }

    // ─────────────────────────────────────────
    //  Info row
    // ─────────────────────────────────────────

    private View buildInfoRow(String label, String value) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(android.view.Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.bottomMargin = dp(4);
        row.setLayoutParams(lp);
        row.setPadding(0, dp(3), 0, dp(3));

        // Divider dot
        View dot = new View(activity);
        android.graphics.drawable.GradientDrawable dotBg =
                new android.graphics.drawable.GradientDrawable();
        dotBg.setShape(android.graphics.drawable.GradientDrawable.OVAL);
        dotBg.setColor(0xFF1C3352);
        dot.setBackground(dotBg);
        LinearLayout.LayoutParams dotLp = new LinearLayout.LayoutParams(dp(4), dp(4));
        dotLp.setMarginEnd(dp(8));
        dotLp.gravity = android.view.Gravity.CENTER_VERTICAL;
        dot.setLayoutParams(dotLp);
        row.addView(dot);

        TextView labelTv = new TextView(activity);
        labelTv.setText(label);
        labelTv.setTextColor(0xFF2E5070);
        labelTv.setTextSize(10f);
        LinearLayout.LayoutParams llp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        llp.setMarginEnd(dp(6));
        labelTv.setLayoutParams(llp);
        row.addView(labelTv);

        // Spacer
        View spacer = new View(activity);
        spacer.setLayoutParams(new LinearLayout.LayoutParams(0, 1, 1f));
        row.addView(spacer);

        TextView valueTv = new TextView(activity);
        valueTv.setText((value == null || value.isEmpty()) ? "—" : value);
        valueTv.setTextColor(0xFFAABBCC);
        valueTv.setTextSize(10f);
        valueTv.setTypeface(null, Typeface.BOLD);
        valueTv.setMaxLines(1);
        row.addView(valueTv);

        return row;
    }

    // ─────────────────────────────────────────
    //  Draw score ring arc onto canvas
    // ─────────────────────────────────────────

    private void drawRingOnCanvas(Canvas canvas, int left, int top,
                                  int w, int h, float progress, int color) {
        if (w <= 0 || h <= 0) return;
        float cx = left + w / 2f, cy = top + h / 2f;
        float stroke = dp(5);
        float r = Math.min(w, h) / 2f - stroke / 2f - dp(1);
        RectF oval = new RectF(cx - r, cy - r, cx + r, cy + r);
        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        p.setStyle(Paint.Style.STROKE);
        p.setStrokeWidth(stroke);
        p.setStrokeCap(Paint.Cap.ROUND);
        // Track
        p.setColor(0xFF1C2B3A);
        canvas.drawArc(oval, 0f, 360f, false, p);
        // Progress
        p.setColor(color);
        canvas.drawArc(oval, -90f, (progress / 100f) * 360f, false, p);
    }

    // ─────────────────────────────────────────
    //  Subtle bottom watermark
    //  App logo (drawable) + "GrowUp AI" text
    // ─────────────────────────────────────────

    private void drawWatermark(Canvas canvas, int canvasW, int canvasH) {
        int padH = dp(18);
        int padV = dp(14);
        int logoS = dp(22);    // logo square size
        int gap = dp(8);

        // Semi-transparent background strip at bottom
        Paint bgPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        bgPaint.setColor(0xCC060C18);
        canvas.drawRect(0, canvasH - logoS - padV * 2, canvasW, canvasH, bgPaint);

        // Thin top border line for the watermark strip
        Paint linePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        linePaint.setColor(0xFF0D2540);
        linePaint.setStrokeWidth(dp(1));
        canvas.drawLine(0, canvasH - logoS - padV * 2,
                canvasW, canvasH - logoS - padV * 2, linePaint);

        // App name text
        Paint textPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        textPaint.setColor(0x55AABBCC);   // very subtle — 33% opacity
        textPaint.setTextSize(dp(13));
        textPaint.setTypeface(Typeface.DEFAULT_BOLD);
        textPaint.setLetterSpacing(0.06f);

        String watermarkText = "GrowUp AI  •  growup.ai";
        float textW = textPaint.measureText(watermarkText);

        // Draw app icon from drawable as bitmap
        try {
            android.graphics.drawable.Drawable iconDrawable =
                    androidx.core.content.ContextCompat.getDrawable(
                            activity, R.mipmap.ic_launcher_round);
            if (iconDrawable != null) {
                Bitmap iconBmp = Bitmap.createBitmap(logoS, logoS, Bitmap.Config.ARGB_8888);
                Canvas ic = new Canvas(iconBmp);
                iconDrawable.setBounds(0, 0, logoS, logoS);
                iconDrawable.setAlpha(80);   // ~31% opacity — very subtle
                iconDrawable.draw(ic);

                Paint iconPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
                iconPaint.setAlpha(80);
                int iconTop = canvasH - logoS - padV;
                canvas.drawBitmap(iconBmp, padH, iconTop, iconPaint);
                iconBmp.recycle();

                // Text vertically centered next to icon
                float textX = padH + logoS + gap;
                float textY = canvasH - padV - (logoS / 2f)
                        + ((-textPaint.ascent() - textPaint.descent()) / 2f);
                canvas.drawText(watermarkText, textX, textY, textPaint);
            } else {
                // No icon — just center the text
                float textX = (canvasW - textW) / 2f;
                float textY = canvasH - padV - dp(4);
                canvas.drawText(watermarkText, textX, textY, textPaint);
            }
        } catch (Exception e) {
            // Fallback: text only
            float textX = padH;
            float textY = canvasH - padV - dp(4);
            canvas.drawText(watermarkText, textX, textY, textPaint);
        }
    }

    // ─────────────────────────────────────────
    //  Share intent
    // ─────────────────────────────────────────

    private void fireShareIntent(File file, CardPage page, String platform) {
        Uri uri = FileProvider.getUriForFile(
                activity,
                activity.getPackageName() + ".provider",
                file);

        float score = gf("attractivenessScore", "overallScore", "overall");
        String text = "My " + page.sectionTitle + " Analysis 🔥\n"
                + "Score: " + (int) score + "/100  •  "
                + DetailedResultsActivity.ratingOf(score) + "\n"
                + "Analyzed by GrowUp AI™  🧬\n"
                + "#GrowUpAI #FaceAnalysis #AIBeauty";

        Intent si = new Intent(Intent.ACTION_SEND);
        si.setType("image/jpeg");
        si.putExtra(Intent.EXTRA_STREAM, uri);
        si.putExtra(Intent.EXTRA_TEXT, text);
        si.setClipData(ClipData.newUri(activity.getContentResolver(), "GrowUp AI", uri));
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
            activity.startActivity(si);
        } catch (android.content.ActivityNotFoundException e) {
            si.setPackage(null);
            activity.startActivity(Intent.createChooser(si, "Share via"));
        }
    }

    // ─────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────

    /**
     * Recursively force layout on all children so bounds are set before draw
     */
    private void forceLayout(View view) {
        view.forceLayout();
        if (view instanceof android.view.ViewGroup) {
            android.view.ViewGroup vg = (android.view.ViewGroup) view;
            for (int i = 0; i < vg.getChildCount(); i++) forceLayout(vg.getChildAt(i));
        }
    }

    private LinearLayout makeRow() {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.bottomMargin = dp(8);
        row.setLayoutParams(lp);
        return row;
    }

    private void setText(View root, int id, String text) {
        TextView tv = root.findViewById(id);
        if (tv != null) tv.setText(text);
    }

    private void setGone(View root, int id) {
        View v = root.findViewById(id);
        if (v != null) v.setVisibility(View.GONE);
    }

    private int dp(int v) {
        return (int) (v * activity.getResources().getDisplayMetrics().density);
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
        return 0f;
    }

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

    // ─────────────────────────────────────────
    //  Public data classes
    //  (DetailedResultsActivity passes these in)
    // ─────────────────────────────────────────

    public static class CardPage {
        public final String sectionTitle;
        public final String sectionIcon;
        public final List<MetricItem> metrics;
        public final List<InfoItem> infos;

        public CardPage(String icon, String title,
                        List<MetricItem> metrics, List<InfoItem> infos) {
            this.sectionIcon = icon;
            this.sectionTitle = title;
            this.metrics = metrics != null ? metrics : new ArrayList<>();
            this.infos = infos != null ? infos : new ArrayList<>();
        }

        public static class MetricItem {
            public final String emoji, label, desc;
            public final float score;

            public MetricItem(String emoji, String label, float score, String desc) {
                this.emoji = emoji;
                this.label = label;
                this.score = score;
                this.desc = desc;
            }
        }

        public static class InfoItem {
            public final String label, value;

            public InfoItem(String label, String value) {
                this.label = label;
                this.value = value;
            }
        }
    }
}