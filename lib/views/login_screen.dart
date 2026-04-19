import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_theme.dart';
import 'teacher_screen.dart';
import 'student_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..badCertificateCallback = (_, __, ___) => true;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _inputCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authCtrl     = AuthController();
  bool _obscure = true;

  // ── Fade-in controller ────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Sweeping light controller — continuous loop ───────────────
  late AnimationController _lightCtrl;

  @override
  void initState() {
    super.initState();
    HttpOverrides.global = MyHttpOverrides();
    _authCtrl.addListener(() { if (mounted) setState(() {}); });

    // Page fade-in
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Sweeping light — starts after card appears, loops forever
    _lightCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) _lightCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _passwordCtrl.dispose();
    _authCtrl.dispose();
    _fadeCtrl.dispose();
    _lightCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final input = _inputCtrl.text.trim();
    final pass  = _passwordCtrl.text.trim();
    if (input.isEmpty || pass.isEmpty) {
      _snack('Please fill in all fields');
      return;
    }
    HapticFeedback.lightImpact();
    final ok = await _authCtrl.login(input, pass);
    if (!mounted) return;
    if (ok) {
      final user = _authCtrl.currentUser!;
      Widget dest = user.role == 'teacher'
          ? TeacherScreen(teacherId: user.id, teacherName: user.name)
          : StudentScreen(
        studentName: user.name,
        studentId: user.id,
        rollNo: user.rollNo,
      );
      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => dest,
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 340),
          ));
    } else {
      _snack(_authCtrl.errorMessage ?? 'Login failed');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
      backgroundColor: AppTheme.text1,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.splashGrad
              : const LinearGradient(
            colors: [
              Color(0xFFE8F0FE),
              Color(0xFFD0E4FB),
              Color(0xFFF0F7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Background ambient blobs ──────────────────────
              _blob(top: -90, right: -90, size: 280,
                  color: AppTheme.primary.withOpacity(isDark ? 0.22 : 0.14)),
              _blob(bottom: 40, left: -80, size: 230,
                  color: AppTheme.primaryLighter.withOpacity(isDark ? 0.14 : 0.10)),
              _blob(top: 160, left: -60, size: 180,
                  color: AppTheme.violet.withOpacity(isDark ? 0.08 : 0.05)),

              // ── Main content ──────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildAnimatedCard(),
                        const SizedBox(height: 32),
                        _buildFooter(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ambient blob ─────────────────────────────────────────────
  Widget _blob({double? top, double? bottom, double? left, double? right,
    required double size, required Color color}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.glowShadow(AppTheme.primary),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(top: 12, right: 12,
                  child: Container(width: 14, height: 14,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle))),
              Positioned(bottom: 12, left: 12,
                  child: Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.13),
                          shape: BoxShape.circle))),
              const Icon(Icons.school_rounded, color: Colors.white, size: 40),
            ],
          ),
        )
            .animate()
            .scaleXY(begin: 0.55, end: 1.0,
            duration: 650.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 450.ms),

        const SizedBox(height: 18),

        Text(
          'EduQuiz',
          style: GoogleFonts.outfit(
              fontSize: 36, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.text1,
              letterSpacing: -1.2),
        )
            .animate(delay: 120.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.25, end: 0, duration: 500.ms),

        const SizedBox(height: 5),

        Text(
          'AI-powered evaluation system',
          style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? AppTheme.textOnDark2 : AppTheme.text3),
        )
            .animate(delay: 220.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.2, end: 0, duration: 500.ms),
      ],
    );
  }

  // ── Card wrapped in sweeping light effect ────────────────────
  Widget _buildAnimatedCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Light color: brighter in dark mode, subtle in light mode
    final lightColor = isDark
        ? AppTheme.primaryLighter
        : AppTheme.primary;

    return AnimatedBuilder(
      animation: _lightCtrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _SweepLightPainter(
            progress: _lightCtrl.value,
            radius: 24,
            lightColor: lightColor,
            isDark: isDark,
          ),
          child: child,
        );
      },
      child: _buildLoginCard(),
    )
        .animate(delay: 320.ms)
        .fadeIn(duration: 550.ms)
        .slideY(begin: 0.12, end: 0, duration: 550.ms, curve: Curves.easeOut);
  }

  // ── Login card content ────────────────────────────────────────
  Widget _buildLoginCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: AppTheme.themedCard(context, radius: 24).copyWith(
        boxShadow: isDark
            ? [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 55, offset: const Offset(0, 22)),
          BoxShadow(
              color: AppTheme.primary.withOpacity(0.12),
              blurRadius: 30, offset: const Offset(0, 10)),
        ]
            : [
          const BoxShadow(
              color: Color(0x281565C0),
              blurRadius: 55, offset: Offset(0, 22)),
          const BoxShadow(
              color: Color(0x0E000000),
              blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top gradient accent strip
            Container(
              height: 4,
              decoration: const BoxDecoration(gradient: AppTheme.primaryGrad),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome Back',
                      style: GoogleFonts.outfit(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Sign in to continue to your account',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
                  const SizedBox(height: 22),
                  _buildTextField(
                    controller: _inputCtrl,
                    label: 'Email or Roll Number',
                    hint: 'you@example.com',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildPasswordField(),
                  const SizedBox(height: 20),
                  _buildSignInButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(
          fontSize: 14,
          color: isDark ? AppTheme.darkText1 : AppTheme.text1),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon, size: 18, color: AppTheme.text4),
        ),
        prefixIconConstraints:
        const BoxConstraints(minWidth: 46, minHeight: 46),
        filled: true,
        fillColor: isDark ? AppTheme.darkInput : const Color(0xFFF5F7FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
                width: 1.2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
                width: 1.2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? const Color(0xFF42A5F5) : AppTheme.primary,
                width: 2.0)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.outfit(
            color: isDark ? AppTheme.darkText3 : AppTheme.text3, fontSize: 13),
        hintStyle: GoogleFonts.outfit(
            color: isDark ? AppTheme.darkText4 : AppTheme.text4, fontSize: 13),
      ),
    );
  }

  Widget _buildPasswordField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: _passwordCtrl,
      obscureText: _obscure,
      style: GoogleFonts.outfit(
          fontSize: 14,
          color: isDark ? AppTheme.darkText1 : AppTheme.text1),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.text4),
        ),
        prefixIconConstraints:
        const BoxConstraints(minWidth: 46, minHeight: 46),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18, color: AppTheme.text4,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
          splashRadius: 18,
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkInput : const Color(0xFFF5F7FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
                width: 1.2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
                width: 1.2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? const Color(0xFF42A5F5) : AppTheme.primary,
                width: 2.0)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.outfit(
            color: isDark ? AppTheme.darkText3 : AppTheme.text3, fontSize: 13),
        hintStyle: GoogleFonts.outfit(
            color: isDark ? AppTheme.darkText4 : AppTheme.text4, fontSize: 13),
      ),
    );
  }

  Widget _buildSignInButton() {
    return _TapScaleButton(
      onTap: _authCtrl.isLoading ? null : _login,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppTheme.heroGrad,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.glowShadow(AppTheme.primary),
        ),
        child: Center(
          child: _authCtrl.isLoading
              ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Sign In',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white, letterSpacing: 0.4)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
        const SizedBox(height: 16),
        Text(
          '© ${DateTime.now().year} EduQuiz. All rights reserved.',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: isDark ? AppTheme.darkText4 : AppTheme.text4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate(delay: 500.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildRoleBadges() => const SizedBox.shrink();
}

// ═══════════════════════════════════════════════════════════════
// Sweeping light painter — draws a glowing arc that travels
// around the card border in a continuous loop
// ═══════════════════════════════════════════════════════════════
class _SweepLightPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 (full revolution)
  final double radius;   // border radius of the card
  final Color lightColor;
  final bool isDark;

  _SweepLightPainter({
    required this.progress,
    required this.radius,
    required this.lightColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = radius;

    // Total perimeter of the rounded rect (approximation)
    final perimeter = 2 * (w + h) - (8 - 2 * math.pi) * r;

    // Arc length of the glowing head
    final headLen = perimeter * 0.18;
    // Tail fades out over this length
    final tailLen = perimeter * 0.30;

    // Current position of the light head along the perimeter
    final headPos = progress * perimeter;

    // Build a rounded-rect path
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(r),
    );
    final borderPath = Path()..addRRect(rrect);

    // We draw multiple semi-transparent strokes to simulate a soft glow
    // Outer glow (wide, faint)
    _drawArcOnPerimeter(canvas, borderPath, perimeter,
        headPos, headLen, tailLen,
        color: lightColor,
        strokeWidth: isDark ? 14.0 : 10.0,
        maxOpacity: isDark ? 0.28 : 0.18);

    // Mid glow
    _drawArcOnPerimeter(canvas, borderPath, perimeter,
        headPos, headLen * 0.7, tailLen * 0.6,
        color: lightColor,
        strokeWidth: isDark ? 7.0 : 5.0,
        maxOpacity: isDark ? 0.55 : 0.38);

    // Bright core
    _drawArcOnPerimeter(canvas, borderPath, perimeter,
        headPos, headLen * 0.3, tailLen * 0.25,
        color: Colors.white,
        strokeWidth: isDark ? 3.0 : 2.2,
        maxOpacity: isDark ? 0.90 : 0.75);
  }

  /// Draws a fading arc segment along the path's perimeter.
  void _drawArcOnPerimeter(
      Canvas canvas,
      Path path,
      double perimeter,
      double headPos,
      double arcLen,
      double fadeLen, {
        required Color color,
        required double strokeWidth,
        required double maxOpacity,
      }) {
    final metrics = path.computeMetrics().first;

    // Number of small segments to approximate the gradient fade
    const segments = 40;
    final totalLen = arcLen + fadeLen;

    for (int i = 0; i < segments; i++) {
      final t = i / segments;
      final segStart = headPos - totalLen + t * totalLen;
      final segEnd   = headPos - totalLen + (i + 1) / segments * totalLen;

      // Wrap around perimeter
      final s = ((segStart % perimeter) + perimeter) % perimeter;
      final e = ((segEnd   % perimeter) + perimeter) % perimeter;

      // Opacity: 0 at tail, peaks at head
      double opacity;
      final distFromHead = headPos - (segStart + (segEnd - segStart) / 2);
      if (distFromHead <= arcLen) {
        // Bright head zone
        opacity = maxOpacity * (1.0 - (distFromHead / arcLen) * 0.3);
      } else {
        // Fading tail
        final fadeFraction = (distFromHead - arcLen) / fadeLen;
        opacity = maxOpacity * 0.7 * (1.0 - fadeFraction);
      }
      opacity = opacity.clamp(0.0, maxOpacity);
      if (opacity <= 0.01) continue;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Extract the segment
      Path segPath;
      if (s <= e) {
        segPath = metrics.extractPath(s, e);
      } else {
        // Wraps around
        final p1 = metrics.extractPath(s, perimeter);
        final p2 = metrics.extractPath(0, e);
        segPath = Path()..addPath(p1, Offset.zero)..addPath(p2, Offset.zero);
      }
      canvas.drawPath(segPath, paint);
    }
  }

  @override
  bool shouldRepaint(_SweepLightPainter old) => old.progress != progress;
}

// ── Tap-scale micro-interaction ───────────────────────────────────
class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TapScaleButton({required this.child, this.onTap});
  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.965)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s, child: widget.child),
    );
  }
}

// ── Role badge (kept for compatibility) ───────────────────────────
class _RoleBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bg, borderColor;
  const _RoleBadge({
    required this.icon, required this.label,
    required this.color, required this.bg, required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}