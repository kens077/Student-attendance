class Student {
  final int? id;
  final String studentName;
  final String rollNumber;
  final String courseName;

  Student({
    this.id,
    required this.studentName,
    required this.rollNumber,
    required this.courseName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_name': studentName,
      'roll_number': rollNumber,
      'course_name': courseName,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      studentName: map['student_name'],
      rollNumber: map['roll_number'],
      courseName: map['course_name'],
    );
  }
}