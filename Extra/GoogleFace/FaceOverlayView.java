package com.rafsan.growup099.GoogleFace;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PointF;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.Nullable;

import com.google.mlkit.vision.face.Face;
import com.google.mlkit.vision.face.FaceContour;
import com.google.mlkit.vision.face.FaceLandmark;

import java.util.List;

public class FaceOverlayView extends View {

    private Face face;
    private Paint contourPaint;
    private Paint landmarkPaint;
    private Paint scanLinePaint;
    private Paint glowPaint;
    private Paint meshPaint;
    private float scaleX = 1f;
    private float scaleY = 1f;
    private boolean isScanning = false;
    private float scanLineY = 0f;

    public FaceOverlayView(Context context) {
        super(context);
        init();
    }

    public FaceOverlayView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public FaceOverlayView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        // Contour paint - neon blue lines
        contourPaint = new Paint();
        contourPaint.setColor(Color.parseColor("#00E5FF"));
        contourPaint.setStyle(Paint.Style.STROKE);
        contourPaint.setStrokeWidth(3f);
        contourPaint.setAntiAlias(true);
        contourPaint.setShadowLayer(10f, 0f, 0f, Color.parseColor("#00E5FF"));

        // Landmark paint - bright points
        landmarkPaint = new Paint();
        landmarkPaint.setColor(Color.parseColor("#FF6B00"));
        landmarkPaint.setStyle(Paint.Style.FILL);
        landmarkPaint.setAntiAlias(true);
        landmarkPaint.setShadowLayer(15f, 0f, 0f, Color.parseColor("#FF6B00"));

        // Scan line paint
        scanLinePaint = new Paint();
        scanLinePaint.setColor(Color.parseColor("#00FF88"));
        scanLinePaint.setStrokeWidth(2f);
        scanLinePaint.setAntiAlias(true);
        scanLinePaint.setShadowLayer(20f, 0f, 0f, Color.parseColor("#00FF88"));

        // Glow paint
        glowPaint = new Paint();
        glowPaint.setColor(Color.parseColor("#3300E5FF"));
        glowPaint.setStyle(Paint.Style.FILL);
        glowPaint.setAntiAlias(true);

        // Mesh paint
        meshPaint = new Paint();
        meshPaint.setColor(Color.parseColor("#6600E5FF"));
        meshPaint.setStyle(Paint.Style.STROKE);
        meshPaint.setStrokeWidth(1f);
        meshPaint.setAntiAlias(true);
    }

    public void setFace(Face face, float scaleX, float scaleY) {
        this.face = face;
        this.scaleX = scaleX;
        this.scaleY = scaleY;
        invalidate();
    }

    public void setScanning(boolean scanning) {
        this.isScanning = scanning;
        invalidate();
    }

    public void setScanLineY(float y) {
        this.scanLineY = y;
        invalidate();
    }

    public void clear() {
        this.face = null;
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);

        if (face == null) return;

        // Draw face mesh/grid
        drawFaceMesh(canvas);

        // Draw all face contours with glow
        drawFaceContours(canvas);

        // Draw landmarks (eyes, nose, mouth)
        drawLandmarks(canvas);

        // Draw scanning line if scanning
        if (isScanning) {
            drawScanLine(canvas);
        }

        // Draw bounding box with corners
        drawBoundingBox(canvas);
    }

    private void drawFaceMesh(Canvas canvas) {
        if (face == null) return;

        // ✅ NULL CHECK - Get face contour safely
        FaceContour faceContour = face.getContour(FaceContour.FACE);
        if (faceContour == null) return;

        List<PointF> contourPoints = faceContour.getPoints();
        if (contourPoints == null || contourPoints.isEmpty()) return;

        // Draw horizontal mesh lines
        float top = Float.MAX_VALUE;
        float bottom = Float.MIN_VALUE;

        for (PointF point : contourPoints) {
            float y = translateY(point.y);
            top = Math.min(top, y);
            bottom = Math.max(bottom, y);
        }

        // Draw horizontal lines
        int numLines = 15;
        float step = (bottom - top) / numLines;
        for (int i = 0; i <= numLines; i++) {
            float y = top + (i * step);
            canvas.drawLine(0, y, getWidth(), y, meshPaint);
        }
    }

    private void drawFaceContours(Canvas canvas) {
        if (face == null) return;

        // ✅ NULL CHECKS for each contour
        // Face oval
        drawContourSafe(canvas, FaceContour.FACE);

        // Left eyebrow
        drawContourSafe(canvas, FaceContour.LEFT_EYEBROW_TOP);
        drawContourSafe(canvas, FaceContour.LEFT_EYEBROW_BOTTOM);

        // Right eyebrow
        drawContourSafe(canvas, FaceContour.RIGHT_EYEBROW_TOP);
        drawContourSafe(canvas, FaceContour.RIGHT_EYEBROW_BOTTOM);

        // Left eye
        drawContourSafe(canvas, FaceContour.LEFT_EYE);

        // Right eye
        drawContourSafe(canvas, FaceContour.RIGHT_EYE);

        // Nose bridge
        drawContourSafe(canvas, FaceContour.NOSE_BRIDGE);

        // Nose bottom
        drawContourSafe(canvas, FaceContour.NOSE_BOTTOM);

        // Upper lip
        drawContourSafe(canvas, FaceContour.UPPER_LIP_TOP);
        drawContourSafe(canvas, FaceContour.UPPER_LIP_BOTTOM);

        // Lower lip
        drawContourSafe(canvas, FaceContour.LOWER_LIP_TOP);
        drawContourSafe(canvas, FaceContour.LOWER_LIP_BOTTOM);
    }

    /**
     * ✅ SAFE method to draw contours with null checks
     */
    private void drawContourSafe(Canvas canvas, int contourType) {
        if (face == null) return;

        FaceContour contour = face.getContour(contourType);
        if (contour == null) return;

        List<PointF> points = contour.getPoints();
        if (points == null || points.isEmpty()) return;

        drawContour(canvas, points, contourPaint);
    }

    private void drawContour(Canvas canvas, List<PointF> contour, Paint paint) {
        if (contour == null || contour.isEmpty()) return;

        Path path = new Path();
        PointF firstPoint = contour.get(0);
        path.moveTo(translateX(firstPoint.x), translateY(firstPoint.y));

        for (int i = 1; i < contour.size(); i++) {
            PointF point = contour.get(i);
            path.lineTo(translateX(point.x), translateY(point.y));
        }

        // Draw glow first
        canvas.drawPath(path, glowPaint);
        // Draw main line
        canvas.drawPath(path, paint);
    }

    private void drawLandmarks(Canvas canvas) {
        if (face == null) return;

        // ✅ NULL CHECKS for each landmark
        // Left eye
        drawLandmark(canvas, face.getLandmark(FaceLandmark.LEFT_EYE));

        // Right eye
        drawLandmark(canvas, face.getLandmark(FaceLandmark.RIGHT_EYE));

        // Nose base
        drawLandmark(canvas, face.getLandmark(FaceLandmark.NOSE_BASE));

        // Mouth corners
        drawLandmark(canvas, face.getLandmark(FaceLandmark.MOUTH_LEFT));
        drawLandmark(canvas, face.getLandmark(FaceLandmark.MOUTH_RIGHT));
        drawLandmark(canvas, face.getLandmark(FaceLandmark.MOUTH_BOTTOM));

        // Left ear
        drawLandmark(canvas, face.getLandmark(FaceLandmark.LEFT_EAR));

        // Right ear
        drawLandmark(canvas, face.getLandmark(FaceLandmark.RIGHT_EAR));

        // Left cheek
        drawLandmark(canvas, face.getLandmark(FaceLandmark.LEFT_CHEEK));

        // Right cheek
        drawLandmark(canvas, face.getLandmark(FaceLandmark.RIGHT_CHEEK));
    }

    private void drawLandmark(Canvas canvas, FaceLandmark landmark) {
        if (landmark == null) return;

        PointF position = landmark.getPosition();
        if (position == null) return;

        float x = translateX(position.x);
        float y = translateY(position.y);

        // Draw glow circle
        canvas.drawCircle(x, y, 8f, glowPaint);
        // Draw main point
        canvas.drawCircle(x, y, 5f, landmarkPaint);
    }

    private void drawScanLine(Canvas canvas) {
        if (scanLineY > 0 && scanLineY < getHeight()) {
            canvas.drawLine(0, scanLineY, getWidth(), scanLineY, scanLinePaint);
        }
    }

    private void drawBoundingBox(Canvas canvas) {
        if (face == null) return;

        android.graphics.Rect bounds = face.getBoundingBox();
        if (bounds == null) return;

        float left = translateX(bounds.left);
        float top = translateY(bounds.top);
        float right = translateX(bounds.right);
        float bottom = translateY(bounds.bottom);

        Paint boxPaint = new Paint();
        boxPaint.setColor(Color.parseColor("#FF6B00"));
        boxPaint.setStyle(Paint.Style.STROKE);
        boxPaint.setStrokeWidth(2f);
        boxPaint.setAntiAlias(true);

        // Draw corners only (more modern look)
        float cornerLength = 40f;

        // Top-left corner
        canvas.drawLine(left, top, left + cornerLength, top, boxPaint);
        canvas.drawLine(left, top, left, top + cornerLength, boxPaint);

        // Top-right corner
        canvas.drawLine(right - cornerLength, top, right, top, boxPaint);
        canvas.drawLine(right, top, right, top + cornerLength, boxPaint);

        // Bottom-left corner
        canvas.drawLine(left, bottom - cornerLength, left, bottom, boxPaint);
        canvas.drawLine(left, bottom, left + cornerLength, bottom, boxPaint);

        // Bottom-right corner
        canvas.drawLine(right - cornerLength, bottom, right, bottom, boxPaint);
        canvas.drawLine(right, bottom - cornerLength, right, bottom, boxPaint);
    }

    private float translateX(float x) {
        return x * scaleX;
    }

    private float translateY(float y) {
        return y * scaleY;
    }
}