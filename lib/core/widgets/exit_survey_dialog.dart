import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class ExitSurveyDialog extends ConsumerStatefulWidget {
  final String collectionName;

  const ExitSurveyDialog({
    super.key,
    required this.collectionName,
  });

  @override
  ConsumerState<ExitSurveyDialog> createState() => _ExitSurveyDialogState();
}

class _ExitSurveyDialogState extends ConsumerState<ExitSurveyDialog> {
  final List<String> _options = [
    'Too expensive',
    'Not what I expected',
    'Just browsing',
    'Will do it later',
    'Technical issues',
  ];

  final Set<String> _selectedOptions = {};
  final TextEditingController _customReasonController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitAndExit() async {
    setState(() {
      _isSubmitting = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirestoreService().saveExitSurvey(
          userId: uid,
          collectionName: widget.collectionName,
          reasons: _selectedOptions.toList(),
          customText: _customReasonController.text.trim(),
        );
      } catch (e) {
        debugPrint('Failed to save exit survey: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      Navigator.of(context).pop(true); // Close dialog and return true
    }
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Why are you leaving?',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Icon(Icons.close, color: Colors.white54, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Please let us know how we can improve.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options.map((option) {
                final isSelected = _selectedOptions.contains(option);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedOptions.remove(option);
                      } else {
                        _selectedOptions.add(option);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withAlpha(40) : Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.white24,
                      ),
                    ),
                    child: Text(
                      option,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: isSelected ? AppTheme.primary : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _customReasonController,
              maxLines: 3,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Please complain here...',
                hintStyle: GoogleFonts.outfit(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: _isSubmitting ? null : AppTheme.gradientAccent,
                color: _isSubmitting ? Colors.grey : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isSubmitting
                    ? []
                    : [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(80),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSubmitting ? null : _submitAndExit,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Submit & Exit',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
