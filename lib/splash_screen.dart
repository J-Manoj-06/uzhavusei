import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(seconds: 3),
  });

  final Widget nextScreen;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _fadeController;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _contentFade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Widget buildFeatureIcon(IconData icon, int index) {
    return Container(
      margin: EdgeInsets.only(left: index == 0 ? 0 : 16),
      decoration: const BoxDecoration(
        color: Color(0x1A4CAF50),
        shape: BoxShape.circle,
      ),
      width: 48,
      height: 48,
      child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/banner1.jpeg',
          fit: BoxFit.cover,
        ),
        Container(color: Colors.white.withValues(alpha: 0.72)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.agriculture,
      Icons.location_on,
      Icons.handshake,
      Icons.grass,
      Icons.payment,
    ];

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          FadeTransition(
            opacity: _contentFade,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.eco,
                      size: 100,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'UzhavuSei',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connecting Farmers, Sharing Resources',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        icons.length,
                        (index) => buildFeatureIcon(icons[index], index),
                      ),
                    ),
                    const SizedBox(height: 34),
                    const SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                        backgroundColor: Color(0x334CAF50),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 230,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x334CAF50),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            widthFactor: _progressAnimation.value,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Loading resources...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
