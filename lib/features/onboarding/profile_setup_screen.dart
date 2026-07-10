import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/firestore_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedAge = 20;
  String _selectedGender = 'Male';
  bool _isSaving = false;

  String _selectedSkinType = 'Oily';
  final List<String> _skinTypes = ['Dry', 'Oily', 'Combination', 'Normal'];

  String _selectedBudget = 'Basic';
  final List<String> _budgets = ['Basic', 'Standard', 'Premium'];

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your name.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Save state using Riverpod (SharedPreferences)
    await ref.read(userStateProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          age: _selectedAge,
          gender: _selectedGender,
        );
    await ref.read(userStateProvider.notifier).updateLifestyle(
          skinType: _selectedSkinType,
          budget: _selectedBudget,
        );

    // Save to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirestoreService().updateUser(user.uid, {
          'display_name': _nameController.text.trim(),
          'age': _selectedAge,
          'gender': _selectedGender,
          'skinType': _selectedSkinType,
          'budget': _selectedBudget,
        });
      } catch (e) {
        debugPrint('Error saving profile to Firestore: $e');
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
      // Route to goals selection
      Navigator.of(context).pushNamed('/goals');
    }
  }

  Widget _buildSelectionChips(String title, List<String> options, String selectedValue, ValueChanged<String> onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return GestureDetector(
              onTap: () => onSelected(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withAlpha(50) : Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Heading
                Text(
                  'Build Your Profile',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let us personalize your Lookmaxxing roadmap.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Form Container
                GlassContainer(
                  glowColor: AppTheme.secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Input
                      Text(
                        'WHAT IS YOUR NAME?',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter your name...',
                          hintStyle: GoogleFonts.outfit(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.black38,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Gender Selection
                      Text(
                        'SELECT YOUR GENDER',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedGender = 'Male'),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Male' ? AppTheme.primary.withAlpha(50) : Colors.black38,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedGender == 'Male' ? AppTheme.primary : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Male 👑',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedGender = 'Female'),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Female' ? AppTheme.secondary.withAlpha(50) : Colors.black38,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedGender == 'Female' ? AppTheme.secondary : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Female ✨',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Age Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HOW OLD ARE YOU?',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '$_selectedAge Years',
                            style: GoogleFonts.outfit(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _selectedAge.toDouble(),
                        min: 14,
                        max: 45,
                        divisions: 31,
                        activeColor: AppTheme.primary,
                        inactiveColor: Colors.black38,
                        onChanged: (val) {
                          setState(() {
                            _selectedAge = val.toInt();
                          });
                        },
                      ),
                      const SizedBox(height: 28),
                      
                      _buildSelectionChips('WHAT IS YOUR SKIN TYPE?', _skinTypes, _selectedSkinType, (val) {
                        setState(() => _selectedSkinType = val);
                      }),

                      _buildSelectionChips('WHAT IS YOUR BUDGET FOR PRODUCTS?', _budgets, _selectedBudget, (val) {
                        setState(() => _selectedBudget = val);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Save button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CONTINUE',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
