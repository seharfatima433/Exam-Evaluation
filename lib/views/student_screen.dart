import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';

// ── NSCT Syllabus Data ────────────────────────────────────────────
class NsctSubject {
  final String name;
  final String weightage;
  final IconData icon;
  final Color color;
  final List<String> topics;
  const NsctSubject({
    required this.name,
    required this.weightage,
    required this.icon,
    required this.color,
    required this.topics,
  });
}

const List<NsctSubject> nsctSubjects = [
  NsctSubject(
    name: 'Computer Networks\n& Cloud Computing',
    weightage: '10%',
    icon: Icons.lan_rounded,
    color: Color(0xFF1565C0),
    topics: [
      '1 - Data Communication',
      '2 - Computer Networks',
      '3 - Data Link Layer',
      '4 - Network Layer',
      '5 - Transport Layer',
      '6 - Application Layer',
      '7 - Wireless Networks',
      '8 - Cloud Computing',
      '9 - Network Security (Networks Perspective)',
      '10 - Next Generation Networks',
    ],
  ),
  NsctSubject(
    name: 'Programming\n(C++/Java/Python)',
    weightage: '10%',
    icon: Icons.code_rounded,
    color: Color(0xFFE65100),
    topics: [
      '1 - Programming Fundamentals',
      '2 - Data Types & Variables',
      '3 - Operators & Expressions',
      '4 - Control Structures',
      '5 - Functions / Methods',
      '6 - Input / Output Handling',
      '7 - Strings & Text Processing',
      '8 - Arrays & Collections',
      '9 - Object-Oriented Programming (OOP)',
      '10 - Memory Management Concepts',
      '11 - Exception & Error Handling',
      '12 - Modules, Packages & Libraries',
      '13 - Advanced Programming Concepts',
      '14 - Concurrency & Parallelism (Introductory)',
      '15 - Debugging, Testing & Optimization',
      '16 - Software Development Practices',
    ],
  ),
  NsctSubject(
    name: 'Data Structures\n& Algorithms',
    weightage: '10%',
    icon: Icons.account_tree_rounded,
    color: Color(0xFF6A1B9A),
    topics: [
      '1 - Foundations of Data Structure and Algorithms',
      '2 - Linear Data Structures',
      '3 - Non-Linear Data Structures',
      '4 - Searching Algorithms',
      '5 - Sorting Algorithms',
      '6 - Hashing',
      '7 - Tree Algorithms',
      '8 - Graph Algorithms',
      '9 - Algorithm Design Techniques',
      '10 - Advanced Data Structures',
      '11 - String Algorithms',
      '12 - Complexity & Optimization',
    ],
  ),
  NsctSubject(
    name: 'Operating Systems',
    weightage: '5%',
    icon: Icons.computer_rounded,
    color: Color(0xFF00695C),
    topics: [
      '1 - Introduction to Operating Systems',
      '2 - Operating System Structures',
      '3 - Process Management',
      '4 - CPU Scheduling',
      '5 - Thread Management',
      '6 - Concurrency & Synchronization',
      '7 - Deadlocks',
      '8 - Memory Management',
      '9 - File System Management',
      '10 - Secondary Storage Management',
      '11 - Input / Output Systems',
      '12 - Protection & Security',
    ],
  ),
  NsctSubject(
    name: 'Software Engineering',
    weightage: '10%',
    icon: Icons.engineering_rounded,
    color: Color(0xFF37474F),
    topics: [
      '1 - Introduction to Software Engineering',
      '2 - Software Process Models',
      '3 - Agile Software Development',
      '4 - Software Requirements Engineering',
      '5 - Software Project Management',
      '6 - Software Design',
      '7 - Software Architecture',
      '8 - User Interface Design',
      '9 - Software Implementation & Coding',
      '10 - Software Testing',
      '11 - Software Maintenance & Evolution',
      '12 - Software Quality Assurance',
      '13 - Software Metrics & Measurement',
      '14 - Software Configuration Management',
      '15 - Software Risk Management',
      '16 - Software Security Engineering',
    ],
  ),
  NsctSubject(
    name: 'Web Development',
    weightage: '10%',
    icon: Icons.web_rounded,
    color: Color(0xFF00838F),
    topics: [
      '1 - Introduction to Web Development',
      '2 - Web Architecture & Protocols',
      '3 - HTML Fundamentals',
      '4 - CSS Fundamentals',
      '5 - Advanced CSS & Responsive Design',
      '6 - JavaScript Fundamentals',
      '7 - Advanced JavaScript',
      '8 - Frontend Frameworks & Libraries',
      '9 - Backend Development Fundamentals',
      '10 - Server-Side Programming',
      '11 - Databases for Web Applications',
      '12 - Web Security',
      '13 - Web Performance & Optimization',
      '14 - Web Testing & Debugging',
      '15 - Deployment & Hosting',
      '16 - Web APIs & Integration',
      '17 - Modern Web Development Practices',
    ],
  ),
  NsctSubject(
    name: 'AI / Machine Learning\n& Data Analytics',
    weightage: '10%',
    icon: Icons.psychology_rounded,
    color: Color(0xFF558B2F),
    topics: [
      '1 - Introduction to AI, ML & Data Analytics',
      '2 - Mathematical Foundations',
      '3 - Python for AI & Data Analytics',
      '4 - Data Collection & Pre-processing',
      '5 - Exploratory Data Analysis (EDA)',
      '6 - Supervised Learning',
      '7 - Ensemble Learning',
      '8 - Unsupervised Learning',
      '9 - Model Evaluation & Validation',
      '10 - Feature Engineering & Selection',
      '11 - Deep Learning Fundamentals',
      '12 - Advanced Deep Learning',
      '13 - Natural Language Processing (NLP)',
      '14 - Computer Vision',
      '15 - Big Data Analytics (Introductory)',
      '16 - Model Deployment & MLOps Basics',
      '17 - AI Ethics, Security & Privacy',
    ],
  ),
  NsctSubject(
    name: 'Cyber Security',
    weightage: '5%',
    icon: Icons.security_rounded,
    color: Color(0xFFB71C1C),
    topics: [
      '1 - Introduction to Cyber Security',
      '2 - Security Fundamentals & Principles',
      '3 - Cryptography Basics',
      '4 - Network Security',
      '5 - Operating System Security',
      '6 - Web Application Security',
      '7 - Malware & Attack Techniques',
      '8 - Authentication & Access Control',
      '9 - Secure Software Development',
      '10 - Wireless & Mobile Security',
      '11 - Cloud & Virtualization Security',
      '12 - Digital Forensics',
      '13 - Incident Response & Management',
      '14 - Security Monitoring & Auditing',
      '15 - Cyber Laws & Ethics',
      '16 - Emerging Trends in Cyber Security',
    ],
  ),
  NsctSubject(
    name: 'Databases',
    weightage: '10%',
    icon: Icons.storage_rounded,
    color: Color(0xFF4527A0),
    topics: [
      '1 - Introduction to Database Systems',
      '2 - Database System Architecture',
      '3 - Data Models',
      '4 - Relational Database Concepts',
      '5 - Relational Algebra & Calculus',
      '6 - Structured Query Language (SQL)',
      '7 - Advanced SQL',
      '8 - Database Design & Normalization',
      '9 - Transaction Management',
      '10 - Concurrency Control',
      '11 - Recovery Management',
      '12 - Indexing & File Organization',
      '13 - Query Processing & Optimization',
      '14 - Database Security',
      '15 - Distributed Databases',
      '16 - NoSQL & Modern Databases',
      '17 - Data Warehousing & Data Mining (Introductory)',
    ],
  ),
  NsctSubject(
    name: 'Problem Solving &\nAnalytical Skills',
    weightage: '20%',
    icon: Icons.lightbulb_rounded,
    color: Color(0xFFFF8F00),
    topics: [
      '1 - Introduction to Problem Solving',
      '2 - Problem Understanding & Analysis',
      '3 - Logical Reasoning Fundamentals',
      '4 - Algorithms & Flow Control',
      '5 - Data Representation & Abstraction',
      '6 - Pattern Recognition & Generalization',
      '7 - Mathematical & Quantitative Reasoning',
      '8 - Algorithmic Thinking',
      '9 - Critical Thinking & Decision Making',
      '10 - Debugging & Error Analysis',
      '11 - Complexity & Efficiency Awareness',
      '12 - Problem Solving Using Programming',
      '13 - Data-Driven Problem Solving',
      '14 - Creative & Innovative Thinking',
      '15 - Real-World Problem Solving',
      '16 - Communication & Documentation of Solutions',
    ],
  ),
];

// ══════════════════════════════════════════════════════════════════
// STUDENT SCREEN  (clean, minimal)
// ══════════════════════════════════════════════════════════════════
class StudentScreen extends StatefulWidget {
  final String studentName;
  final int studentId;
  final String? rollNo;
  const StudentScreen({
    super.key,
    this.studentName = 'Student',
    this.studentId = 0,
    this.rollNo,
  });
  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 0;

  String get _initials {
    final p = widget.studentName.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return widget.studentName.isNotEmpty
        ? widget.studentName[0].toUpperCase()
        : 'S';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _StudentDrawer(studentName: widget.studentName),
      body: Column(
        children: [
          PremiumAppBar(
            title: widget.studentName,
            subtitle:
            widget.rollNo != null ? 'Roll: ${widget.rollNo}' : 'Student',
            initials: _initials,
            showThemeToggle: true,
            actionIcon: Icons.menu_rounded,
            onActionTap: () {
              _scaffoldKey.currentState?.openDrawer();
              HapticFeedback.lightImpact();
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
              children: [
                // Welcome Banner
                _WelcomeBanner(studentName: widget.studentName)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.12, end: 0),

                const SizedBox(height: 28),

                // Recent Activity placeholder cards
                _SectionLabel('Overview')
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 380.ms),
                const SizedBox(height: 12),
                _OverviewCards()
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 380.ms)
                    .slideY(begin: 0.08, end: 0),

                const SizedBox(height: 28),

                // NSCT hint card
                _NsctHintCard(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                    HapticFeedback.lightImpact();
                  },
                ).animate(delay: 220.ms).fadeIn(duration: 380.ms).slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selected: _tab,
        onTap: (i) {
          setState(() => _tab = i);
          HapticFeedback.selectionClick();
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DRAWER  — single NSCT option
// ══════════════════════════════════════════════════════════════════
class _StudentDrawer extends StatelessWidget {
  final String studentName;
  const _StudentDrawer({required this.studentName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(gradient: AppTheme.heroGrad),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.30), width: 1),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Student Portal',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Menu Items ───────────────────────────────────────────
          const SizedBox(height: 12),

          // NSCT tile
          _DrawerTile(
            icon: Icons.school_rounded,
            label: 'NSCT',
            subtitle: 'Syllabus & Preparation',
            color: AppTheme.primary,
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NsctScreen()),
              );
            },
          ),

          const Spacer(),

          // ── Footer ───────────────────────────────────────────────
          Divider(
            height: 1,
            color: isDark ? AppTheme.darkDivider : AppTheme.divider,
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'NSCT Preparation App',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.18), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGrad,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? AppTheme.darkText4 : AppTheme.text4),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// NSCT SCREEN  — two options: Syllabus & Preparation Material
// ══════════════════════════════════════════════════════════════════
class NsctScreen extends StatelessWidget {
  const NsctScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              bottom: 22,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(gradient: AppTheme.heroGrad),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.30), width: 1),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NSCT',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'National Skill Competency Test',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.18), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${nsctSubjects.length} subjects · ${nsctSubjects.fold(0, (s, e) => s + e.topics.length)} topics · 100% marks',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms),

                const SizedBox(height: 24),

                Text(
                  'Select an option',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                    letterSpacing: 0.2,
                  ),
                ).animate(delay: 80.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 12),

                // ── Syllabus Card ────────────────────────────────
                _NsctOptionCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Syllabus',
                  description:
                  'Browse all ${nsctSubjects.length} subject areas with full topic breakdowns and weightages.',
                  badgeText: '${nsctSubjects.fold(0, (s, e) => s + e.topics.length)} Topics',
                  gradient: AppTheme.primaryGrad,
                  accentColor: AppTheme.primary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NsctSyllabusScreen()),
                    );
                  },
                ).animate(delay: 130.ms).fadeIn(duration: 380.ms).slideY(begin: 0.10, end: 0),

                const SizedBox(height: 14),

                // ── Preparation Material Card ────────────────────
                _NsctOptionCard(
                  icon: Icons.folder_copy_rounded,
                  title: 'Preparation Material',
                  description:
                  'Study notes, guides, and resources organized by subject to ace your NSCT.',
                  badgeText: 'Resources',
                  gradient: AppTheme.greenGrad,
                  accentColor: AppTheme.greenDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NsctMaterialScreen()),
                    );
                  },
                ).animate(delay: 200.ms).fadeIn(duration: 380.ms).slideY(begin: 0.10, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Option card widget used in NsctScreen
class _NsctOptionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String badgeText;
  final Gradient gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _NsctOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_NsctOptionCard> createState() => _NsctOptionCardState();
}

class _NsctOptionCardState extends State<_NsctOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.border,
              width: 1,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.badgeText,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: widget.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.description,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: widget.accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// NSCT SYLLABUS SCREEN  — all subjects with expandable topics
// ══════════════════════════════════════════════════════════════════
class NsctSyllabusScreen extends StatefulWidget {
  const NsctSyllabusScreen({super.key});
  @override
  State<NsctSyllabusScreen> createState() => _NsctSyllabusScreenState();
}

class _NsctSyllabusScreenState extends State<NsctSyllabusScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              bottom: 22,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(gradient: AppTheme.heroGrad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NSCT Syllabus',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${nsctSubjects.length} Areas of Competency',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.70),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total topics badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: Text(
                        '${nsctSubjects.fold(0, (s, e) => s + e.topics.length)} Topics',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Subject List ─────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              itemCount: nsctSubjects.length,
              itemBuilder: (context, index) {
                final subject = nsctSubjects[index];
                final isExpanded = _expandedIndex == index;
                return Column(
                  children: [
                    // Subject row
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedIndex = isExpanded ? null : index;
                        });
                        HapticFeedback.selectionClick();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? subject.color.withOpacity(0.07)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isExpanded
                              ? Border.all(
                              color: subject.color.withOpacity(0.20),
                              width: 1)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: subject.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(subject.icon,
                                  size: 18, color: subject.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.name.replaceAll('\n', ' '),
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.darkText1
                                          : AppTheme.text1,
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                          subject.color.withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          subject.weightage,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: subject.color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${subject.topics.length} topics',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: isDark
                                              ? AppTheme.darkText3
                                              : AppTheme.text3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: isExpanded ? subject.color : AppTheme.text4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Topics expanded
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Padding(
                        padding: const EdgeInsets.only(
                            left: 18, right: 8, bottom: 8),
                        child: Column(
                          children: subject.topics.map((topic) {
                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: subject.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      topic,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppTheme.darkText2
                                            : AppTheme.text2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),
                    if (index < nsctSubjects.length - 1)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark ? AppTheme.darkDivider : AppTheme.divider,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// NSCT MATERIAL SCREEN  — preparation resources by subject
// ══════════════════════════════════════════════════════════════════
class NsctMaterialScreen extends StatefulWidget {
  const NsctMaterialScreen({super.key});
  @override
  State<NsctMaterialScreen> createState() => _NsctMaterialScreenState();
}

class _NsctMaterialScreenState extends State<NsctMaterialScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Animated Header ──────────────────────────────────────
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              final t = _pulseAnim.value;
              return Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 14,
                  bottom: 24,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF2E7D32), const Color(0xFF1B5E20), t)!,
                      Color.lerp(const Color(0xFF388E3C), const Color(0xFF43A047), t)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.28), width: 1),
                      ),
                      child: const Icon(Icons.folder_copy_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preparation Material',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${nsctSubjects.length} subjects · 3 resource types each',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Resource type legend chips
                Row(
                  children: [
                    _HeaderChip(Icons.article_rounded, 'Notes', Colors.white),
                    const SizedBox(width: 8),
                    _HeaderChip(Icons.quiz_rounded, 'MCQs', Colors.white),
                    const SizedBox(width: 8),
                    _HeaderChip(Icons.picture_as_pdf_rounded, 'PDF Guide', Colors.white),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideX(begin: -0.05, end: 0),
              ],
            ),
          ),

          // ── Material List ────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              itemCount: nsctSubjects.length,
              itemBuilder: (context, index) {
                final subject = nsctSubjects[index];
                return _MaterialSubjectCard(subject: subject, index: index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeaderChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resource types data ───────────────────────────────────────────
const _resourceTypes = [
  (Icons.article_rounded, 'Notes', Color(0xFF1565C0)),
  (Icons.quiz_rounded, 'MCQs', Color(0xFF6A1B9A)),
  (Icons.picture_as_pdf_rounded, 'PDF Guide', Color(0xFFB71C1C)),
];

class _MaterialSubjectCard extends StatefulWidget {
  final NsctSubject subject;
  final int index;
  const _MaterialSubjectCard({required this.subject, required this.index});
  @override
  State<_MaterialSubjectCard> createState() => _MaterialSubjectCardState();
}

class _MaterialSubjectCardState extends State<_MaterialSubjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // Fire shimmer once after entry animation settles
    Future.delayed(Duration(milliseconds: 300 + widget.index * 45), () {
      if (mounted) _shimmerCtrl.forward();
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = widget.subject;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Colored top accent bar ──────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [subject.color, subject.color.withOpacity(0.50)],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Subject header ────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              subject.color,
                              subject.color.withOpacity(0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: subject.color.withOpacity(0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(subject.icon,
                            size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name.replaceAll('\n', ' '),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkText1
                                    : AppTheme.text1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: subject.color.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    subject.weightage,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: subject.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${subject.topics.length} topics',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppTheme.darkText3
                                        : AppTheme.text3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Resource buttons — fixed overflow ─────────
                  // Use separate rows to avoid any horizontal overflow
                  Row(
                    children: List.generate(_resourceTypes.length, (i) {
                      final r = _resourceTypes[i];
                      return Expanded(
                        child: Padding(
                          // gap between chips; no right padding on last
                          padding: EdgeInsets.only(right: i < 2 ? 7 : 0),
                          child: _ResourceChip(
                            icon: r.$1,
                            label: r.$2,
                            chipColor: r.$3,
                            accentColor: subject.color,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 55))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic)
        .then()
        .shimmer(
      duration: 700.ms,
      color: subject.color.withOpacity(0.12),
      delay: Duration(milliseconds: widget.index * 30),
    );
  }
}

class _ResourceChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color chipColor;
  final Color accentColor;
  const _ResourceChip({
    required this.icon,
    required this.label,
    required this.chipColor,
    required this.accentColor,
  });
  @override
  State<_ResourceChip> createState() => _ResourceChipState();
}

class _ResourceChipState extends State<_ResourceChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        HapticFeedback.lightImpact();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          // fixed height so all chips are uniform
          height: 64,
          decoration: BoxDecoration(
            color: widget.accentColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.20),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.chipColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon,
                    size: 14, color: widget.chipColor),
              ),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText2 : AppTheme.text2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// STUDENT SCREEN SUPPORTING WIDGETS
// ══════════════════════════════════════════════════════════════════

// Welcome Banner
class _WelcomeBanner extends StatelessWidget {
  final String studentName;
  const _WelcomeBanner({required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGrad,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.glowShadow(AppTheme.primary),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${studentName.split(' ')[0]} 👋',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.80),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to prepare?',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap the menu icon or open the drawer to get started with NSCT.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.65),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Section label
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: GoogleFonts.outfit(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkText1
          : AppTheme.text1,
      letterSpacing: -0.2,
    ),
  );
}

// Overview stat cards
class _OverviewCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final totalTopics =
    nsctSubjects.fold(0, (sum, s) => sum + s.topics.length);
    final cards = [
      (Icons.book_rounded, '${nsctSubjects.length}', 'Subjects', AppTheme.primaryGrad, AppTheme.primary),
      (Icons.topic_rounded, '$totalTopics', 'Topics', AppTheme.violetGrad, AppTheme.violet),
      (Icons.bar_chart_rounded, '100%', 'Marks', AppTheme.greenGrad, AppTheme.greenDark),
    ];
    return Row(
      children: cards.map((c) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: AppTheme.themedCard(context, radius: 14),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: c.$4,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: c.$5.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Icon(c.$1, color: Colors.white, size: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  c.$2,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkText1
                        : AppTheme.text1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.$3,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkText3
                        : AppTheme.text3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// NSCT hint card on home
class _NsctHintCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NsctHintCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGrad,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.glowShadow(AppTheme.primary),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NSCT Preparation',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Open drawer → NSCT to view syllabus & materials',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.onTap});

  static const _tabs = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.quiz_rounded, Icons.quiz_outlined, 'Quizzes'),
    (Icons.menu_book_rounded, Icons.menu_book_outlined, 'NSCT'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ]
            : [
          const BoxShadow(
              color: Color(0x0C1565C0),
              blurRadius: 16,
              offset: Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final sel = i == selected;
              final t = _tabs[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        decoration: sel
                            ? BoxDecoration(
                          gradient: AppTheme.primaryGrad,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                                color:
                                AppTheme.primary.withOpacity(0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ],
                        )
                            : null,
                        child: Icon(sel ? t.$1 : t.$2,
                            size: 20,
                            color:
                            sel ? Colors.white : AppTheme.text4),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: sel
                              ? (Theme.of(context).brightness ==
                              Brightness.dark
                              ? const Color(0xFF42A5F5)
                              : AppTheme.primary)
                              : AppTheme.text4,
                          fontWeight:
                          sel ? FontWeight.w700 : FontWeight.w400,
                        ),
                        child: Text(t.$3),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
