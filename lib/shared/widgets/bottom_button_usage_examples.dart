import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/bottom_action_button.dart';

/// EXAMPLE USAGE PATTERNS FOR BOTTOM ACTION BUTTON ACROSS SCREENS
/// 
/// This file demonstrates how to implement BottomActionButton in various screens
/// Copy and adapt these patterns to your specific screens

// ======== PATTERN 1: Simple Call-to-Action Button ========
class ExampleSimpleButton extends StatelessWidget {
  const ExampleSimpleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your main content
        ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Main Content Here'),
            ),
          ],
        ),
        
        // Bottom Action Button
        BottomActionButton(
          label: 'Continue',
          icon: Icons.arrow_forward,
          onTap: () {
            // Handle action
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// ======== PATTERN 2: Button with Loading State ========
class ExampleLoadingButton extends StatefulWidget {
  const ExampleLoadingButton({super.key});

  @override
  State<ExampleLoadingButton> createState() => _ExampleLoadingButtonState();
}

class _ExampleLoadingButtonState extends State<ExampleLoadingButton> {
  bool _isProcessing = false;

  Future<void> _handleAction() async {
    setState(() => _isProcessing = true);
    
    // Simulate async operation
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isProcessing = false);
      // Handle success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: const [
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Main Content Here'),
            ),
          ],
        ),
        
        BottomActionButton(
          label: 'Submit',
          icon: Icons.check,
          isLoading: _isProcessing,
          loadingText: 'Processing...',
          onTap: !_isProcessing ? _handleAction : null,
          bottomOffset: 60,
        ),
      ],
    );
  }
}

// ======== PATTERN 3: Multiple Buttons (PageView navigation) ========
class ExampleMultipleButtons extends StatefulWidget {
  const ExampleMultipleButtons({super.key});

  @override
  State<ExampleMultipleButtons> createState() => _ExampleMultipleButtonsState();
}

class _ExampleMultipleButtonsState extends State<ExampleMultipleButtons> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage >= 3; // Adjust based on your page count

    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: const [
              Center(child: Text('Page 1')),
              Center(child: Text('Page 2')),
              Center(child: Text('Page 3')),
              Center(child: Text('Page 4')),
            ],
          ),
          
          // Back Button (hidden on first page)
          if (_currentPage > 0)
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: _previousPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 2),
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.surface.withValues(alpha: 0.5),
                        ),
                        child: const Center(
                          child: Text('Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.kineticGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            isLastPage ? 'Finish' : 'Next',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Single Next Button (first page)
            BottomActionButton(
              label: 'Next',
              icon: Icons.arrow_forward,
              onTap: _nextPage,
            ),
          
          // Final Button (last page)
          if (isLastPage)
            BottomActionButton(
              label: 'Get Started',
              icon: Icons.check,
              onTap: () {
                // Handle completion
              },
            ),
        ],
      ),
    );
  }
}

// ======== PATTERN 4: With Custom Position ========
class ExampleCustomPosition extends StatelessWidget {
  const ExampleCustomPosition({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: const [
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Main Content Here'),
            ),
          ],
        ),
        
        // Custom offset - closer or further from bottom
        BottomActionButton(
          label: 'Action',
          bottomOffset: 30, // Closer to bottom (default is 60)
          onTap: () {},
        ),
      ],
    );
  }
}

// ======== PATTERN 5: Context-Based Button (Conditional Rendering) ========
class ExampleConditionalButton extends StatefulWidget {
  const ExampleConditionalButton({super.key});

  @override
  State<ExampleConditionalButton> createState() => 
      _ExampleConditionalButtonState();
}

class _ExampleConditionalButtonState extends State<ExampleConditionalButton> {
  bool _hasData = false;

  void _loadData() async {
    setState(() => _hasData = true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: const [
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Main Content Here'),
            ),
          ],
        ),
        
        // Button only shows if certain conditions are met
        if (_hasData)
          BottomActionButton(
            label: 'Continue',
            icon: Icons.check,
            onTap: () {},
          )
        else
          BottomActionButton(
            label: 'Load Data',
            icon: Icons.refresh,
            onTap: _loadData,
          ),
      ],
    );
  }
}

// ======== COPY PATTERNS TO YOUR SCREENS ========

/*
Steps to apply to existing screens:

1. Add Stack wrapper to your Scaffold body (or existing Stack)
2. Wrap main content (ListView/SingleChildScrollView) with proper padding:
   padding: const EdgeInsets.only(bottom: 120),

3. Add BottomActionButton as last child of Stack

4. For screens with existing bottom buttons:
   - Look for buttons in Positioned widgets at the bottom
   - Replace with BottomActionButton component
   - Remove old padding/margins from bottom

5. For screens with PageView (like Onboarding):
   - Manage button visibility with conditional rendering
   - Use boolean to track current page index
   - Show different buttons for first/middle/last pages

SCREENS TO UPDATE:
- ✅ SplashScreen (already using optimized version)
- OnboardingScreen: Replace button row with navigation buttons
- ProgramsScreen: Add "Start Program" action button
- DashboardScreen: Add "View Tasks" action button  
- FaceScanScreen: Replace capture button
- ProgramDetailScreen: Replace CTA button
- ProfileScreen: Add contextual action button
*/
