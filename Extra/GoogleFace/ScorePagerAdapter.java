/*
package com.rafsan.growup099.GoogleFace;

import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.content.res.ColorStateList;
import android.graphics.Bitmap;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.rafsan.growup099.R;

import java.text.DecimalFormat;
import java.util.List;

*/
/**
 * ScorePagerAdapter — 5 premium swipeable pages.
 * <p>
 * Page 0 — Overview
 * Hero card (big score + ranking + category)
 * + Model Potential · Jawline · Cheekbones · Masculinity · Skin Quality · Hot Score
 * <p>
 * Page 1 — Symmetry & Proportions
 * 5× Symmetry scores + Golden Ratio + Harmony + Face L:W
 * + Thirds / Fifths + Model Potential + Youthfulness + Celebrity Match
 * <p>
 * Page 2 — Face Shape & Eyes
 * Face Shape / Score + Angles (3) + Eye Size/Shape/Sym + Brow (2) + Eye Spacing + Eye Color
 * <p>
 * Page 3 — Nose, Lips & Beauty
 * Nose 6× + Lips 6× + Beauty 3×
 * <p>
 * Page 4 — Skin, Age & Origin
 * Skin 4× + Scan Quality 4× + Age 3× + Ethnicity + Breakdown
 * + Unique Features + Strengths + Suggestions
 *//*

public class ScorePagerAdapter extends RecyclerView.Adapter<ScorePagerAdapter.VH> {

    // ── Color palette ─────────────────────────────────────────────────────
    public static final int C_EXCELLENT = 0xFF00E676;  // green  ≥80
    public static final int C_GOOD      = 0xFF00BFFF;  // cyan   ≥60
    public static final int C_AVERAGE   = 0xFFFFAB40;  // amber  ≥40
    public static final int C_POOR      = 0xFFFF5252;  // red    <40

    private static final DecimalFormat DF = new DecimalFormat("#.#");

    // ── Data models ───────────────────────────────────────────────────────

    public static class Metric {
        public final String emoji;
        public final String label;
        public final float  score;   // -1 for info-only
        public final String value;   // used when score == -1
        public final String desc;
        public final boolean isHero;

        */
/**
 * Score metric
 *//*

        public Metric(String emoji, String label, float score, String desc) {
            this.emoji  = emoji; this.label = label; this.score = score;
            this.desc   = desc;  this.value = null;  this.isHero = false;
        }

        */
/**
 * Info (text-only) metric
 *//*

        public Metric(String emoji, String label, String value, String desc) {
            this.emoji  = emoji; this.label = label; this.score = -1f;
            this.desc   = desc;  this.value = value; this.isHero = false;
        }

        */
/** Hero card *//*

        public Metric(String emoji, String label, float score, String desc, boolean isHero) {
            this.emoji  = emoji; this.label = label; this.score = score;
            this.desc   = desc;  this.value = null;  this.isHero = isHero;
        }
    }

    public static class ScorePage {
        public final String        title;
        public final String        subtitle;
        public final List<Metric>  metrics;

        public ScorePage(String title, String subtitle, List<Metric> metrics) {
            this.title    = title;
            this.subtitle = subtitle;
            this.metrics  = metrics;
        }
    }

    // ── Share callback ────────────────────────────────────────────────────

    public interface ShareCardCallback {
        void onShare(ScorePage page, Bitmap faceBitmap);
    }

    // ── Fields ────────────────────────────────────────────────────────────

    private final List<ScorePage>    pages;
    private final Bitmap             faceBitmap;
    private final String             photoUrl;
    private final ShareCardCallback  shareCallback;

    public ScorePagerAdapter(List<ScorePage> pages,
                             Bitmap faceBitmap,
                             String photoUrl,
                             ShareCardCallback shareCallback) {
        this.pages         = pages;
        this.faceBitmap    = faceBitmap;
        this.photoUrl      = photoUrl;
        this.shareCallback = shareCallback;
    }

    // ── RecyclerView.Adapter ──────────────────────────────────────────────

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_score_page, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        ScorePage page = pages.get(position);

        // Face photo
        if (faceBitmap != null) {
            h.faceImage.setImageBitmap(faceBitmap);
        } else if (photoUrl != null && !photoUrl.isEmpty()) {
            Glide.with(h.faceImage.getContext())
                    .load(photoUrl).circleCrop().into(h.faceImage);
        }

        h.title.setText(page.title);
        h.subtitle.setText(page.subtitle);

        h.metricsContainer.removeAllViews();
        for (int i = 0; i < page.metrics.size(); i++) {
            Metric m = page.metrics.get(i);
            if (m.isHero) addHeroRow(h.metricsContainer, m);
            else          addMetricRow(h.metricsContainer, m, position, i);
        }

        h.shareBtn.setOnClickListener(v -> {
            if (shareCallback != null) shareCallback.onShare(page, faceBitmap);
        });
    }

    @Override
    public int getItemCount() { return pages != null ? pages.size() : 0; }

    // ── Hero card ─────────────────────────────────────────────────────────

    private void addHeroRow(LinearLayout container, Metric m) {
        View row = LayoutInflater.from(container.getContext())
                .inflate(R.layout.item_hero_score_card, container, false);

        TextView  scoreTv = row.findViewById(R.id.heroScore);
        TextView  ratingTv = row.findViewById(R.id.heroRating);
        ProgressBar pb     = row.findViewById(R.id.heroProgress);
        // rankTv / catTv are set externally by DetailedResultsActivity

        int color = colorFor(m.score);
        if (scoreTv != null) {
            scoreTv.setTextColor(color);
            ValueAnimator va = ValueAnimator.ofFloat(0f, m.score);
            va.setDuration(1800);
            va.setInterpolator(new AccelerateDecelerateInterpolator());
            va.addUpdateListener(a -> scoreTv.setText(DF.format((float) a.getAnimatedValue())));
            va.start();
        }
        if (ratingTv != null) ratingTv.setText(m.desc);
        if (pb != null) {
            pb.setMax(100);
            pb.setProgressTintList(ColorStateList.valueOf(color));
            pb.setProgressBackgroundTintList(ColorStateList.valueOf(0xFF0D1B2E));
            ObjectAnimator anim = ObjectAnimator.ofInt(pb, "progress", 0, (int) m.score);
            anim.setDuration(1800);
            anim.setInterpolator(new AccelerateDecelerateInterpolator());
            anim.start();
        }

        // Update heroScoreLabel if present
        TextView labelTv = row.findViewById(R.id.heroScoreLabel);
        if (labelTv != null) labelTv.setText((int) m.score + " / 100");

        container.addView(row);
    }

    // ── Normal metric row ─────────────────────────────────────────────────

    private void addMetricRow(LinearLayout container, Metric m, int pagePos, int rowIdx) {
        View row = LayoutInflater.from(container.getContext())
                .inflate(R.layout.item_metric_row, container, false);

        TextView    emojiTv = row.findViewById(R.id.metricEmoji);
        TextView    labelTv = row.findViewById(R.id.metricLabel);
        TextView    scoreTv = row.findViewById(R.id.metricScore);
        ProgressBar pb      = row.findViewById(R.id.metricProgress);
        TextView    descTv  = row.findViewById(R.id.metricDesc);
        View        strip   = row.findViewById(R.id.colorIndicator);

        if (emojiTv != null) emojiTv.setText(m.emoji);
        if (labelTv != null) labelTv.setText(m.label);
        if (descTv  != null) descTv.setText(m.desc);

        if (m.score >= 0) {
            // ── Scored metric ──────────────────────────────────────────
            int color = colorFor(m.score);
            if (strip   != null) strip.setBackgroundColor(color);
            if (scoreTv != null) {
                scoreTv.setTextColor(color);
                scoreTv.setTextSize(26f);
            }
            if (pb != null) {
                pb.setVisibility(View.VISIBLE);
                pb.setMax(100);
                pb.setProgress(0);
                pb.setProgressTintList(ColorStateList.valueOf(color));
                pb.setProgressBackgroundTintList(ColorStateList.valueOf(0xFF162035));
            }

            long delay = (long)(pagePos * 40) + (rowIdx * 30L);

            if (pb != null) {
                ObjectAnimator barAnim = ObjectAnimator.ofInt(pb, "progress", 0, Math.min(100, (int) m.score));
                barAnim.setStartDelay(delay);
                barAnim.setDuration(700);
                barAnim.setInterpolator(new AccelerateDecelerateInterpolator());
                barAnim.start();
            }
            if (scoreTv != null) {
                ValueAnimator numAnim = ValueAnimator.ofFloat(0f, m.score);
                numAnim.setStartDelay(delay);
                numAnim.setDuration(700);
                numAnim.setInterpolator(new AccelerateDecelerateInterpolator());
                numAnim.addUpdateListener(a -> scoreTv.setText(DF.format((float) a.getAnimatedValue())));
                numAnim.start();
            }

        } else {
            // ── Info-only metric ───────────────────────────────────────
            if (strip   != null) strip.setBackgroundColor(0xFF1A3050);
            if (pb      != null) pb.setVisibility(View.GONE);
            if (scoreTv != null) {
                scoreTv.setTextColor(0xFF00BFFF);
                scoreTv.setTextSize(12f);
                scoreTv.setText(m.value != null ? m.value : "—");
            }
        }

        container.addView(row);
    }

    // ── Color helper ──────────────────────────────────────────────────────

    public static int colorFor(float v) {
        if (v >= 80) return C_EXCELLENT;
        if (v >= 60) return C_GOOD;
        if (v >= 40) return C_AVERAGE;
        return C_POOR;
    }

    // ── ViewHolder ────────────────────────────────────────────────────────

    static class VH extends RecyclerView.ViewHolder {
        ImageView   faceImage;
        TextView    title, subtitle;
        LinearLayout metricsContainer;
        LinearLayout shareBtn;

        VH(View v) {
            super(v);
            faceImage        = v.findViewById(R.id.pageFaceImage);
            title            = v.findViewById(R.id.pageTitle);
            subtitle         = v.findViewById(R.id.pageSubtitle);
            metricsContainer = v.findViewById(R.id.metricsContainer);
            shareBtn         = v.findViewById(R.id.pageShareBtn);
        }
    }
}*/
