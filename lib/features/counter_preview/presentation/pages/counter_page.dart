import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';

class CounterPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const CounterPage({
    Key? key,
    required this.onToggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    if (_counter > 0) {
      setState(() {
        _counter--;
      });
    }
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          // Premium subtle background decorations
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(isDark ? 0.15 : 0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Custom Header / Bar
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        ),
                        child: const Icon(
                          Icons.dashboard_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spaceS),
                      Text(
                        'VSARTS Studio',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: widget.onToggleTheme,
                    ),
                    const SizedBox(width: AppConstants.spaceS),
                  ],
                ),

                // Main Dashboard Body
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppConstants.spaceM),
                      
                      // Welcome Segment
                      Text(
                        'Welcome to your\nnew project.',
                        style: theme.textTheme.displayLarge?.copyWith(
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceS),
                      Text(
                        'This project is configured with a high-fidelity Feature-First architecture, optimized lint rules, and professional Git configuration.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: AppConstants.spaceXL),

                      // Premium Interactive Glass-Style Card
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spaceL),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(AppConstants.radiusL),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Interactive Demo',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Counter Component',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spaceS,
                                    vertical: AppConstants.spaceXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'READY',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spaceXL),
                            
                            // Visual Animated Counter Display
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: AppConstants.durationNormalMs),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                '$_counter',
                                key: ValueKey<int>(_counter),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: AppConstants.spaceXL),

                            // Control Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _counter == 0 ? null : _decrementCounter,
                                    icon: const Icon(Icons.remove),
                                    label: const Text('Decrease'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceM),
                                      side: BorderSide(
                                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spaceM),
                                Expanded(
                                  child: CustomButton(
                                    text: 'Increase',
                                    icon: Icons.add,
                                    isGradient: true,
                                    onTap: _incrementCounter,
                                  ),
                                ),
                              ],
                            ),
                            
                            if (_counter > 0) ...[
                              const SizedBox(height: AppConstants.spaceM),
                              TextButton(
                                onPressed: _resetCounter,
                                child: Text(
                                  'Reset Count',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.spaceXL),

                      // Features/Architecture Checkpoints Showcase
                      Text(
                        'Project Blueprint Highlights',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppConstants.spaceM),
                      
                      _buildBulletPoint(
                        context,
                        icon: Icons.folder_copy_rounded,
                        title: 'Feature-First Folder Layout',
                        subtitle: 'Organized modular architecture under lib/features/ and common dependencies under lib/core/.',
                      ),
                      const SizedBox(height: AppConstants.spaceM),
                      _buildBulletPoint(
                        context,
                        icon: Icons.palette_rounded,
                        title: 'Premium Cohesive Palette',
                        subtitle: 'Pre-configured HSL colors supporting robust Material 3 Light/Dark color themes.',
                      ),
                      const SizedBox(height: AppConstants.spaceM),
                      _buildBulletPoint(
                        context,
                        icon: Icons.security_rounded,
                        title: 'Strict Quality Lints',
                        subtitle: 'Strict analysis parameters via analysis_options.yaml to maintain elegant and compliant Dart standards.',
                      ),
                      const SizedBox(height: AppConstants.spaceXXL),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withOpacity(0.5) : AppColors.cardLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppConstants.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
