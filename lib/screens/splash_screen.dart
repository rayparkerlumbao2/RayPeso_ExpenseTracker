import 'package:material_ui/material_ui.dart';

import '../providers/expense_provider.dart';
import '../widgets/peso_ray_logo.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final ExpenseProvider provider;

  const SplashScreen({super.key, required this.provider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.easeInOut),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreen(provider: widget.provider),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1218) : Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // Radiant Peso Sun Coin Logo
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: const PesoRayLogo(size: 210),
                      ),
                      const SizedBox(height: 36),

                      // PesoRay Brand Name
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Peso',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF0C3D2E),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const TextSpan(
                              text: 'Ray',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFC77E19),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Progress bar matching photo
                      SizedBox(
                        width: 170,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              // Background track
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withAlpha(25)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              // Animated progress fill
                              FractionallySizedBox(
                                widthFactor: _progressAnimation.value.clamp(0.05, 1.0),
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC77E19),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Loading caption
                      Text(
                        'Loading your wallet...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          letterSpacing: 0.1,
                        ),
                      ),

                      const Spacer(flex: 4),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
