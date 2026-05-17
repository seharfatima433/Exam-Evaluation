import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

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
  // Simple index — no TabController needed
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header — NO TabBar here ──────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(gradient: AppTheme.heroGrad),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.28), width: 1),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.adminName,
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text('Admin Panel',
                          style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.70))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _confirmLogout(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: Row(children: [
                      const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text('Logout',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Body ─────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                _AddTeacherTab(),
                _AssignCoursesTab(),
                _EnrollStudentTab(),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom Navigation Bar ONLY ────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _bottomItem(0, Icons.person_add_rounded,           'Add Teacher', isDark),
                _bottomItem(1, Icons.book_rounded,                 'Assign Courses', isDark),
                _bottomItem(2, Icons.assignment_turned_in_rounded, 'Enroll', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomItem(int index, IconData icon, String label, bool isDark) {
    final selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryBg : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20,
                  color: selected
                      ? AppTheme.primary
                      : (isDark ? AppTheme.darkText4 : AppTheme.text4)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? AppTheme.primary
                      : (isDark ? AppTheme.darkText4 : AppTheme.text4),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Logout dialog (unchanged) ─────────────────────────────
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
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, a, __) => const LoginScreen(),
                transitionsBuilder: (_, a, __, child) =>
                    FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
                  (route) => false,
            );
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
// TAB 1 — ADD TEACHER  (unchanged)
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
// TAB 2 — ASSIGN COURSES TO TEACHER  (unchanged)
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
                          _selectedTeacherId = val; // already int from DropdownMenuItem<int>
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
// GET  /admin/student-courses/{user_id}  — from image/docx
// POST /admin/assign-course              — from docx
// POST /admin/remove-student-course      — from image/docx
// GET  /admin/courses                    — already confirmed
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

  bool _loadingCourses  = true;
  bool _loadingEnrolled = false;
  bool _enrolling       = false;
  bool _removing        = false;

  int? get _userId => int.tryParse(_userIdCtrl.text.trim());

  @override
  void initState() { super.initState(); _loadCourses(); }

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

                  // Student ID field + Load button
                  Text('Student ID',
                      style: GoogleFonts.outfit(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                          letterSpacing: 0.2)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _userIdCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(fontSize: 14,
                            color: isDark ? AppTheme.darkText1 : AppTheme.text1),
                        decoration: InputDecoration(
                          labelText: 'Student User ID',
                          hintText: 'e.g. 42',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.badge_outlined,
                                size: 18, color: AppTheme.text4),
                          ),
                          prefixIconConstraints:
                          const BoxConstraints(minWidth: 46, minHeight: 46),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkInput
                              : const Color(0xFFF5F7FF),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? AppTheme.darkBorder
                                      : AppTheme.border,
                                  width: 1.2)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? AppTheme.darkBorder
                                      : AppTheme.border,
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'User ID required';
                          if (int.tryParse(v.trim()) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loadingEnrolled ? null : () {
                          if (_formKey.currentState!.validate()) _loadEnrolled();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _loadingEnrolled
                            ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : Text('Load',
                            style: GoogleFonts.outfit(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),

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