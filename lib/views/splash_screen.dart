import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    // Logo glow pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Navigate after 3.4 s
    Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const LoginScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark1,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.splashGrad),
        child: Stack(
          children: [
            // ── Decorative background blobs ────────────────────
            _DecorCircle(top: -110, right: -110, size: 340,
                color: AppTheme.primary.withOpacity(0.13)),
            _DecorCircle(bottom: -90, left: -90, size: 300,
                color: AppTheme.primaryLighter.withOpacity(0.09)),
            _DecorCircle(topFraction: 0.38, left: -50, size: 170,
                color: AppTheme.green.withOpacity(0.07)),

            // ── Centre content ─────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 30),
                  _buildAppName(),
                  const SizedBox(height: 8),
                  _buildTagline(),
                  const SizedBox(height: 64),
                  _buildBouncingDots(),
                ],
              ),
            ),

            // ── Footer ─────────────────────────────────────────
            Positioned(
              bottom: 44, left: 0, right: 0,
              child: Center(
                child: Text(
                  'AI-Powered Exam Evaluation',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textOnDark2,
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 1400.ms).fadeIn(duration: 700.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final glow = 0.28 + _pulseCtrl.value * 0.28;
        return Container(
          width: 104, height: 104,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withOpacity(glow),
                  blurRadius: 48, spreadRadius: 8),
              BoxShadow(color: AppTheme.primaryLighter.withOpacity(0.18),
                  blurRadius: 22),
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 13, right: 13,
              child: Container(width: 16, height: 16,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle))),
            Positioned(bottom: 14, left: 13,
              child: Container(width: 8, height: 8,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    shape: BoxShape.circle))),
            const Icon(Icons.school_rounded, color: Colors.white, size: 46),
          ]),
        );
      },
    )
        .animate()
        .scale(begin: const Offset(0.45, 0.45), end: const Offset(1.0, 1.0),
            duration: 750.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 500.ms);
  }

  Widget _buildAppName() {
    return Text(
      'EduQuiz',
      style: GoogleFonts.outfit(
        fontSize: 46, fontWeight: FontWeight.w800,
        color: Colors.white, letterSpacing: -2.0,
      ),
    )
        .animate(delay: 250.ms)
        .fadeIn(duration: 550.ms)
        .slideY(begin: 0.35, end: 0, duration: 550.ms, curve: Curves.easeOut);
  }

  Widget _buildTagline() {
    return Text(
      'AI-Powered Learning Platform',
      style: GoogleFonts.outfit(
        fontSize: 14, color: AppTheme.textOnDark2,
        fontWeight: FontWeight.w400, letterSpacing: 0.4,
      ),
    )
        .animate(delay: 420.ms)
        .fadeIn(duration: 550.ms)
        .slideY(begin: 0.3, end: 0, duration: 550.ms, curve: Curves.easeOut);
  }

  /// ── Three bouncing dots loader ─────────────────────────────────
  Widget _buildBouncingDots() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: const BoxDecoration(
                color: AppTheme.primaryLighter,
                shape: BoxShape.circle,
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                  delay: (i * 200).ms,
                )
                .moveY(
                  begin: 0,
                  end: -16,
                  duration: 420.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .custom(
                  duration: 0.ms,
                  builder: (_, __, child) => child,
                );
          }),
        ),
        const SizedBox(height: 18),
        Text(
          'Getting ready…',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textOnDark2,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ).animate(delay: 850.ms).fadeIn(duration: 600.ms);
  }
}

// ── Decorative background circle ──────────────────────────────────
class _DecorCircle extends StatelessWidget {
  final double? top, bottom, left, right, topFraction;
  final double size;
  final Color color;

  const _DecorCircle({
    this.top, this.bottom, this.left, this.right, this.topFraction,
    required this.size, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final topVal = topFraction != null
        ? MediaQuery.sizeOf(context).height * topFraction!
        : top;
    return Positioned(
      top: topVal, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
