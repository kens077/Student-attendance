import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('student_attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_name TEXT NOT NULL,
        roll_number TEXT NOT NULL,
        course_name TEXT NOT NULL,
        UNIQUE(roll_number, course_name)
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');
  }

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    if (oldVersion < 2) {
      // Remove duplicate students before adding the unique constraint.
      await db.execute('''
        DELETE FROM students
        WHERE id NOT IN (
          SELECT MIN(id)
          FROM students
          GROUP BY roll_number, course_name
        )
      ''');

      // Recreate students table with unique constraint.
      await db.execute('''
        CREATE TABLE students_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          student_name TEXT NOT NULL,
          roll_number TEXT NOT NULL,
          course_name TEXT NOT NULL,
          UNIQUE(roll_number, course_name)
        )
      ''');

      await db.execute('''
        INSERT INTO students_new
        (id, student_name, roll_number, course_name)
        SELECT id, student_name, roll_number, course_name
        FROM students
      ''');

      await db.execute('DROP TABLE students');

      await db.execute('ALTER TABLE students_new RENAME TO students');
    }
  }

  // Insert student.
  // Duplicate Roll Number + Course Name will be ignored.
  Future<int> insertStudent(Map<String, dynamic> student) async {
    final db = await database;

    return await db.insert(
      'students',
      student,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    final db = await database;

    return await db.query(
      'students',
      orderBy: 'roll_number ASC',
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;

    await db.delete(
      'attendance',
      where: 'student_id = ?',
      whereArgs: [id],
    );

    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------
  // CLEAR ALL DATA
  // ---------------------------------------------------------

  Future<void> clearAllData() async {
    final db = await database;

    // Delete attendance first because it references students.
    await db.delete('attendance');

    // Then delete all students.
    await db.delete('students');
  }

  // ---------------------------------------------------------
  // ATTENDANCE
  // ---------------------------------------------------------

  Future<int> markAttendance(
      Map<String, dynamic> attendance,
      ) async {
    final db = await database;

    return await db.insert(
      'attendance',
      attendance,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAttendanceByDate(
      String date,
      ) async {
    final db = await database;

    return await db.query(
      'attendance',
      where: 'attendance_date = ?',
      whereArgs: [date],
    );
  }

  Future<List<Map<String, dynamic>>> getAbsenteesByDate(
      String date,
      ) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        students.id,
        students.student_name,
        students.roll_number,
        students.course_name,
        attendance.attendance_date,
        attendance.status
      FROM students
      INNER JOIN attendance
        ON students.id = attendance.student_id
      WHERE attendance.attendance_date = ?
        AND attendance.status = 'Absent'
      ORDER BY students.roll_number ASC
    ''', [date]);
  }

  // ---------------------------------------------------------
  // CLOSE DATABASE
  // ---------------------------------------------------------

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}