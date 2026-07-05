import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'teacher_screen.dart';
import 'student_courses_screen.dart';
import 'admin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    Timer(const Duration(milliseconds: 3800), () async {
      if (!mounted) return;
      
      final authCtrl = AuthController();
      await authCtrl.autoLogin();
      
      Widget dest = const LoginScreen();
      if (authCtrl.currentUser != null) {
        final user = authCtrl.currentUser!;
        if (user.role == 'admin') {
          dest = AdminDashboard(adminName: user.name);
        } else if (user.role == 'teacher') {
          dest = TeacherScreen(teacherId: user.id, teacherName: user.name);
        } else {
          dest = StudentCoursesScreen(
            studentName: user.name,
            studentId: user.id,
            rollNo: user.rollNo,
          );
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => dest,
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
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09080F),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF09080F),
              Color(0xFF0C0A1E),
              Color(0xFF13103A),
              Color(0xFF0C0A1E),
              Color(0xFF09080F),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ── Shiny star particles ────────────────────────────
            ..._buildStars(),

            // ── Glowing radial blobs ──────────────────────────
            Positioned(
              top: -100, right: -100,
              child: _GlowBlob(
                size: 320,
                color: const Color(0xFF4F46E5),
                pulseCtrl: _pulseCtrl,
              ),
            ),
            Positioned(
              bottom: -80, left: -80,
              child: _GlowBlob(
                size: 280,
                color: const Color(0xFF7C3AED),
                pulseCtrl: _pulseCtrl,
              ),
            ),
            Positioned(
              top: MediaQuery.sizeOf(context).height * 0.35,
              left: -40,
              child: _GlowBlob(
                size: 200,
                color: const Color(0xFF0D9488),
                pulseCtrl: _pulseCtrl,
              ),
            ),

            // ── Centre content ──────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie animation
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Lottie.asset(
                      'assets/lottie/student.json',
                      animate: true,
                      repeat: true,
                    ),
                  )
                      .animate()
                      .scaleXY(
                          begin: 0.3,
                          end: 1.0,
                          duration: 800.ms,
                          curve: Curves.elasticOut)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // App name with shimmer
                  _buildShimmerName(),

                  const SizedBox(height: 10),

                  // Tagline
                  _buildTagline(),

                  const SizedBox(height: 58),

                  // Bouncing dots
                  _buildBouncingDots(),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────
            Positioned(
              bottom: 44, left: 0, right: 0,
              child: Center(
                child: Text(
                  'AI-Powered Exam Evaluation',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 1500.ms).fadeIn(duration: 700.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shiny star particles ─────────────────────────────────────
  List<Widget> _buildStars() {
    final rng = math.Random(42);
    return List.generate(25, (i) {
      final top = rng.nextDouble() * MediaQuery.sizeOf(context).height;
      final left = rng.nextDouble() * MediaQuery.sizeOf(context).width;
      final size = 1.5 + rng.nextDouble() * 2.5;
      final delay = (rng.nextDouble() * 2000).ms;
      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.6),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true), delay: delay)
            .fadeIn(duration: 1200.ms)
            .then()
            .fadeOut(duration: 1200.ms),
      );
    });
  }

  // ── Shiny logo ───────────────────────────────────────────────
  Widget _buildShinyLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _floatCtrl]),
      builder: (_, __) {
        final glow = 0.3 + _pulseCtrl.value * 0.35;
        final floatY = math.sin(_floatCtrl.value * math.pi) * 6;
        return Transform.translate(
          offset: Offset(0, -floatY),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3730A3),
                  Color(0xFF4F46E5),
                  Color(0xFF818CF8),
                  Color(0xFFA5B4FC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(glow),
                    blurRadius: 40,
                    spreadRadius: 8),
                BoxShadow(
                    color: const Color(0xFF818CF8).withOpacity(0.25),
                    blurRadius: 20),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shimmer highlight
                AnimatedBuilder(
                  animation: _shimmerCtrl,
                  builder: (_, __) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.15),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment(
                                -1.0 + 2 * _shimmerCtrl.value, -0.5),
                            end: Alignment(
                                1.0 + 2 * _shimmerCtrl.value, 0.5),
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(
                          width: 88,
                          height: 88,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    );
                  },
                ),
                // Decorative dots
                Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ))),
                Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ))),
                const Icon(Icons.school_rounded, color: Colors.white, size: 40),
              ],
            ),
          ),
        );
      },
    )
        .animate()
        .scaleXY(
          begin: 0.4,
          end: 1.0,
          duration: 700.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 500.ms);
  }

  // ── Shimmer name ─────────────────────────────────────────────
  Widget _buildShimmerName() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Colors.white,
                Color(0xFF818CF8),
                Colors.white,
              ],
              stops: [
                _shimmerCtrl.value - 0.3,
                _shimmerCtrl.value,
                _shimmerCtrl.value + 0.3,
              ].map((v) => v.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: Text(
            'EduQuiz',
            style: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -2.0,
            ),
          ),
        );
      },
    )
        .animate(delay: 280.ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  // ── Tagline ──────────────────────────────────────────────────
  Widget _buildTagline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 13, color: Colors.amber.shade300),
          const SizedBox(width: 6),
          Text(
            'AI-Powered Learning Platform',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    )
        .animate(delay: 450.ms)
        .fadeIn(duration: 550.ms)
        .slideY(begin: 0.25, end: 0, duration: 550.ms, curve: Curves.easeOut);
  }

  // ── Bouncing dots ────────────────────────────────────────────
  Widget _buildBouncingDots() {
    final colors = [
      const Color(0xFF818CF8),
      const Color(0xFF7C3AED),
      const Color(0xFF0D9488),
    ];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors[i].withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                  delay: (i * 200).ms,
                )
                .moveY(begin: 0, end: -14, duration: 420.ms,
                    curve: Curves.easeInOut);
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'Getting ready…',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white.withOpacity(0.35),
            letterSpacing: 0.5,
          ),
        ),
      ],
    ).animate(delay: 900.ms).fadeIn(duration: 600.ms);
  }
}

// ── Animated Glow Blob ─────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final AnimationController pulseCtrl;

  const _GlowBlob({
    required this.size,
    required this.color,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) {
        final scale = 0.9 + pulseCtrl.value * 0.2;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.12),
                  color.withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
