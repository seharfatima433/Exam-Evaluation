import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/student_service.dart';
import 'student_course_detail_screen.dart';
import 'student_screen.dart'; // NsctScreen, NsctSyllabusScreen, NsctMaterialScreen

// ══════════════════════════════════════════════════════════════════
// STUDENT COURSES SCREEN — enrolled courses list
// ══════════════════════════════════════════════════════════════════
class StudentCoursesScreen extends StatefulWidget {
  final String studentName;
  final int studentId;
  final String? rollNo;

  const StudentCoursesScreen({
    super.key,
    required this.studentName,
    required this.studentId,
    this.rollNo,
  });

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _service = StudentService();
  List<StudentCourse> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    Map<String, dynamic> result;
    if (widget.rollNo != null && widget.rollNo!.isNotEmpty) {
      result = await _service.fetchMyCourses(widget.rollNo!);
    } else {
      result = await _service.fetchStudentCoursesByUserId(widget.studentId);
    }
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() { _courses = result['data'] as List<StudentCourse>; _loading = false; });
    } else {
      setState(() { _error = result['message'] as String?; _loading = false; });
    }
  }

  String get _initials {
    final p = widget.studentName.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _NsctDrawer(studentName: widget.studentName, initials: _initials, rollNo: widget.rollNo),
      body: Column(
        children: [
          // AppBar
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.heroGrad),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 16, left: 16, right: 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.30)),
                    ),
                    child: Center(
                      child: Text(_initials,
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.studentName,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (widget.rollNo != null)
                        Text('Roll No: ${widget.rollNo}',
                            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withOpacity(0.70))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(AppTheme.primary)),
        const SizedBox(height: 14),
        Text('Loading your courses…', style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
      ]));
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64,
            decoration: BoxDecoration(color: AppTheme.red.withOpacity(0.10), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.error_outline_rounded, size: 30, color: AppTheme.red)),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
        const SizedBox(height: 16),
        TextButton.icon(onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text('Try Again', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary)),
      ])));
    }
    if (_courses.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80,
            decoration: BoxDecoration(gradient: AppTheme.primaryGrad, borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.school_outlined, color: Colors.white, size: 36)),
        const SizedBox(height: 20),
        Text('No Courses Found', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkText1 : AppTheme.text1)),
        const SizedBox(height: 6),
        Text('You are not enrolled in any course yet. Please contact your admin.', textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
      ])));
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Welcome card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: AppTheme.heroGrad, borderRadius: BorderRadius.circular(18), boxShadow: AppTheme.glowShadow(AppTheme.primary)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome! 👋', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withOpacity(0.80))),
                const SizedBox(height: 4),
                Text('My Courses', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('${_courses.length} course${_courses.length != 1 ? 's' : ''} enrolled',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withOpacity(0.65))),
              ])),
              Container(width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 24)),
            ]),
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 20),
          Text('My Enrolled Courses', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText2 : AppTheme.text2)).animate(delay: 80.ms).fadeIn(),
          const SizedBox(height: 10),

          ...List.generate(_courses.length, (i) {
            final course = _courses[i];
            final colors = [
              const Color(0xFF1565C0), const Color(0xFF6A1B9A), const Color(0xFF00695C),
              const Color(0xFFE65100), const Color(0xFF00838F), const Color(0xFF4527A0),
            ];
            final accent = colors[i % colors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                boxShadow: AppTheme.softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(children: [
                  Container(height: 3, decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [accent, accent.withOpacity(0.4)]))),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(width: 46, height: 46,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [accent, accent.withOpacity(0.75)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(13)),
                          child: const Icon(Icons.book_rounded, color: Colors.white, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(course.courseTitle,
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkText1 : AppTheme.text1),
                            maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
                        if (course.courseCode != null) ...[
                          const SizedBox(height: 4),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(5)),
                              child: Text(course.courseCode!, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                        ],
                      ])),
                      // View Details button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => StudentCourseDetailScreen(
                              course: course,
                              studentId: widget.studentId,
                              studentName: widget.studentName,
                              accentColor: accent,
                              rollNo: widget.rollNo,
                            ),
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [accent, accent.withOpacity(0.80)]),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: accent.withOpacity(0.30), blurRadius: 8, offset: const Offset(0, 3))]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('View Details', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ).animate(delay: Duration(milliseconds: i * 70)).fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
          }),
        ],
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════════
// NSCT DRAWER
// ══════════════════════════════════════════════════════════════════
class _NsctDrawer extends StatelessWidget {
  final String studentName;
  final String initials;
  final String? rollNo;

  const _NsctDrawer({
    required this.studentName,
    required this.initials,
    required this.rollNo,
  });

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      width: 285,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: const BoxDecoration(gradient: AppTheme.heroGrad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(studentName,
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (rollNo != null)
                    Text('Roll No: $rollNo',
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withOpacity(0.70))),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── NSCT Section ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Text('NSCT PREPARATION',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
            ),

            _DrawerTile(
              icon: Icons.school_rounded,
              label: 'NSCT Home',
              subtitle: 'Overview & options',
              color: AppTheme.primary,
              onTap: () => _go(context, const NsctScreen()),
            ),
            _DrawerTile(
              icon: Icons.menu_book_rounded,
              label: 'Syllabus',
              subtitle: '10 subjects · all topics',
              color: AppTheme.violet,
              onTap: () => _go(context, const NsctSyllabusScreen()),
            ),
            _DrawerTile(
              icon: Icons.folder_copy_rounded,
              label: 'Preparation Material',
              subtitle: 'Notes, MCQs, PDF guides',
              color: AppTheme.greenDark,
              onTap: () => _go(context, const NsctMaterialScreen()),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('AI Based Evaluation · Student',
                  style: GoogleFonts.outfit(fontSize: 10,
                      color: isDark ? AppTheme.darkText4 : AppTheme.text4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon, required this.label,
    required this.subtitle, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText1 : AppTheme.text1)),
              Text(subtitle, style: GoogleFonts.outfit(fontSize: 10,
                  color: isDark ? AppTheme.darkText4 : AppTheme.text4)),
            ])),
            Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppTheme.darkText4 : AppTheme.text4),
          ]),
        ),
      ),
    );
  }
}