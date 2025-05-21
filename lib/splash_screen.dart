import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController progressController;

  @override
  void initState() {
    super.initState();
    progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UzhavuSei()),
      );
    });
  }

  @override
  void dispose() {
    progressController.dispose();
    super.dispose();
  }

  Widget buildFeatureIcon(IconData icon, int index) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 1500),
      opacity: 1.0,
      curve: Curves.easeInOut,
      child: Container(
        margin: EdgeInsets.only(left: index == 0 ? 0 : 16),
        decoration: const BoxDecoration(
          color: Color(0x1A4CAF50),
          shape: BoxShape.circle,
        ),
        width: 48,
        height: 48,
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
      ),
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
          // Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(
                'https://public.readdy.ai/ai/img_res/971a5965f88df1b4c03c2243299d2bf1.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Splash Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with pulse
                const AnimatedScale(
                  scale: 1.05,
                  duration: Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.eco,
                    size: 100,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'UzhavuSei',
                  style: GoogleFonts.montserrat(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connecting Farmers, Sharing Resources',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF555555),
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
                const SizedBox(height: 32),
                // Loading Circle
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                    backgroundColor: Color(0x334CAF50),
                  ),
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x334CAF50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: AnimatedBuilder(
                    animation: progressController,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        widthFactor: progressController.value,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            borderRadius: BorderRadius.all(Radius.circular(2)),
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
        ],
      ),
    );
  }
}
