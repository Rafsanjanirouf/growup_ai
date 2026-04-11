import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/voice_guide_provider.dart';
import '../../core/theme/app_colors.dart';

class VoiceGuideToggle extends ConsumerStatefulWidget {
  const VoiceGuideToggle({super.key});

  @override
  ConsumerState<VoiceGuideToggle> createState() => _VoiceGuideToggleState();
}

class _VoiceGuideToggleState extends ConsumerState<VoiceGuideToggle> {
  Offset _offset = const Offset(0, 0); // Local offset within the Draggable context
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isVoiceEnabled = ref.watch(voiceGuideProvider);
    final size = MediaQuery.of(context).size;

    return Positioned(
      left: _offset.dx == 0 ? null : _offset.dx,
      right: _offset.dx == 0 ? 24 : null,
      top: _offset.dy == 0 ? 60 : _offset.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanEnd: (_) => setState(() => _isDragging = false),
        onPanUpdate: (details) {
          setState(() {
            _offset = Offset(
              (_offset.dx == 0 ? size.width - 24 - 100 : _offset.dx) + details.delta.dx,
              (_offset.dy == 0 ? 60 : _offset.dy) + details.delta.dy,
            ).clamp(
              const Offset(16, 40),
              Offset(size.width - 120, size.height - 100),
            );
          });
        },
        child: AnimatedScale(
          scale: _isDragging ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: GestureDetector(
                onTap: () => ref.read(voiceGuideProvider.notifier).toggleVoiceGuide(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isVoiceEnabled 
                        ? AppColors.primary.withValues(alpha: 0.2) 
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isVoiceEnabled 
                          ? AppColors.primary.withValues(alpha: 0.4) 
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (isVoiceEnabled || _isDragging)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: _isDragging ? 25 : 15,
                        spreadRadius: -5,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: isVoiceEnabled ? AppColors.primary : Colors.white70,
                        size: 20,
                      ),
                      if (isVoiceEnabled) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'AI GUIDE ON',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension OffsetExtension on Offset {
  Offset clamp(Offset min, Offset max) {
    return Offset(
      dx.clamp(min.dx, max.dx),
      dy.clamp(min.dy, max.dy),
    );
  }
}
