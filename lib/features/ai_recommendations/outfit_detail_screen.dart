import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/outfit_history_provider.dart';

class OutfitDetailScreen extends StatefulWidget {
  final OutfitRecord record;
  const OutfitDetailScreen({super.key, required this.record});

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  int _selectedCategoryIndex = 0;

  IconData _getIconForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('top') || lower.contains('shirt') || lower.contains('jacket')) return Icons.checkroom_rounded;
    if (lower.contains('bottom') || lower.contains('pant') || lower.contains('jeans') || lower.contains('trouser')) return Icons.airline_seat_legroom_normal_rounded;
    if (lower.contains('foot') || lower.contains('shoe') || lower.contains('sneaker')) return Icons.roller_skating_rounded;
    if (lower.contains('access') || lower.contains('watch') || lower.contains('glass')) return Icons.watch_rounded;
    if (lower.contains('outfit')) return Icons.accessibility_new_rounded;
    return Icons.checkroom_rounded;
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.record.fullData;
    
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          DateFormat('MMM dd, yyyy').format(widget.record.date),
          style: GoogleFonts.cinzel(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                if (widget.record.imagePath != null && File(widget.record.imagePath!).existsSync())
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.glassBorder, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      File(widget.record.imagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                
                const SizedBox(height: 32),

                // Visual Color Palette
                if (data['color_palette'] != null) ...[
                  Text(
                    'Recommended Color Palette',
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: (data['color_palette'] as List).map((colorObj) {
                        final colorHex = colorObj['hex']?.toString() ?? '#FFFFFF';
                        final colorName = colorObj['name']?.toString() ?? '';
                        final parsedColor = _hexToColor(colorHex);
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: parsedColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: parsedColor.withAlpha(100),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                colorName,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Overall Verdict
                if (data['overall_verdict'] != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Stylist Verdict',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withAlpha(20),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withAlpha(80), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(10),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Text(
                      data['overall_verdict'].toString(),
                      style: GoogleFonts.outfit(
                        color: Colors.white.withAlpha(240),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Fashion Categories Tabs
                if (data['categories'] != null) ...[
                  Text(
                    'Outfit Breakdown',
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate((data['categories'] as List).length, (index) {
                        final category = data['categories'][index];
                        final isSelected = _selectedCategoryIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary.withAlpha(20) : AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : AppTheme.glassBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              category['name']?.toString() ?? 'Category',
                              style: GoogleFonts.outfit(
                                color: isSelected ? AppTheme.primary : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Display Items for Selected Category
                  Builder(
                    builder: (context) {
                      final categories = data['categories'] as List;
                      if (categories.isEmpty || _selectedCategoryIndex >= categories.length) return const SizedBox();
                      
                      final items = categories[_selectedCategoryIndex]['items'] as List?;
                      if (items == null || items.isEmpty) return const SizedBox();

                      return Column(
                        children: items.map((item) {
                          final type = item['type']?.toString() ?? 'Item';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.surface.withAlpha(150),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white10, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withAlpha(20),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(_getIconForType(type), color: AppTheme.primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        type,
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item['description']?.toString() ?? '',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withAlpha(230),
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
