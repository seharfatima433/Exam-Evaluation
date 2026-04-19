import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// EduQuiz Premium Design System v3 — Light + Dark
class AppTheme {
  // ── Brand Palette ─────────────────────────────────────────────
  static const Color primary       = Color(0xFF1565C0);
  static const Color primaryLight  = Color(0xFF1E88E5);
  static const Color primaryLighter= Color(0xFF42A5F5);
  static const Color primaryDark   = Color(0xFF0D47A1);
  static const Color primaryBg     = Color(0xFFE3F2FD);
  static const Color primaryLight2 = Color(0xFFBBDEFB);

  static const Color green         = Color(0xFF00BFA5);
  static const Color greenDark     = Color(0xFF00897B);
  static const Color greenBg       = Color(0xFFE0F2F1);
  static const Color greenLight    = Color(0xFFB2DFDB);
  static const Color success       = Color(0xFF00897B);

  static const Color amber         = Color(0xFFFFB300);
  static const Color amberBg       = Color(0xFFFFF8E1);
  static const Color amberLight    = Color(0xFFFFECB3);

  static const Color red           = Color(0xFFD32F2F);
  static const Color redBg         = Color(0xFFFFEBEE);
  static const Color redLight      = Color(0xFFFFCDD2);

  static const Color violet        = Color(0xFF6A1B9A);
  static const Color violetMid     = Color(0xFF7B1FA2);
  static const Color violetBg      = Color(0xFFF3E5F5);
  static const Color violetLight   = Color(0xFFE1BEE7);

  static const Color teal          = Color(0xFF00838F);
  static const Color tealBg        = Color(0xFFE0F7FA);

  // ── Light Neutrals ────────────────────────────────────────────
  static const Color bg            = Color(0xFFF0F4FF);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceAlt    = Color(0xFFF8FAFF);
  static const Color border        = Color(0xFFDDE3F0);
  static const Color borderMid     = Color(0xFFB8C4D8);
  static const Color divider       = Color(0xFFECF0FB);

  // ── Dark Neutrals ─────────────────────────────────────────────
  static const Color darkBg        = Color(0xFF06101E);
  static const Color darkSurface   = Color(0xFF0D1E3A);
  static const Color darkSurfaceAlt= Color(0xFF0A1830);
  static const Color darkBorder    = Color(0xFF1A3355);
  static const Color darkDivider   = Color(0xFF1A3355);
  static const Color darkInput     = Color(0xFF0F2040);

  // ── Splash / Login background ──────────────────────────────────
  static const Color dark1         = Color(0xFF080E1C);
  static const Color dark2         = Color(0xFF0D1B35);
  static const Color dark3         = Color(0xFF122B55);

  // ── Text ──────────────────────────────────────────────────────
  static const Color text1         = Color(0xFF0D1B35);
  static const Color text2         = Color(0xFF263A58);
  static const Color text3         = Color(0xFF5C7597);
  static const Color text4         = Color(0xFF9DB0C8);
  static const Color textOnDark    = Color(0xFFEAF1FF);
  static const Color textOnDark2   = Color(0xFF8AAFD4);

  // Dark-mode text
  static const Color darkText1     = Color(0xFFEAF1FF);
  static const Color darkText2     = Color(0xFFB8D0F0);
  static const Color darkText3     = Color(0xFF8AAFD4);
  static const Color darkText4     = Color(0xFF5C7597);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient primaryGradDeep = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient appBarGrad = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
  static const LinearGradient heroGrad = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient splashGrad = LinearGradient(
    colors: [Color(0xFF050C1A), Color(0xFF0A1628), Color(0xFF0D2040), Color(0xFF112B5A)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient greenGrad = LinearGradient(
    colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF00BFA5)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient accentGrad = LinearGradient(
    colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient violetGrad = LinearGradient(
    colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ── Light ThemeData ───────────────────────────────────────────
  static ThemeData get theme => _buildTheme(Brightness.light);

  // ── Dark ThemeData ────────────────────────────────────────────
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final base = ThemeData(
      useMaterial3: false,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? darkBg : bg,
      cardColor: isDark ? darkSurface : surface,
      dividerColor: isDark ? darkDivider : divider,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: Color(0xFF2196F3),
              secondary: Color(0xFF00BFA5),
              error: Color(0xFFEF5350),
              background: darkBg,
              surface: darkSurface,
            )
          : const ColorScheme.light(
              primary: primary,
              secondary: green,
              error: red,
              background: bg,
              surface: surface,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: Colors.white, letterSpacing: 0.1,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF2196F3) : primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkInput : const Color(0xFFF5F7FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.outfit(
            color: isDark ? darkText3 : text3, fontSize: 13),
        hintStyle: GoogleFonts.outfit(
            color: isDark ? darkText4 : text4, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? darkBorder : border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? darkBorder : border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? const Color(0xFF2196F3) : primary, width: 2.0),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? darkSurface : surface,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? const Color(0xFF2196F3) : primary,
        linearTrackColor: isDark ? darkBorder : primaryBg,
        circularTrackColor: isDark ? darkBorder : primaryBg,
      ),
    );

    final darkTextBase = base.textTheme.apply(
      bodyColor: darkText2,
      displayColor: darkText1,
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(isDark ? darkTextBase : base.textTheme)
          .copyWith(
        headlineLarge: GoogleFonts.outfit(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: isDark ? darkText1 : text1, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.outfit(
            fontSize: 19, fontWeight: FontWeight.w700,
            color: isDark ? darkText1 : text1, letterSpacing: -0.4),
        headlineSmall: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: isDark ? darkText1 : text1, letterSpacing: -0.2),
        bodyLarge: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? darkText2 : text2, height: 1.55),
        bodyMedium: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? darkText2 : text2, height: 1.55),
        labelLarge: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    );
  }

  // ── Card decorations ──────────────────────────────────────────
  static BoxDecoration card({Color? borderColor, double radius = 14, Color? backgroundColor}) =>
      BoxDecoration(
        color: backgroundColor ?? surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? border, width: 1.0),
        boxShadow: const [
          BoxShadow(color: Color(0x0B1565C0), blurRadius: 18, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x04000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      );

  /// Theme-aware card — pass context to auto-pick light/dark
  static BoxDecoration themedCard(BuildContext ctx, {double radius = 14, Color? borderColor}) {
    final dark = Theme.of(ctx).brightness == Brightness.dark;
    return BoxDecoration(
      color: dark ? darkSurface : surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: dark ? darkBorder : border, width: 1.0),
      boxShadow: dark
          ? [
              BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ]
          : const [
              BoxShadow(
                  color: Color(0x0B1565C0), blurRadius: 18, offset: Offset(0, 6)),
              BoxShadow(
                  color: Color(0x04000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
    );
  }

  static BoxDecoration cardElevated({Color? borderColor}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? border, width: 1.0),
        boxShadow: const [
          BoxShadow(color: Color(0x161565C0), blurRadius: 44, offset: Offset(0, 18)),
          BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      );

  static BoxDecoration glassCard({double radius = 16, Color? borderColor}) =>
      BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.20), width: 1.2),
      );

  static BoxDecoration pill(Color bgColor, Color borderColor) => BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 1),
      );

  static BoxDecoration pillRect(Color bgColor, Color borderColor,
          {double radius = 8}) =>
      BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
      );

  static List<BoxShadow> glowShadow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withOpacity(0.28 * intensity),
          blurRadius: 32, offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: color.withOpacity(0.10 * intensity),
          blurRadius: 6, offset: const Offset(0, 3),
        ),
      ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x0D1565C0), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// Convenience: is dark mode currently active?
  static bool isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  /// Resolve a light/dark color based on current theme
  static Color resolve(BuildContext ctx, Color light, Color dark) =>
      isDark(ctx) ? dark : light;
}
