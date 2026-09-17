import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/student.dart';

class AttendanceScreen extends StatefulWidget {
const AttendanceScreen({super.key});

@override
State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

List<Student> students = [];

// student id -> Present / Absent
Map<int, String> attendanceStatus = {};

DateTime selectedDate = DateTime.now();

bool isLoading = true;
bool isSaving = false;

String get formattedDate {
return DateFormat('yyyy-MM-dd').format(selectedDate);
}

String get displayDate {
return DateFormat('dd MMM yyyy').format(selectedDate);
}

@override
void initState() {
super.initState();
_loadAttendance();
}

// ============================================================
// LOAD ATTENDANCE
// ============================================================

Future<void> _loadAttendance() async {
try {
setState(() {
isLoading = true;
});

final studentData = await _databaseHelper.getStudents();

final attendanceData =
await _databaseHelper.getAttendanceByDate(
formattedDate,
);

final List<Student> loadedStudents =
studentData.map((student) {
return Student.fromMap(student);
}).toList();

final Map<int, String> loadedAttendance = {};

for (final record in attendanceData) {
final dynamic studentId = record['student_id'];
final dynamic status = record['status'];

if (studentId != null && status != null) {
loadedAttendance[studentId as int] = status.toString();
}
}

if (!mounted) return;

setState(() {
students = loadedStudents;
attendanceStatus = loadedAttendance;
isLoading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
isLoading = false;
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Unable to load attendance: $e'),
behavior: SnackBarBehavior.floating,
),
);
}
}

// ============================================================
// SELECT DATE
// ============================================================

Future<void> _selectDate() async {
final DateTime? pickedDate = await showDatePicker(
context: context,
initialDate: selectedDate,
firstDate: DateTime(2020),
lastDate: DateTime(2100),
builder: (context, child) {
return Theme(
data: Theme.of(context).copyWith(
colorScheme: const ColorScheme.light(
primary: Color(0xFF172033),
onPrimary: Colors.white,
surface: Colors.white,
onSurface: Color(0xFF172033),
),
),
child: child!,
);
},
);

if (pickedDate == null) {
return;
}

setState(() {
selectedDate = pickedDate;
});

await _loadAttendance();
}

// ============================================================
// MARK PRESENT
// ============================================================

void _markPresent(Student student) {
if (student.id == null) {
return;
}

setState(() {
attendanceStatus[student.id!] = 'Present';
});
}

// ============================================================
// MARK ABSENT
// ============================================================

void _markAbsent(Student student) {
if (student.id == null) {
return;
}

setState(() {
attendanceStatus[student.id!] = 'Absent';
});
}

// ============================================================
// MARK ALL PRESENT
// ============================================================

void _markAllPresent() {
final Map<int, String> updatedStatus = {};

for (final student in students) {
if (student.id != null) {
updatedStatus[student.id!] = 'Present';
}
}

setState(() {
attendanceStatus = updatedStatus;
});
}

// ============================================================
// SAVE ATTENDANCE
// ============================================================

Future<void> _saveAttendance() async {
if (students.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('No students are available.'),
behavior: SnackBarBehavior.floating,
),
);
return;
}

final List<Student> notMarked = students.where((student) {
if (student.id == null) {
return false;
}

return !attendanceStatus.containsKey(student.id);
}).toList();

if (notMarked.isNotEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'${notMarked.length} student(s) still require attendance status.',
),
duration: const Duration(seconds: 3),
behavior: SnackBarBehavior.floating,
),
);
return;
}

try {
setState(() {
isSaving = true;
});

final existingAttendance =
await _databaseHelper.getAttendanceByDate(
formattedDate,
);

for (final record in existingAttendance) {
final dynamic id = record['id'];

if (id != null) {
await _deleteAttendanceRecord(id as int);
}
}

for (final student in students) {
if (student.id == null) {
continue;
}

final String? status =
attendanceStatus[student.id!];

if (status == null) {
continue;
}

await _databaseHelper.markAttendance({
'student_id': student.id,
'attendance_date': formattedDate,
'status': status,
});
}

if (!mounted) return;

setState(() {
isSaving = false;
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Attendance recorded for $displayDate',
),
duration: const Duration(seconds: 3),
behavior: SnackBarBehavior.floating,
),
);

await _loadAttendance();
} catch (e) {
if (!mounted) return;

setState(() {
isSaving = false;
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Unable to save attendance: $e',
),
duration: const Duration(seconds: 5),
behavior: SnackBarBehavior.floating,
),
);
}
}

// ============================================================
// DELETE ATTENDANCE RECORD
// ============================================================

Future<void> _deleteAttendanceRecord(int id) async {
final db = await _databaseHelper.database;

await db.delete(
'attendance',
where: 'id = ?',
whereArgs: [id],
);
}

// ============================================================
// COUNTS
// ============================================================

int get presentCount {
return attendanceStatus.values
    .where((status) => status == 'Present')
    .length;
}

int get absentCount {
return attendanceStatus.values
    .where((status) => status == 'Absent')
    .length;
}

int get markedCount {
return attendanceStatus.length;
}

int get pendingCount {
return students.length - markedCount;
}

// ============================================================
// BUILD
// ============================================================

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF7F8FA),

appBar: AppBar(
backgroundColor: const Color(0xFFF7F8FA),
foregroundColor: const Color(0xFF172033),
elevation: 0,
titleSpacing: 20,
title: const Text(
'Attendance',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w700,
color: Color(0xFF172033),
),
),
),

body: isLoading
? const Center(
child: CircularProgressIndicator(
color: Color(0xFF172033),
),
)
    : students.isEmpty
? _buildEmptyState()
    : Column(
children: [
Expanded(
child: RefreshIndicator(
color: const Color(0xFF172033),
onRefresh: _loadAttendance,
child: ListView(
padding: const EdgeInsets.fromLTRB(
20,
6,
20,
130,
),
children: [
_buildPageHeader(),

const SizedBox(height: 24),

_buildDateCard(),

const SizedBox(height: 18),

_buildOverviewCard(),

const SizedBox(height: 22),

_buildQuickAction(),

const SizedBox(height: 28),

Row(
children: [
const Expanded(
child: Text(
'Attendance register',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
color: Color(0xFF172033),
),
),
),
_buildProgressIndicator(),
],
),

const SizedBox(height: 14),

...students.map(
_buildStudentCard,
),
],
),
),
),
],
),

bottomNavigationBar: students.isEmpty
? null
    : SafeArea(
child: Container(
padding: const EdgeInsets.fromLTRB(
20,
12,
20,
14,
),
decoration: BoxDecoration(
color: const Color(0xFFF7F8FA),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(
alpha: 0.055,
),
blurRadius: 24,
offset: const Offset(0, -6),
),
],
),
child: SizedBox(
height: 55,
width: double.infinity,
child: ElevatedButton(
onPressed:
isSaving ? null : _saveAttendance,
style: ElevatedButton.styleFrom(
backgroundColor:
const Color(0xFF172033),
foregroundColor: Colors.white,
disabledBackgroundColor:
const Color(0xFF9BA1AC),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(17),
),
),
child: isSaving
? const Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
SizedBox(
width: 19,
height: 19,
child:
CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
),
SizedBox(width: 12),
Text(
'Recording attendance',
style: TextStyle(
fontSize: 14,
fontWeight:
FontWeight.w600,
),
),
],
)
    : const Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Icon(
Icons.check_rounded,
size: 20,
),
SizedBox(width: 9),
Text(
'Record Attendance',
style: TextStyle(
fontSize: 15,
fontWeight:
FontWeight.w700,
),
),
],
),
),
),
),
),
);
}

// ============================================================
// PAGE HEADER
// ============================================================

Widget _buildPageHeader() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Daily register',
style: TextStyle(
fontSize: 12.5,
color: Color(0xFF858B97),
fontWeight: FontWeight.w500,
letterSpacing: 0.2,
),
),
const SizedBox(height: 6),
const Text(
'Record Attendance',
style: TextStyle(
fontSize: 29,
height: 1.1,
fontWeight: FontWeight.w800,
color: Color(0xFF172033),
letterSpacing: -0.5,
),
),
const SizedBox(height: 8),
Text(
'Maintain an accurate attendance record for your class.',
style: const TextStyle(
fontSize: 13,
height: 1.45,
color: Color(0xFF858B97),
),
),
],
);
}

// ============================================================
// DATE CARD
// ============================================================

Widget _buildDateCard() {
return Material(
color: Colors.white,
borderRadius: BorderRadius.circular(21),
child: InkWell(
onTap: _selectDate,
borderRadius: BorderRadius.circular(21),
child: Container(
padding: const EdgeInsets.all(17),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(21),
border: Border.all(
color: const Color(0xFFE9EBEF),
),
),
child: Row(
children: [
Container(
width: 49,
height: 49,
decoration: BoxDecoration(
color: const Color(0xFF172033),
borderRadius: BorderRadius.circular(15),
),
child: const Icon(
Icons.calendar_today_rounded,
color: Colors.white,
size: 21,
),
),
const SizedBox(width: 14),
const Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Selected date',
style: TextStyle(
fontSize: 11.5,
color: Color(0xFF858B97),
fontWeight: FontWeight.w500,
),
),
SizedBox(height: 4),
Text(
'Attendance period',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
color: Color(0xFF172033),
),
),
],
),
),
Column(
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
Text(
displayDate,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
color: Color(0xFF172033),
),
),
const SizedBox(height: 4),
const Text(
'Change',
style: TextStyle(
fontSize: 10.5,
color: Color(0xFF858B97),
fontWeight: FontWeight.w500,
),
),
],
),
const SizedBox(width: 7),
const Icon(
Icons.chevron_right_rounded,
color: Color(0xFF9BA1AC),
size: 22,
),
],
),
),
),
);
}

// ============================================================
// OVERVIEW
// ============================================================

Widget _buildOverviewCard() {
return Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(21),
border: Border.all(
color: const Color(0xFFE9EBEF),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Attendance overview',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w700,
color: Color(0xFF172033),
),
),

const SizedBox(height: 16),

Row(
children: [
Expanded(
child: _overviewMetric(
value: presentCount,
label: 'Present',
),
),
_verticalDivider(),
Expanded(
child: _overviewMetric(
value: absentCount,
label: 'Absent',
),
),
_verticalDivider(),
Expanded(
child: _overviewMetric(
value: pendingCount,
label: 'Pending',
),
),
],
),
],
),
);
}

Widget _overviewMetric({
required int value,
required String label,
}) {
return Column(
children: [
Text(
value.toString(),
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.w800,
color: Color(0xFF172033),
),
),
const SizedBox(height: 4),
Text(
label,
style: const TextStyle(
fontSize: 10.5,
color: Color(0xFF858B97),
fontWeight: FontWeight.w500,
),
),
],
);
}

Widget _verticalDivider() {
return Container(
width: 1,
height: 38,
color: const Color(0xFFE9EBEF),
);
}

// ============================================================
// PROGRESS INDICATOR
// ============================================================

Widget _buildProgressIndicator() {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: const Color(0xFFF0F2F5),
borderRadius: BorderRadius.circular(10),
),
child: Text(
'$markedCount / ${students.length}',
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w700,
color: Color(0xFF626978),
),
),
);
}

// ============================================================
// QUICK ACTION
// ============================================================

Widget _buildQuickAction() {
return Material(
color: const Color(0xFF172033),
borderRadius: BorderRadius.circular(20),
child: InkWell(
onTap: students.isEmpty ? null : _markAllPresent,
borderRadius: BorderRadius.circular(20),
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 17,
vertical: 16,
),
child: Row(
children: [
Container(
width: 43,
height: 43,
decoration: BoxDecoration(
color: Colors.white.withValues(
alpha: 0.10,
),
borderRadius: BorderRadius.circular(13),
),
child: const Icon(
Icons.done_all_rounded,
color: Colors.white,
size: 21,
),
),
const SizedBox(width: 13),
const Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Set all as present',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
color: Colors.white,
),
),
SizedBox(height: 3),
Text(
'Apply present status to the entire register',
style: TextStyle(
fontSize: 11,
color: Colors.white60,
),
),
],
),
),
Container(
width: 31,
height: 31,
decoration: BoxDecoration(
color: Colors.white.withValues(
alpha: 0.10,
),
shape: BoxShape.circle,
),
child: const Icon(
Icons.arrow_forward_rounded,
color: Colors.white,
size: 16,
),
),
],
),
),
),
);
}

// ============================================================
// STUDENT CARD
// ============================================================

Widget _buildStudentCard(Student student) {
final String? status = student.id == null
? null
    : attendanceStatus[student.id!];

final String initial =
student.studentName.isNotEmpty
? student.studentName[0].toUpperCase()
    : '?';

return Container(
margin: const EdgeInsets.only(bottom: 12),
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: status == null
? const Color(0xFFE9EBEF)
    : const Color(0xFFDDE1E7),
),
),
child: Column(
children: [
Row(
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: const Color(0xFF172033),
borderRadius: BorderRadius.circular(15),
),
alignment: Alignment.center,
child: Text(
initial,
style: const TextStyle(
color: Colors.white,
fontSize: 16,
fontWeight: FontWeight.w700,
),
),
),

const SizedBox(width: 13),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
student.studentName,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w700,
color: Color(0xFF172033),
),
),
const SizedBox(height: 5),
Row(
children: [
Text(
'Roll ${student.rollNumber}',
style: const TextStyle(
fontSize: 11,
color: Color(0xFF858B97),
fontWeight: FontWeight.w500,
),
),
const SizedBox(width: 8),
Container(
width: 3,
height: 3,
decoration:
const BoxDecoration(
color: Color(0xFFB0B5BE),
shape: BoxShape.circle,
),
),
const SizedBox(width: 8),
Expanded(
child: Text(
student.courseName,
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 11,
color: Color(0xFF858B97),
),
),
),
],
),
],
),
),

if (status != null)
Container(
padding:
const EdgeInsets.symmetric(
horizontal: 9,
vertical: 6,
),
decoration: BoxDecoration(
color: status == 'Present'
? const Color(0xFF172033)
    : const Color(0xFFF0F2F5),
borderRadius:
BorderRadius.circular(9),
),
child: Text(
status,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w700,
color: status == 'Present'
? Colors.white
    : const Color(0xFF626978),
),
),
),
],
),

const SizedBox(height: 13),

Row(
children: [
Expanded(
child: _attendanceButton(
label: 'Present',
icon: Icons.check_rounded,
isSelected: status == 'Present',
onPressed: () {
_markPresent(student);
},
),
),
const SizedBox(width: 9),
Expanded(
child: _attendanceButton(
label: 'Absent',
icon: Icons.close_rounded,
isSelected: status == 'Absent',
onPressed: () {
_markAbsent(student);
},
),
),
],
),
],
),
);
}

// ============================================================
// ATTENDANCE BUTTON
// ============================================================

Widget _attendanceButton({
required String label,
required IconData icon,
required bool isSelected,
required VoidCallback onPressed,
}) {
return SizedBox(
height: 44,
child: ElevatedButton.icon(
onPressed: onPressed,
icon: Icon(
icon,
size: 17,
),
label: Text(
label,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
style: ElevatedButton.styleFrom(
backgroundColor: isSelected
? const Color(0xFF172033)
    : const Color(0xFFF7F8FA),
foregroundColor: isSelected
? Colors.white
    : const Color(0xFF626978),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(13),
side: BorderSide(
color: isSelected
? const Color(0xFF172033)
    : const Color(0xFFE4E7EB),
),
),
),
),
);
}

// ============================================================
// EMPTY STATE
// ============================================================

Widget _buildEmptyState() {
return Center(
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 35,
vertical: 90,
),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
width: 78,
height: 78,
decoration: BoxDecoration(
color: const Color(0xFF172033),
borderRadius: BorderRadius.circular(24),
),
child: const Icon(
Icons.fact_check_outlined,
size: 35,
color: Colors.white,
),
),

const SizedBox(height: 22),

const Text(
'Register is empty',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.w700,
color: Color(0xFF172033),
),
),

const SizedBox(height: 8),

const Text(
'Add students to the directory before recording attendance.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 13,
height: 1.5,
color: Color(0xFF858B97),
),
),
],
),
),
);
}
}

