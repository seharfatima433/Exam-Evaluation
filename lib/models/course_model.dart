class Course {
  final int id;
  final String courseTitle;
  final String? courseCode;
  final int? totalStudents;

  const Course({
    required this.id,
    required this.courseTitle,
    this.courseCode,
    this.totalStudents,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: _parseInt(json['id']),
        courseTitle: json['course_title'] ?? json['title'] ?? 'Unknown',
        courseCode: json['course_code']?.toString(),
        totalStudents: _parseInt(json['total_students']),
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
