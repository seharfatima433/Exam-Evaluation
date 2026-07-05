import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/teacher_service.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';

class QuizMonitoringScreen extends StatefulWidget {
  final String quizCode;
  final String quizName;

  const QuizMonitoringScreen({
    super.key,
    required this.quizCode,
    required this.quizName,
  });

  @override
  State<QuizMonitoringScreen> createState() => _QuizMonitoringScreenState();
}

class _QuizMonitoringScreenState extends State<QuizMonitoringScreen> {
  final _service = TeacherService();
  bool _loading = true;
  String? _error;
  List<dynamic> _attempts = [];
  int _totalLoaded = 0;
  int _activeCount = 0;

  Timer? _refreshTimer;
  bool _autoRefresh = true;
  int _secondsRemaining = 8;
  Timer? _countdownTimer;

  String _selectedFilter = 'All'; // 'All', 'Active', 'Submitted', 'Abandoned', 'Alerts'

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimers();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!_autoRefresh) return;

      setState(() {
        if (_secondsRemaining <= 1) {
          _secondsRemaining = 8;
          _loadData(silent: true);
        } else {
          _secondsRemaining--;
        }
      });
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final res = await _service.fetchQuizAttempts(widget.quizCode);
    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'];
      setState(() {
        _attempts = data['attempts'] ?? [];
        _totalLoaded = data['total_loaded'] ?? 0;
        _activeCount = data['active_count'] ?? 0;
        _loading = false;
        _error = null;
      });
    } else {
      if (!silent) {
        setState(() {
          _error = res['message'] ?? 'Failed to load tracking data';
          _loading = false;
        });
      }
    }
  }

  void _toggleAutoRefresh(bool val) {
    HapticFeedback.lightImpact();
    setState(() {
      _autoRefresh = val;
      if (_autoRefresh) {
        _secondsRemaining = 8;
        _startTimers();
      } else {
        _refreshTimer?.cancel();
        _countdownTimer?.cancel();
      }
    });
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  List<dynamic> get _filteredAttempts {
    if (_selectedFilter == 'All') {
      return _attempts;
    }
    if (_selectedFilter == 'Active') {
      return _attempts.where((a) => a['is_active'] == true).toList();
    }
    if (_selectedFilter == 'Submitted') {
      return _attempts.where((a) => a['status'] == 'submitted').toList();
    }
    if (_selectedFilter == 'Abandoned') {
      return _attempts.where((a) => a['status'] == 'abandoned').toList();
    }
    if (_selectedFilter == 'Alerts') {
      return _attempts.where((a) => _toInt(a['tab_switch_count']) > 0).toList();
    }
    return _attempts;
  }

  int get _submittedCount {
    return _attempts.where((a) => a['status'] == 'submitted').toList().length;
  }

  int get _abandonedCount {
    return _attempts.where((a) => a['status'] == 'abandoned').toList().length;
  }

  int get _alertsCount {
    return _attempts.where((a) => _toInt(a['tab_switch_count']) > 0).toList().length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          PremiumAppBar(
            title: widget.quizName,
            subtitle: 'Live Integrity Dashboard',
            showBack: true,
            tag: widget.quizCode,
            actionIcon: Icons.refresh_rounded,
            onActionTap: () {
              HapticFeedback.lightImpact();
              _loadData();
            },
          ),

          // Sub-Header: Auto-Refresh Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.surfaceAlt,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sync_rounded,
                  size: 16,
                  color: _autoRefresh ? AppTheme.primary : (isDark ? AppTheme.darkText4 : AppTheme.text4),
                ),
                const SizedBox(width: 8),
                Text(
                  _autoRefresh ? 'Auto-refreshing in ${_secondsRemaining}s' : 'Auto-refresh paused',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _autoRefresh
                        ? AppTheme.primary
                        : (isDark ? AppTheme.darkText3 : AppTheme.text3),
                  ),
                ),
                const Spacer(),
                Text(
                  'Auto Update',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _autoRefresh,
                    onChanged: _toggleAutoRefresh,
                    activeColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fetching live attempts...',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? AppTheme.darkText3 : AppTheme.text3,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.red.withOpacity(0.15)),
                ),
                child: const Icon(Icons.wifi_off_rounded, size: 28, color: AppTheme.red),
              ),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _loadData(),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: Text('Try Again', style: GoogleFonts.outfit(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 1. Stats Counter Row
        _buildStatsCards(isDark),

        // 2. Filters
        _buildFiltersRow(isDark),

        // 3. Attempt List
        Expanded(
          child: _filteredAttempts.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: _filteredAttempts.length,
                  itemBuilder: (ctx, index) {
                    final attempt = _filteredAttempts[index];
                    return _buildAttemptTile(attempt, index, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStat(
              label: 'Active',
              value: '$_activeCount',
              color: AppTheme.greenDark,
              gradient: AppTheme.greenGrad,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMiniStat(
              label: 'Submitted',
              value: '$_submittedCount',
              color: AppTheme.primary,
              gradient: AppTheme.primaryGrad,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMiniStat(
              label: 'Alerts',
              value: '$_alertsCount',
              color: AppTheme.red,
              gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFEF5350)]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
    required Gradient gradient,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(bool isDark) {
    final filters = ['All', 'Active', 'Submitted', 'Abandoned', 'Alerts'];
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: filters.length,
        itemBuilder: (ctx, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          Color filterColor = AppTheme.primary;
          if (filter == 'Active') filterColor = AppTheme.greenDark;
          if (filter == 'Alerts') filterColor = AppTheme.red;
          if (filter == 'Abandoned') filterColor = AppTheme.amber;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedFilter = filter;
                });
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? (filter == 'Alerts'
                          ? const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFEF5350)])
                          : filter == 'Active'
                              ? AppTheme.greenGrad
                              : filter == 'Abandoned'
                                  ? AppTheme.accentGrad
                                  : AppTheme.primaryGrad)
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? AppTheme.darkInput : AppTheme.surfaceAlt),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? AppTheme.darkBorder : AppTheme.border),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTheme.darkText2 : AppTheme.text2),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkInput : AppTheme.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 26,
                color: isDark ? AppTheme.darkText4 : AppTheme.text4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No Students Found',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText2 : AppTheme.text2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No attempts match the current filter selection.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? AppTheme.darkText4 : AppTheme.text4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptTile(dynamic attempt, int index, bool isDark) {
    final name = attempt['student_name']?.toString() ?? 'Student';
    final rollNo = attempt['student_identifier']?.toString() ?? 'N/A';
    final status = attempt['status']?.toString() ?? 'started';
    final tabSwitches = _toInt(attempt['tab_switch_count']);
    final isActive = attempt['is_active'] == true;
    final inactiveMins = _toInt(attempt['inactive_minutes']);

    Color badgeColor = AppTheme.primary;
    String badgeText = 'STARTED';
    if (status == 'submitted') {
      badgeColor = AppTheme.greenDark;
      badgeText = 'SUBMITTED';
    } else if (status == 'abandoned') {
      badgeColor = AppTheme.red;
      badgeText = 'ABANDONED';
    } else if (status == 'not_started') {
      badgeColor = isDark ? AppTheme.darkText4 : AppTheme.text4;
      badgeText = 'NOT STARTED';
    } else if (isActive) {
      badgeColor = AppTheme.green;
      badgeText = 'ACTIVE';
    } else {
      badgeColor = isDark ? AppTheme.darkText4 : AppTheme.text3;
      badgeText = 'IDLE (${inactiveMins}m)';
    }

    final hasAlert = tabSwitches > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAlert
              ? AppTheme.red.withOpacity(0.35)
              : (isDark ? AppTheme.darkBorder : AppTheme.border),
          width: hasAlert ? 1.5 : 1.2,
        ),
        boxShadow: hasAlert
            ? [
                BoxShadow(
                  color: AppTheme.red.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Student info & main Status badge
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withOpacity(0.08),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                        ),
                      ),
                      Text(
                        rollNo,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Row 2: Integrity stats (tab switches) & last active
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Integrity Indicator (Tab switches)
                if (tabSwitches > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.red.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 13,
                          color: AppTheme.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$tabSwitches Tab Switch${tabSwitches > 1 ? 'es' : ''}',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.red,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.greenDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 13,
                          color: AppTheme.greenDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'No violations',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Last Active Indicator
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatLastActive(attempt['last_active_at']),
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (status == 'abandoned') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    attempt['allowed_reentry'] == 1 || attempt['allowed_reentry'] == true
                        ? '🔓 Re-entry Allowed'
                        : '🔒 Re-entry Blocked',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: attempt['allowed_reentry'] == 1 || attempt['allowed_reentry'] == true
                          ? AppTheme.greenDark
                          : AppTheme.red,
                    ),
                  ),
                  if (attempt['allowed_reentry'] != 1 && attempt['allowed_reentry'] != true)
                    ElevatedButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final attemptId = _toInt(attempt['id']);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Unlocking attempt for $name...',
                              style: GoogleFonts.outfit(),
                            ),
                            backgroundColor: AppTheme.primary,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        
                        final res = await _service.unlockAttempt(attemptId);
                        if (res['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$name unlocked successfully!',
                                style: GoogleFonts.outfit(),
                              ),
                              backgroundColor: AppTheme.greenDark,
                            ),
                          );
                          _loadData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                res['message'] ?? 'Failed to unlock attempt',
                                style: GoogleFonts.outfit(),
                              ),
                              backgroundColor: AppTheme.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.lock_open_rounded, size: 13, color: Colors.white),
                      label: Text(
                        'Unlock Quiz',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLastActive(dynamic lastActiveStr) {
    if (lastActiveStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(lastActiveStr.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 15) {
        return 'Active just now';
      }
      if (diff.inMinutes < 1) {
        return 'Active ${diff.inSeconds}s ago';
      }
      if (diff.inHours < 1) {
        return 'Active ${diff.inMinutes}m ago';
      }
      return 'Active ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      // Fallback: extract HH:mm from raw string
      final str = lastActiveStr.toString();
      if (str.length >= 16) {
        return 'Active ${str.substring(11, 16)}';
      }
      return 'Active $str';
    }
  }
}
