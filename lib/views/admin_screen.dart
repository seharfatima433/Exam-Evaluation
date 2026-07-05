import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';
import 'login_screen.dart';
import '../services/fcm_sender_service.dart';

// Safe int parser — handles String "5" and int 5 from API
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

// ═══════════════════════════════════════════════════════════
// ADMIN DASHBOARD — bottom nav only (no top TabBar)
// Tab 1 — Add Teacher
// Tab 2 — Assign Courses
// Tab 3 — Enroll Student
// ═══════════════════════════════════════════════════════════
class AdminDashboard extends StatefulWidget {
  final String adminName;
  const AdminDashboard({super.key, this.adminName = 'Admin'});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _tabTitle {
    switch (_currentIndex) {
      case 1: return 'Add Teacher';
      case 2: return 'Assign Courses';
      case 3: return 'Enroll Student';
      default: return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isDesktop ? null : Drawer(
        child: Builder(
          builder: (ctx) => _buildSidebar(ctx, isDark),
        ),
      ),
      body: Column(
        children: [
          // ── Premium App Bar (mobile only) ──────────────────
          if (!isDesktop)
            PremiumAppBar(
              title: 'Admin Panel',
              subtitle: widget.adminName,
              initials: widget.adminName.isNotEmpty
                  ? widget.adminName[0].toUpperCase()
                  : 'A',
              onLeadingTap: () => _scaffoldKey.currentState?.openDrawer(),
              actionIcon: Icons.menu_rounded,
              onActionTap: () => _scaffoldKey.currentState?.openDrawer(),
              showThemeToggle: true,
            ),
          Expanded(
            child: Row(
              children: [
                if (isDesktop) _buildSidebar(context, isDark),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _DashboardTab(onNavigate: (index) => setState(() => _currentIndex = index)),
                      const _AddTeacherTab(),
                      const _AssignCoursesTab(),
                      const _EnrollStudentTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 20,
            offset: const Offset(4, 0),
          )
        ],
      ),
      child: Column(
        children: [
          // ── Premium sidebar header — same wave gradient as PremiumAppBar ──
          Stack(
            children: [
              // Shadow underline layer
              ClipPath(
                clipper: const _SidebarWave(offsetY: 3),
                child: Container(
                  height: 120 + MediaQuery.of(context).padding.top,
                  color: Colors.black.withOpacity(0.08),
                ),
              ),
              // Gradient layer
              ClipPath(
                clipper: const _SidebarWave(),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 22,
                    bottom: 28,
                    left: 20,
                    right: 16,
                  ),
                  decoration: const BoxDecoration(gradient: AppTheme.appBarGrad),
                  child: Row(
                    children: [
                      // Avatar badge
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.30), width: 1.2),
                        ),
                        child: Center(
                          child: Text(
                            widget.adminName.isNotEmpty
                                ? widget.adminName[0].toUpperCase()
                                : 'A',
                            style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.adminName,
                              style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                              ),
                              child: Text(
                                'Admin Panel',
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarItem(context, 0, Icons.dashboard_rounded, 'Dashboard', isDark),
                const SizedBox(height: 8),
                _sidebarItem(context, 1, Icons.person_add_rounded, 'Add Teacher', isDark),
                const SizedBox(height: 8),
                _sidebarItem(context, 2, Icons.book_rounded, 'Assign Courses', isDark),
                const SizedBox(height: 8),
                _sidebarItem(context, 3, Icons.assignment_turned_in_rounded, 'Enroll Student', isDark),
              ],
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _confirmLogout(context);
              },
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.redBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: AppTheme.red, size: 18),
                    const SizedBox(width: 8),
                    Text('Logout',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.red)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, int index, IconData icon, String label, bool isDark) {
    final selected = _currentIndex == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
        // If drawer is open on mobile, close it
        if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20,
                color: selected
                    ? AppTheme.primary
                    : (isDark ? AppTheme.darkText3 : AppTheme.text3)),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppTheme.primary
                      : (isDark ? AppTheme.darkText2 : AppTheme.text2),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar wave-curve clipper (mirrors PremiumAppBar wave) ───────
class _SidebarWave extends CustomClipper<Path> {
  final double offsetY;
  const _SidebarWave({this.offsetY = 0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 18 + offsetY);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 8 + offsetY,
      size.width,
      size.height - 18 + offsetY,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _SidebarWave old) => old.offsetY != offsetY;
}

// ── Dashboard Tab (Analytics) ───────────────────────────────
class _DashboardTab extends StatefulWidget {
  final Function(int) onNavigate;
  const _DashboardTab({super.key, required this.onNavigate});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _loading = true;
  int _totalStudents = 0;
  int _totalCourses = 0;
  int _totalTeachers = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConstants.baseUrl}/admin/students'), headers: {'Accept': 'application/json'}),
        http.get(Uri.parse('${ApiConstants.baseUrl}/admin/courses'), headers: {'Accept': 'application/json'}),
        http.get(Uri.parse('${ApiConstants.baseUrl}/admin/teachers'), headers: {'Accept': 'application/json'}),
      ]);

      final studentsData = jsonDecode(responses[0].body);
      final coursesData = jsonDecode(responses[1].body);
      final teachersData = jsonDecode(responses[2].body);

      final studentsList = studentsData is List ? studentsData : (studentsData['students'] ?? studentsData['data'] ?? []);
      final coursesList = coursesData is List ? coursesData : (coursesData['courses'] ?? coursesData['data'] ?? []);
      final teachersList = teachersData is List ? teachersData : (teachersData['teachers'] ?? teachersData['data'] ?? []);

      if (mounted) {
        setState(() {
          _totalStudents = studentsList.length;
          _totalCourses = coursesList.length;
          _totalTeachers = teachersList.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Welcome Banner ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGrad,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.glowShadow(AppTheme.primary, intensity: 0.5),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -40,
                  child: Icon(Icons.auto_awesome_rounded, 
                    size: 160, 
                    color: Colors.white.withOpacity(0.1)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back, Admin!',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        )),
                    const SizedBox(height: 8),
                    Text('Here is your system overview for today.',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.85),
                        )),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 8),
                          Text(DateTime.now().toString().split(' ')[0],
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fade().slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic, duration: 600.ms),
          
          const SizedBox(height: 40),

          // ── Statistics Section ──────────────────────────────────
          Text('Key Metrics',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText1 : AppTheme.text1,
              )).animate().fade(delay: 100.ms).slideX(begin: -0.05, end: 0),
          const SizedBox(height: 16),
          
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
                double aspectRatio = constraints.maxWidth > 800 ? 1.0 : 0.85; // slightly taller on mobile to prevent overflow
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                  children: [
                    _buildSquareCard(
                      title: 'Total Students',
                      value: _totalStudents.toString(),
                      icon: Icons.school_rounded,
                      color: AppTheme.primary,
                      trendText: '+12%',
                      trendUp: true,
                      isDark: isDark,
                    ),
                    _buildSquareCard(
                      title: 'Active Courses',
                      value: _totalCourses.toString(),
                      icon: Icons.book_rounded,
                      color: AppTheme.amber,
                      trendText: '+3',
                      trendUp: true,
                      isDark: isDark,
                    ),
                    _buildSquareCard(
                      title: 'Teachers',
                      value: _totalTeachers.toString(),
                      icon: Icons.person_rounded,
                      color: AppTheme.green,
                      trendText: 'Stable',
                      trendUp: true,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildSquareCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trendText,
    required bool trendUp,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendUp 
                      ? (isDark ? AppTheme.green.withOpacity(0.15) : AppTheme.greenBg)
                      : (isDark ? AppTheme.red.withOpacity(0.15) : AppTheme.redBg),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 10,
                      color: trendUp ? AppTheme.green : AppTheme.red,
                    ),
                    const SizedBox(width: 2),
                    Text(trendText, 
                      style: GoogleFonts.outfit(
                        fontSize: 10, 
                        fontWeight: FontWeight.w700, 
                        color: trendUp ? AppTheme.green : AppTheme.red,
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(value,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                    height: 1.1,
                  )
                ),
                const SizedBox(height: 2),
                Text(title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                  )
                ),
              ]
            ),
          )
        ],
      ),
    );
  }

}

// ── Logout dialog ─────────────────────────────────────────
void _confirmLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Theme.of(context).cardColor,
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: AppTheme.redBg,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.logout_rounded,
              size: 18, color: AppTheme.red),
        ),
        const SizedBox(width: 12),
        Text('Logout',
            style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkText1
                    : AppTheme.text1)),
      ]),
      content: Text('Are you sure you want to logout?',
          style: GoogleFonts.outfit(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkText3
                  : AppTheme.text3)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkText3
                      : AppTheme.text3,
                  fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            // Clear login session
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('user_session');
            await FCMSenderService.clearFCMData();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, a, __) => const LoginScreen(),
                  transitionsBuilder: (_, a, __, child) =>
                      FadeTransition(opacity: a, child: child),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
                    (route) => false,
              );
            }
          },
          child: Text('Logout',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.red,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// TAB 1 — ADD TEACHER
// POST /admin/add-teacher  { name, email, password }
// ═══════════════════════════════════════════════════════════
class _AddTeacherTab extends StatefulWidget {
  const _AddTeacherTab();
  @override
  State<_AddTeacherTab> createState() => _AddTeacherTabState();
}

class _AddTeacherTabState extends State<_AddTeacherTab> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading     = false;
  bool _passVisible = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/admin/add-teacher'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name':     _nameCtrl.text.trim(),
          'email':    _emailCtrl.text.trim(),
          'password': _passCtrl.text.trim(),
        }),
      ).timeout(ApiConstants.timeout);

      final data = jsonDecode(res.body);

      if (data['status'] == true) {
        _nameCtrl.clear();
        _emailCtrl.clear();
        _passCtrl.clear();
        _snack('Teacher added successfully!', success: true);
      } else {
        String msg = data['message'] ?? 'Something went wrong';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          msg = (errors.values.first as List).first.toString();
        }
        _snack(msg);
      }
    } catch (e) {
      _snack('Network error: $e');
    }

    setState(() => _loading = false);
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
      backgroundColor: success ? AppTheme.green : AppTheme.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Teacher',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                    letterSpacing: -0.4)),
            const SizedBox(height: 6),
            Text('Create a teacher account',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.themedCard(context, radius: 16),
              child: Column(children: [
                _field(ctrl: _nameCtrl, label: 'Full Name',
                    hint: 'e.g. Dr. Ali Hassan',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v!.trim().isEmpty ? 'Name required' : null),
                const SizedBox(height: 14),
                _field(ctrl: _emailCtrl, label: 'Email',
                    hint: 'teacher@example.com',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Email required';
                      if (!v.contains('@')) return 'Enter valid email';
                      return null;
                    }),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_passVisible,
                  style: GoogleFonts.outfit(fontSize: 14,
                      color: isDark ? AppTheme.darkText1 : AppTheme.text1),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Min. 8 characters',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.lock_outline_rounded,
                          size: 18, color: AppTheme.text4),
                    ),
                    prefixIconConstraints:
                    const BoxConstraints(minWidth: 46, minHeight: 46),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18, color: AppTheme.text4,
                      ),
                      onPressed: () =>
                          setState(() => _passVisible = !_passVisible),
                      splashRadius: 18,
                    ),
                    filled: true,
                    fillColor:
                    isDark ? AppTheme.darkInput : const Color(0xFFF5F7FF),
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
                            color: isDark
                                ? const Color(0xFF42A5F5)
                                : AppTheme.primary,
                            width: 2.0)),
                    labelStyle: GoogleFonts.outfit(
                        color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                        fontSize: 13),
                    hintStyle: GoogleFonts.outfit(
                        color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                        fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Password required' : null,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      onTap: _loading ? null : _addTeacher,
                      borderRadius: BorderRadius.circular(13),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: _loading ? null : AppTheme.heroGrad,
                          color: _loading
                              ? (isDark ? AppTheme.darkInput : AppTheme.bg)
                              : null,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: _loading
                              ? null
                              : AppTheme.glowShadow(AppTheme.primary),
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppTheme.primary)))
                              : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_add_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('Add Teacher',
                                    style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.outfit(fontSize: 14,
          color: isDark ? AppTheme.darkText1 : AppTheme.text1),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
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
        labelStyle: GoogleFonts.outfit(
            color: isDark ? AppTheme.darkText3 : AppTheme.text3, fontSize: 13),
        hintStyle: GoogleFonts.outfit(
            color: isDark ? AppTheme.darkText4 : AppTheme.text4, fontSize: 13),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 2 — ASSIGN COURSES TO TEACHER
// GET  /admin/teachers
// GET  /admin/courses
// POST /admin/assign-courses { teacher_id, course_ids:[...] }
// ═══════════════════════════════════════════════════════════
class _AssignCoursesTab extends StatefulWidget {
  const _AssignCoursesTab();
  @override
  State<_AssignCoursesTab> createState() => _AssignCoursesTabState();
}

class _AssignCoursesTabState extends State<_AssignCoursesTab> {
  List<dynamic> _teachers          = [];
  List<dynamic> _courses           = [];
  int?          _selectedTeacherId;
  List<int>     _selectedCourseIds = [];
  bool          _loadingData       = true;
  bool          _assigning         = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final tRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/teachers'),
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConstants.timeout);

      final cRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/courses'),
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConstants.timeout);

      final tData = jsonDecode(tRes.body);
      final cData = jsonDecode(cRes.body);

      setState(() {
        _teachers = tData['teachers'] ?? [];
        _courses  = cData['courses']  ?? [];
        if (_selectedTeacherId != null) {
          final stillExists =
          _teachers.any((t) => _toInt(t['id']) == _selectedTeacherId);
          if (!stillExists) _selectedTeacherId = null;
        }
      });
    } catch (e) {
      _snack('Failed to load data: $e');
    }
    setState(() => _loadingData = false);
  }

  Future<void> _assignCourses() async {
    if (_selectedTeacherId == null) {
      _snack('Please select a teacher', warning: true); return;
    }
    if (_selectedCourseIds.isEmpty) {
      _snack('Please select at least one course', warning: true); return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _assigning = true);

    final teacher = _teachers.firstWhere(
            (t) => _toInt(t['id']) == _selectedTeacherId,
        orElse: () => {'name': 'Teacher'});

    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/admin/assign-courses'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'teacher_id': _selectedTeacherId,
          'course_ids': _selectedCourseIds,
        }),
      ).timeout(ApiConstants.timeout);

      final data = jsonDecode(res.body);
      if (data['status'] == true) {
        final count = _selectedCourseIds.length;
        setState(() => _selectedCourseIds = []);
        _snack('$count course(s) assigned to ${teacher['name']}!',
            success: true);
        _loadData();
      } else {
        _snack(data['message'] ?? 'Failed to assign');
      }
    } catch (e) {
      _snack('Network error: $e');
    }
    setState(() => _assigning = false);
  }

  void _snack(String msg, {bool success = false, bool warning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
      backgroundColor:
      success ? AppTheme.green : warning ? AppTheme.amber : AppTheme.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingData) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            strokeWidth: 2.5),
        const SizedBox(height: 12),
        Text('Loading…', style: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Assign Courses',
              style: GoogleFonts.outfit(fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                  letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text('Select teacher then assign courses',
              style: GoogleFonts.outfit(fontSize: 13,
                  color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
          const SizedBox(height: 24),

          // Teacher dropdown
          Container(
            decoration: AppTheme.themedCard(context, radius: 14),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Teacher',
                      style: GoogleFonts.outfit(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                          letterSpacing: 0.2)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkInput : const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                          width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: Text('Choose a teacher',
                            style: GoogleFonts.outfit(fontSize: 13,
                                color: isDark ? AppTheme.darkText4 : AppTheme.text4)),
                        value: _selectedTeacherId,
                        dropdownColor:
                        isDark ? AppTheme.darkSurface : AppTheme.surface,
                        items: _teachers.map((t) => DropdownMenuItem<int>(
                          value: _toInt(t['id']),
                          child: Text('${t['name']}  •  ${t['email']}',
                              style: GoogleFonts.outfit(fontSize: 13,
                                  color: isDark ? AppTheme.darkText1 : AppTheme.text1),
                              overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (val) => setState(() {
                          _selectedTeacherId = val;
                          _selectedCourseIds = [];
                        }),
                      ),
                    ),
                  ),
                ]),
          ),
          const SizedBox(height: 16),

          // Courses checklist
          Container(
            decoration: AppTheme.themedCard(context, radius: 14),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text('Select Courses',
                        style: GoogleFonts.outfit(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                            letterSpacing: 0.2))),
                    if (_selectedCourseIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppTheme.primaryBg,
                            borderRadius: BorderRadius.circular(50)),
                        child: Text('${_selectedCourseIds.length} selected',
                            style: GoogleFonts.outfit(fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  _courses.isEmpty
                      ? Center(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('No courses found',
                          style: GoogleFonts.outfit(fontSize: 13,
                              color: isDark
                                  ? AppTheme.darkText3
                                  : AppTheme.text3))))
                      : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final course    = _courses[i];
                      final courseId  = _toInt(course['id']);
                      final isSelected = _selectedCourseIds.contains(courseId);
                      final assignedTeacher = course['teacher'];

                      return GestureDetector(
                        onTap: () => setState(() => isSelected
                            ? _selectedCourseIds.remove(courseId)
                            : _selectedCourseIds.add(courseId)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBg
                                : (isDark
                                ? AppTheme.darkInput
                                : const Color(0xFFF5F7FF)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary.withOpacity(0.5)
                                  : (isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.border),
                              width: isSelected ? 1.5 : 1.2,
                            ),
                          ),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : (isDark
                                        ? AppTheme.darkBorder
                                        : AppTheme.borderMid),
                                    width: 1.5),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(course['course_title'] ?? '',
                                    style: GoogleFonts.outfit(fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppTheme.darkText1
                                            : AppTheme.text1)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  Text('Code: ${course['course_code'] ?? ''}',
                                      style: GoogleFonts.outfit(fontSize: 11,
                                          color: isDark
                                              ? AppTheme.darkText3
                                              : AppTheme.text3)),
                                  if (assignedTeacher != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                          color: AppTheme.greenBg,
                                          borderRadius:
                                          BorderRadius.circular(4)),
                                      child: Text(assignedTeacher['name'],
                                          style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              color: AppTheme.greenDark,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ] else ...[
                                    const SizedBox(width: 8),
                                    Text('Unassigned',
                                        style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            color: isDark
                                                ? AppTheme.darkText4
                                                : AppTheme.text4)),
                                  ],
                                ]),
                              ],
                            )),
                          ]),
                        ),
                      );
                    },
                  ),
                ]),
          ),
          const SizedBox(height: 20),

          // Assign button
          SizedBox(
            width: double.infinity, height: 50,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: _assigning ? null : _assignCourses,
                borderRadius: BorderRadius.circular(13),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _assigning ? null : AppTheme.heroGrad,
                    color: _assigning
                        ? (isDark ? AppTheme.darkInput : AppTheme.bg)
                        : null,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: _assigning
                        ? null
                        : AppTheme.glowShadow(AppTheme.primary),
                  ),
                  child: Center(
                    child: _assigning
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(
                                AppTheme.primary)))
                        : Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_turned_in_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Assign Courses',
                              style: GoogleFonts.outfit(fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ]),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 3 — ENROLL STUDENT
// GET  /admin/students/{user_id}         ← NEW: name + roll no
// GET  /admin/student-courses/{user_id}
// POST /admin/assign-course
// POST /admin/remove-student-course
// GET  /admin/courses
// ═══════════════════════════════════════════════════════════
class _EnrollStudentTab extends StatefulWidget {
  const _EnrollStudentTab();
  @override
  State<_EnrollStudentTab> createState() => _EnrollStudentTabState();
}

class _EnrollStudentTabState extends State<_EnrollStudentTab> {
  final _formKey    = GlobalKey<FormState>();
  final _userIdCtrl = TextEditingController();

  List<dynamic> _courses         = [];
  int?          _selectedCourseId;
  List<dynamic> _enrolledCourses = [];

  List<dynamic> _students        = [];
  bool          _loadingStudents = true;

  // ── Student info ─────────────────────────────────────────
  String? _studentName;
  String? _studentRollNo;
  bool    _loadingStudent = false;
  // ─────────────────────────────────────────────────────────

  bool _loadingCourses  = true;
  bool _loadingEnrolled = false;
  bool _enrolling       = false;
  bool _removing        = false;

  int? get _userId => int.tryParse(_userIdCtrl.text.trim());

  @override
  void initState() { super.initState(); _loadCourses(); _loadStudents(); }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/students'),
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConstants.timeout);
      final raw = jsonDecode(res.body);
      final list = raw is List ? raw : (raw['students'] ?? raw['data'] ?? raw['users'] ?? []);
      if (mounted) setState(() => _students = list as List);
    } catch (e) {
      if (mounted) _snack('Failed to load students: $e');
    }
    if (mounted) setState(() => _loadingStudents = false);
  }

  @override
  void dispose() { _userIdCtrl.dispose(); super.dispose(); }

  Future<void> _loadCourses() async {
    setState(() => _loadingCourses = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/courses'),
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConstants.timeout);
      final data = jsonDecode(res.body);
      if (mounted) setState(() => _courses = data['courses'] ?? []);
    } catch (e) {
      if (mounted) _snack('Failed to load courses: $e');
    }
    if (mounted) setState(() => _loadingCourses = false);
  }

  // GET /admin/students/{user_id} — name + roll no fetch
  Future<void> _loadStudentInfo() async {
    if (_userId == null) return;
    setState(() {
      _loadingStudent = true;
      _studentName    = null;
      _studentRollNo  = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/students/$_userId'),
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConstants.timeout);

      final raw = jsonDecode(res.body);

      // status/data/user/student wrapper support
      final student = raw is Map
          ? (raw['student'] ?? raw['data'] ?? raw['user'] ?? raw)
          : null;

      if (mounted && student != null && student['name'] != null) {
        setState(() {
          _studentName   = student['name']?.toString();
          _studentRollNo = (student['roll_no'] ??
              student['rollno']  ??
              student['roll_number'])?.toString();
        });
      } else {
        if (mounted) _snack('Student not found', warning: true);
      }
    } catch (e) {
      if (mounted) _snack('Error loading student: $e');
    }
    if (mounted) setState(() => _loadingStudent = false);
  }

  // GET /admin/student-courses/{user_id}
  Future<void> _loadEnrolled() async {
    if (_userId == null) return;
    setState(() { _loadingEnrolled = true; _enrolledCourses = []; });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/student-courses/$_userId'),
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConstants.timeout);
      final raw  = jsonDecode(res.body);
      final list = raw is List ? raw : (raw['courses'] ?? raw['data'] ?? []);
      if (mounted) setState(() => _enrolledCourses = list as List);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
    if (mounted) setState(() => _loadingEnrolled = false);
  }

  // POST /admin/assign-course
  Future<void> _enroll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      _snack('Please select a course', warning: true); return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _enrolling = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/admin/assign-course'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id':   _userId,
          'course_id': _selectedCourseId,
        }),
      ).timeout(ApiConstants.timeout);

      final data = jsonDecode(res.body);
      if (data['status'] == true ||
          res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _selectedCourseId = null);
        _snack('Student enrolled successfully!', success: true);
        _loadEnrolled();
      } else {
        _snack(data['message'] ?? 'Enrollment failed (${res.statusCode})');
      }
    } catch (e) {
      _snack('Network error: $e');
    }
    if (mounted) setState(() => _enrolling = false);
  }

  // POST /admin/remove-student-course
  Future<void> _removeCourse(int courseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Remove Course?',
            style: GoogleFonts.outfit(fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkText1 : AppTheme.text1)),
        content: Text('Remove this course from the student?',
            style: GoogleFonts.outfit(fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkText3 : AppTheme.text3)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('Remove',
                  style: GoogleFonts.outfit(
                      color: AppTheme.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _removing = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/admin/remove-student-course'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id':   _userId,
          'course_id': courseId,
        }),
      ).timeout(ApiConstants.timeout);

      final data = jsonDecode(res.body);
      if (data['status'] == true ||
          res.statusCode == 200 || res.statusCode == 201) {
        _snack('Course removed', success: true);
        _loadEnrolled();
      } else {
        _snack(data['message'] ?? 'Remove failed (${res.statusCode})');
      }
    } catch (e) {
      _snack('Network error: $e');
    }
    if (mounted) setState(() => _removing = false);
  }

  void _snack(String msg, {bool success = false, bool warning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
      backgroundColor:
      success ? AppTheme.green : warning ? AppTheme.amber : AppTheme.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enroll Student',
              style: GoogleFonts.outfit(fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                  letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text('Enter student ID and assign a course',
              style: GoogleFonts.outfit(fontSize: 13,
                  color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
          const SizedBox(height: 24),

          Container(
            decoration: AppTheme.themedCard(context, radius: 14),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Student Search Dropdown
                  Text('Search Student',
                      style: GoogleFonts.outfit(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                          letterSpacing: 0.2)),
                  const SizedBox(height: 10),
                  _loadingStudents
                      ? const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(AppTheme.primary))))
                      : LayoutBuilder(
                          builder: (context, constraints) => DropdownMenu<int>(
                            width: constraints.maxWidth,
                            enableFilter: true,
                            enableSearch: true,
                            requestFocusOnTap: true,
                            hintText: 'Search by name or roll no...',
                            leadingIcon: Icon(Icons.search, size: 18, color: AppTheme.text4),
                            textStyle: GoogleFonts.outfit(
                                fontSize: 14, color: isDark ? AppTheme.darkText1 : AppTheme.text1),
                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: isDark
                                  ? AppTheme.darkInput
                                  : const Color(0xFFF5F7FF),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              hintStyle: GoogleFonts.outfit(
                                  color: isDark ? AppTheme.darkText4 : AppTheme.text4, fontSize: 13),
                            ),
                            menuStyle: MenuStyle(
                              backgroundColor: MaterialStateProperty.all(
                                  isDark ? AppTheme.darkSurface : AppTheme.surface),
                              elevation: MaterialStateProperty.all(4),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                            ),
                            onSelected: (int? value) {
                              if (value != null) {
                                _userIdCtrl.text = value.toString();
                                // Get student data locally
                                final selected = _students.firstWhere(
                                  (s) => _toInt(s['id']) == value,
                                  orElse: () => null,
                                );
                                setState(() {
                                  if (selected != null) {
                                    _studentName = selected['name']?.toString();
                                    _studentRollNo = (selected['roll_no'] ??
                                            selected['rollno'] ??
                                            selected['roll_number'])
                                        ?.toString();
                                  }
                                });
                                _loadEnrolled();
                                if (_studentName == null) {
                                  _loadStudentInfo();
                                }
                              } else {
                                setState(() {
                                  _userIdCtrl.clear();
                                  _studentName = null;
                                  _studentRollNo = null;
                                  _enrolledCourses.clear();
                                });
                              }
                            },
                            dropdownMenuEntries: _students.map((s) {
                              final name = s['name']?.toString() ?? 'Unknown';
                              final roll = (s['roll_no'] ?? s['rollno'] ?? s['roll_number'])?.toString() ?? '';
                              final label = roll.isNotEmpty ? '$name (Roll: $roll)' : name;
                              return DropdownMenuEntry<int>(
                                value: _toInt(s['id']),
                                label: label,
                                style: MenuItemButton.styleFrom(
                                  foregroundColor: isDark ? AppTheme.darkText1 : AppTheme.text1,
                                  textStyle: GoogleFonts.outfit(fontSize: 14),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                  // ── Student Info Card ──────────────────────────────
                  if (_loadingStudent)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(children: [
                        const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation(AppTheme.primary))),
                        const SizedBox(width: 10),
                        Text('Loading student info…',
                            style: GoogleFonts.outfit(fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkText3
                                    : AppTheme.text3)),
                      ]),
                    )
                  else if (_studentName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.primaryBg.withOpacity(0.15)
                            : AppTheme.primaryBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                            width: 1.2),
                      ),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.person_rounded,
                              color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_studentName!,
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppTheme.darkText1
                                        : AppTheme.text1)),
                            if (_studentRollNo != null) ...[
                              const SizedBox(height: 2),
                              Text('Roll No: $_studentRollNo',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppTheme.darkText3
                                          : AppTheme.text3)),
                            ],
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppTheme.greenBg,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('Verified',
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppTheme.greenDark,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  ],
                  // ──────────────────────────────────────────────────

                  const SizedBox(height: 20),
                  Divider(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                  const SizedBox(height: 16),

                  // Course dropdown
                  Text('Select Course',
                      style: GoogleFonts.outfit(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                          letterSpacing: 0.2)),
                  const SizedBox(height: 10),
                  _loadingCourses
                      ? const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(AppTheme.primary))))
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkInput
                          : const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                          width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: Text('Choose a course',
                            style: GoogleFonts.outfit(fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkText4
                                    : AppTheme.text4)),
                        value: _selectedCourseId,
                        dropdownColor:
                        isDark ? AppTheme.darkSurface : AppTheme.surface,
                        items: _courses.map((c) => DropdownMenuItem<int>(
                          value: _toInt(c['id']),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c['course_title'] ?? '',
                                  style: GoogleFonts.outfit(fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.darkText1
                                          : AppTheme.text1)),
                              Text('Code: ${c['course_code'] ?? '—'}',
                                  style: GoogleFonts.outfit(fontSize: 11,
                                      color: isDark
                                          ? AppTheme.darkText3
                                          : AppTheme.text3)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCourseId = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Enroll button
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        onTap: _enrolling ? null : _enroll,
                        borderRadius: BorderRadius.circular(13),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _enrolling ? null : AppTheme.heroGrad,
                            color: _enrolling
                                ? (isDark ? AppTheme.darkInput : AppTheme.bg)
                                : null,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: _enrolling
                                ? null
                                : AppTheme.glowShadow(AppTheme.primary),
                          ),
                          child: Center(
                            child: _enrolling
                                ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(
                                        AppTheme.primary)))
                                : Row(mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.assignment_turned_in_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Enroll Student',
                                      style: GoogleFonts.outfit(fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
          ),

          const SizedBox(height: 28),

          // Enrolled courses list
          if (_enrolledCourses.isNotEmpty || _loadingEnrolled) ...[
            Row(children: [
              Text('Enrolled Courses',
                  style: GoogleFonts.outfit(fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                      letterSpacing: -0.3)),
              const SizedBox(width: 8),
              if (_enrolledCourses.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryBg,
                      borderRadius: BorderRadius.circular(50)),
                  child: Text('${_enrolledCourses.length}',
                      style: GoogleFonts.outfit(fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
                ),
              const Spacer(),
              if (_loadingEnrolled)
                const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.primary))),
            ]),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _enrolledCourses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c        = _enrolledCourses[i];
                final courseId = _toInt(c['id'] ?? c['course_id']);
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  decoration: AppTheme.themedCard(context, radius: 14),
                  child: Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                          color: AppTheme.greenBg,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.check_circle_outline_rounded,
                          color: AppTheme.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['course_title'] ?? c['title'] ?? 'Course',
                            style: GoogleFonts.outfit(fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkText1
                                    : AppTheme.text1)),
                        const SizedBox(height: 2),
                        Text('Code: ${c['course_code'] ?? c['code'] ?? '—'}',
                            style: GoogleFonts.outfit(fontSize: 11,
                                color: isDark
                                    ? AppTheme.darkText3
                                    : AppTheme.text3)),
                      ],
                    )),
                    _removing
                        ? const Padding(padding: EdgeInsets.all(10),
                        child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    AppTheme.red))))
                        : IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            color: AppTheme.red, size: 22),
                        onPressed: () => _removeCourse(courseId),
                        splashRadius: 20),
                  ]),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}