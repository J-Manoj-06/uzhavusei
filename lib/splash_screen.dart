import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:UzhavuSei/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/location_provider.dart';
import 'providers/user_profile_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER FOR BACKGROUND CONNECTION LINES
// ─────────────────────────────────────────────────────────────────────────────

class SplashBackgroundPainter extends CustomPainter {
  const SplashBackgroundPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0) return;

    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: opacity * 0.05)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw the main diagonal lines crossing behind the logo
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.3),
      Offset(size.width * 0.85, size.height * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.3),
      Offset(size.width * 0.15, size.height * 0.7),
      paint,
    );

    // Draw horizontal and vertical connecting lines that converge
    canvas.drawLine(
      Offset(size.width * 0.1, center.dy),
      Offset(size.width * 0.9, center.dy),
      paint,
    );

    // Draw additional delicate concentric dashed guides for the network nodes
    final dashPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: opacity * 0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _drawDashedCircle(canvas, center, size.width * 0.25, dashPaint);
    _drawDashedCircle(canvas, center, size.width * 0.38, dashPaint);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const int dashCount = 40;
    const double dashWidth = 5.0;
    final double circumference = 2 * math.pi * radius;
    final double dashAngle = (dashWidth / circumference) * 2 * math.pi;
    final double spaceAngle = (2 * math.pi - (dashCount * dashAngle)) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = i * (dashAngle + spaceAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SplashBackgroundPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BORROW LOGO WIDGET — Custom M3 logo with network hub sharing icon
// ─────────────────────────────────────────────────────────────────────────────

class BorrowLogoWidget extends StatelessWidget {
  const BorrowLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Rounded square container with custom sharing hub icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _LogoHubPainter(),
          ),
        ),
        const SizedBox(width: 16),
        // Borrow Text Logo
        const Text(
          'Borrow',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LogoHubPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw central node
    canvas.drawCircle(center, 5.0, paint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // Branches going out to 4 smaller nodes
    final angles = [
      -math.pi / 4,      // Top Right
      -3 * math.pi / 4,  // Top Left
      math.pi / 4,       // Bottom Right
      3 * math.pi / 4,   // Bottom Left
    ];

    const double branchLength = 12.0;

    for (final angle in angles) {
      final target = Offset(
        center.dx + math.cos(angle) * branchLength,
        center.dy + math.sin(angle) * branchLength,
      );

      // Draw line
      canvas.drawLine(center, target, linePaint);

      // Draw terminal node
      canvas.drawCircle(target, 3.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING RESOURCE ICON
// ─────────────────────────────────────────────────────────────────────────────

class FloatingResourceIcon extends StatefulWidget {
  const FloatingResourceIcon({
    super.key,
    required this.icon,
    required this.alignment,
    required this.duration,
    required this.offsetRange,
  });

  final IconData icon;
  final Alignment alignment;
  final Duration duration;
  final double offsetRange;

  @override
  State<FloatingResourceIcon> createState() => _FloatingResourceIconState();
}

class _FloatingResourceIconState extends State<FloatingResourceIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    // Use a smooth sinusoidal-like float animation
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(
        (math.Random().nextDouble() * 2 - 1) * widget.offsetRange,
        (math.Random().nextDouble() * 2 - 1) * widget.offsetRange,
      ),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
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
    return Align(
      alignment: widget.alignment,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: _animation.value,
            child: child,
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING STATUS TEXT
// ─────────────────────────────────────────────────────────────────────────────

class LoadingStatusText extends StatefulWidget {
  const LoadingStatusText({super.key});

  @override
  State<LoadingStatusText> createState() => _LoadingStatusTextState();
}

class _LoadingStatusTextState extends State<LoadingStatusText> {
  int _currentIndex = 0;
  Timer? _timer;

  static const List<String> _messages = [
    'Preparing your community...',
    'Finding nearby resources...',
    'Loading shared items...',
    'Connecting nearby members...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        _messages[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED PROGRESS INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedProgressIndicator extends StatefulWidget {
  const AnimatedProgressIndicator({super.key});

  @override
  State<AnimatedProgressIndicator> createState() =>
      _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animation = CurveTween(curve: Curves.easeInOut).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset(-1.0 + (_animation.value * 2.0), 0.0),
            child: FractionallySizedBox(
              widthFactor: 0.6,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(seconds: 4),
  });

  final Widget nextScreen;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  late final AnimationController _breathingController;
  late final Animation<double> _breathingScale;

  late final AnimationController _linesController;
  late final Animation<double> _linesOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Fade + scale entry animation (700 ms, easeOutCubic)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _logoOpacity = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );

    // 2. Infinite breathing animation (2s per cycle: 1.00 -> 1.05 -> 1.00)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _breathingScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_breathingController);

    // Start breathing after the entrance finishes
    _entryController.forward().then((_) {
      _breathingController.repeat();
    });

    // 3. Connection lines fade-in animation (slowly starts after logo appears)
    _linesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _linesOpacity = CurvedAnimation(
      parent: _linesController,
      curve: Curves.easeIn,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _linesController.forward();
    });

    // Start initialization processes
    _performInitialization();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _breathingController.dispose();
    _linesController.dispose();
    super.dispose();
  }

  Future<void> _performInitialization() async {
    final startTime = DateTime.now();

    try {
      // Initialize location provider & auth checks
      final locProvider = Provider.of<LocationProvider>(context, listen: false);
      final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);

      // Verify location services and fetch permission status (non-blocking if disabled)
      await Geolocator.isLocationServiceEnabled();

      // If user is authenticated, preload profile data
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await profileProvider.loadProfileImage();
      }

      // Check current location status
      await locProvider.recheckPermission();
    } catch (e) {
      // Gracefully catch background load errors (e.g. offline during splash)
    }

    // Enforce a minimum display time of 3.5 seconds to appreciate the beautiful premium entry animation
    final elapsed = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(milliseconds: 3500) - elapsed;

    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    // Custom smooth fade route transition of 400ms duration
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Subtle radial gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFEFF6FF), // very light blue tint glow in center
                    Color(0xFFF8FAFC), // back to slate background
                  ],
                  center: Alignment.center,
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // 2. Fade-in network connection lines painter
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _linesOpacity,
              builder: (context, child) {
                return CustomPaint(
                  painter: SplashBackgroundPainter(opacity: _linesOpacity.value),
                );
              },
            ),
          ),

          // 3. Six floating resource nodes positioned dynamically using FractionallySizedBox and Alignment
          const FloatingResourceIcon(
            icon: Icons.menu_book_rounded, // Book
            alignment: Alignment(-0.6, -0.6),
            duration: Duration(milliseconds: 3200),
            offsetRange: 8.0,
          ),
          const FloatingResourceIcon(
            icon: Icons.handyman_rounded, // Tools
            alignment: Alignment(0.65, -0.55),
            duration: Duration(milliseconds: 3600),
            offsetRange: 6.0,
          ),
          const FloatingResourceIcon(
            icon: Icons.fitness_center_rounded, // Dumbbell / Sports
            alignment: Alignment(-0.75, -0.05),
            duration: Duration(milliseconds: 4000),
            offsetRange: 9.0,
          ),
          const FloatingResourceIcon(
            icon: Icons.home_rounded, // House / Shelter
            alignment: Alignment(0.78, -0.05),
            duration: Duration(milliseconds: 4400),
            offsetRange: 7.0,
          ),
          const FloatingResourceIcon(
            icon: Icons.yard_rounded, // Garden / Plant
            alignment: Alignment(-0.55, 0.55),
            duration: Duration(milliseconds: 4800),
            offsetRange: 8.0,
          ),
          const FloatingResourceIcon(
            icon: Icons.inventory_2_rounded, // Box / Storage
            alignment: Alignment(0.55, 0.6),
            duration: Duration(milliseconds: 5200),
            offsetRange: 7.0,
          ),

          // 4. Center Logo and Text with breathing & entrance scale/fade animations
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_entryController, _breathingController]),
              builder: (context, child) {
                final scale = _breathingController.isAnimating
                    ? _breathingScale.value
                    : _logoScale.value;

                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: scale,
                    child: const BorrowLogoWidget(),
                  ),
                );
              },
            ),
          ),

          // 5. Bottom Loading Indicator & Status messages
          const Align(
            alignment: Alignment(0.0, 0.88),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingStatusText(),
                SizedBox(height: 18),
                AnimatedProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
