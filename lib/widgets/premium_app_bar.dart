import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/theme_controller.dart';

/// Premium gradient app bar with:
///   • Curved wave bottom edge
///   • Glass avatar badge / back button
///   • Optional theme (dark/light) toggle button
class PremiumAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? initials;
  final bool showBack;
  final VoidCallback? onLeadingTap;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;
  final String? tag;
  final Color? tagColor;

  /// Show sun/moon theme-toggle icon in the trailing area
  final bool showThemeToggle;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.initials,
    this.showBack = false,
    this.onLeadingTap,
    this.actionIcon,
    this.onActionTap,
    this.tag,
    this.tagColor,
    this.showThemeToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.appBarGrad),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    // ── Leading ─────────────────────────────────
                    if (showBack)
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        onTap: onLeadingTap ?? () => Navigator.pop(context),
                      )
                    else if (initials != null)
                      _AvatarBadge(initials: initials!)
                    else
                      const SizedBox(width: 4),

                    const SizedBox(width: 12),

                    // ── Title block ──────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (tag != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (tagColor ?? AppTheme.primaryLighter)
                                        .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: (tagColor ?? AppTheme.primaryLighter)
                                          .withOpacity(0.45),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    tag!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: tagColor ?? AppTheme.primaryLighter,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.68),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Theme toggle ─────────────────────────────
                    if (showThemeToggle) ...[
                      const SizedBox(width: 8),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeNotifier,
                        builder: (_, mode, __) => _GlassIconButton(
                          icon: mode == ThemeMode.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 18,
                          onTap: toggleTheme,
                        ),
                      ),
                    ],

                    // ── Action button ────────────────────────────
                    if (actionIcon != null) ...[
                      const SizedBox(width: 8),
                      _GlassIconButton(
                        icon: actionIcon!,
                        onTap: onActionTap ?? () {},
                      ),
                    ],
                  ],
                ),
              ),

              // Extra space carved out by the wave clipper
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: -0.7, end: 0, duration: 380.ms, curve: Curves.easeOut)
        .fadeIn(duration: 380.ms);
  }
}

// ── Wave-curve bottom clipper ─────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start from top-left
    path.lineTo(0, size.height - 22);
    // Gentle convex curve: dips slightly in the center
    path.quadraticBezierTo(
      size.width * 0.5,  // control point x (center)
      size.height + 6,   // control point y (below edge = convex)
      size.width,        // end x
      size.height - 22,  // end y
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveClipper old) => false;
}

// ── Glass icon button ─────────────────────────────────────────────
class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, this.size = 18, required this.onTap});

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _s = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(11),
            border:
                Border.all(color: Colors.white.withOpacity(0.24), width: 1.2),
          ),
          child: Icon(widget.icon, size: widget.size, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Initials avatar badge ─────────────────────────────────────────
class _AvatarBadge extends StatelessWidget {
  final String initials;
  const _AvatarBadge({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.26),
            Colors.white.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.38), width: 1.5),
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}
