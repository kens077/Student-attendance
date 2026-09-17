import 'package:flutter/material.dart';

import 'screens/students_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/absentees_screen.dart';

void main() {
runApp(const StudentAttendanceApp());
}

class StudentAttendanceApp extends StatelessWidget {
const StudentAttendanceApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Attendance Management',
theme: ThemeData(
useMaterial3: true,
scaffoldBackgroundColor: const Color(0xFFF5F6F8),

colorScheme: ColorScheme.fromSeed(
seedColor: const Color(0xFF111827),
brightness: Brightness.light,
),

fontFamily: 'Roboto',

appBarTheme: const AppBarTheme(
backgroundColor: Color(0xFFF5F6F8),
foregroundColor: Color(0xFF111827),
elevation: 0,
centerTitle: false,
),

cardTheme: CardThemeData(
color: Colors.white,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
),

dividerTheme: const DividerThemeData(
color: Color(0xFFE7E9ED),
thickness: 1,
),
),
home: const HomeScreen(),
);
}
}

class HomeScreen extends StatelessWidget {
const HomeScreen({super.key});

void _openAttendance(BuildContext context) {
Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => const AttendanceScreen(),
),
);
}

void _openStudents(BuildContext context) {
Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => const StudentsScreen(),
),
);
}

void _openReports(BuildContext context) {
Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => const AbsenteesScreen(),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F6F8),

body: SafeArea(
child: SingleChildScrollView(
physics: const BouncingScrollPhysics(),

padding: const EdgeInsets.fromLTRB(
24,
24,
24,
32,
),

child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// ==========================================================
// HEADER
// ==========================================================

Row(
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: const Color(0xFF111827),
borderRadius: BorderRadius.circular(13),
),
child: const Icon(
Icons.school_outlined,
color: Colors.white,
size: 22,
),
),

const SizedBox(width: 13),

const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'ATTENDANCE',
style: TextStyle(
fontSize: 10,
letterSpacing: 1.4,
fontWeight: FontWeight.w700,
color: Color(0xFF8A909B),
),
),
SizedBox(height: 3),
Text(
'Management',
style: TextStyle(
fontSize: 17,
height: 1,
fontWeight: FontWeight.w700,
color: Color(0xFF111827),
),
),
],
),
),

Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: const Color(0xFFE4E7EB),
),
),
child: const Icon(
Icons.more_horiz_rounded,
size: 20,
color: Color(0xFF596170),
),
),
],
),

const SizedBox(height: 48),

// ==========================================================
// PAGE INTRODUCTION
// ==========================================================

const Text(
'CLASSROOM',
style: TextStyle(
fontSize: 10,
letterSpacing: 1.6,
fontWeight: FontWeight.w700,
color: Color(0xFF8A909B),
),
),

const SizedBox(height: 8),

const Text(
'Attendance,\nsimplified.',
style: TextStyle(
fontSize: 34,
height: 1.08,
letterSpacing: -0.8,
fontWeight: FontWeight.w800,
color: Color(0xFF111827),
),
),

const SizedBox(height: 12),

const Text(
'Manage student records, daily attendance and reports from a single workspace.',
style: TextStyle(
fontSize: 13.5,
height: 1.55,
color: Color(0xFF737A87),
),
),

const SizedBox(height: 32),

// ==========================================================
// PRIMARY ATTENDANCE ACTION
// ==========================================================

SizedBox(
width: double.infinity,
child: Material(
color: const Color(0xFF111827),
borderRadius: BorderRadius.circular(22),
child: InkWell(
onTap: () {
_openAttendance(context);
},
borderRadius: BorderRadius.circular(22),
child: Padding(
padding: const EdgeInsets.fromLTRB(
21,
20,
17,
20,
),

child: Row(
children: [
Container(
width: 48,
height: 48,
decoration: BoxDecoration(
color: Colors.white.withValues(
alpha: 0.08,
),
borderRadius: BorderRadius.circular(15),
border: Border.all(
color: Colors.white.withValues(
alpha: 0.08,
),
),
),
child: const Icon(
Icons.fact_check_outlined,
color: Colors.white,
size: 23,
),
),

const SizedBox(width: 15),

const Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'DAILY ATTENDANCE',
style: TextStyle(
fontSize: 10,
letterSpacing: 1.1,
fontWeight: FontWeight.w600,
color: Color(0xFF9CA3AF),
),
),
SizedBox(height: 5),
Text(
'Record attendance',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
color: Colors.white,
),
),
],
),
),

Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: Colors.white.withValues(
alpha: 0.08,
),
shape: BoxShape.circle,
),
child: const Icon(
Icons.arrow_forward_rounded,
color: Colors.white,
size: 19,
),
),
],
),
),
),
),
),

const SizedBox(height: 38),

// ==========================================================
// WORKSPACE
// ==========================================================

const Text(
'WORKSPACE',
style: TextStyle(
fontSize: 10,
letterSpacing: 1.6,
fontWeight: FontWeight.w700,
color: Color(0xFF8A909B),
),
),

const SizedBox(height: 14),

// Students
_PremiumMenuItem(
icon: Icons.people_outline_rounded,
title: 'Students',
subtitle: 'Manage student records',
onTap: () {
_openStudents(context);
},
),

const SizedBox(height: 10),

// Attendance
_PremiumMenuItem(
icon: Icons.fact_check_outlined,
title: 'Attendance',
subtitle: 'Record and review daily attendance',
onTap: () {
_openAttendance(context);
},
),

const SizedBox(height: 10),

// Reports
_PremiumMenuItem(
icon: Icons.description_outlined,
title: 'Reports',
subtitle: 'Review absentees and export records',
onTap: () {
_openReports(context);
},
),

const SizedBox(height: 38),

// ==========================================================
// FOOTER
// ==========================================================

Row(
children: [
Container(
width: 5,
height: 5,
decoration: const BoxDecoration(
color: Color(0xFF111827),
shape: BoxShape.circle,
),
),

const SizedBox(width: 8),

const Text(
'STUDENT ATTENDANCE',
style: TextStyle(
fontSize: 9,
letterSpacing: 1.3,
fontWeight: FontWeight.w600,
color: Color(0xFF9AA0AA),
),
),

const Spacer(),

const Text(
'2026',
style: TextStyle(
fontSize: 9,
letterSpacing: 1,
fontWeight: FontWeight.w600,
color: Color(0xFF9AA0AA),
),
),
],
),
],
),
),
),
);
}
}

// ======================================================================
// PREMIUM WORKSPACE ITEM
// ======================================================================

class _PremiumMenuItem extends StatelessWidget {
final IconData icon;
final String title;
final String subtitle;
final VoidCallback onTap;

const _PremiumMenuItem({
required this.icon,
required this.title,
required this.subtitle,
required this.onTap,
});

@override
Widget build(BuildContext context) {
return Material(
color: Colors.white,
borderRadius: BorderRadius.circular(18),

child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(18),

child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 15,
),

decoration: BoxDecoration(
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: const Color(0xFFE6E8EC),
),
),

child: Row(
children: [
Container(
width: 45,
height: 45,

decoration: BoxDecoration(
color: const Color(0xFFF3F4F6),
borderRadius: BorderRadius.circular(14),
),

child: Icon(
icon,
color: const Color(0xFF252B36),
size: 21,
),
),

const SizedBox(width: 14),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w700,
color: Color(0xFF171C26),
),
),

const SizedBox(height: 4),

Text(
subtitle,
style: const TextStyle(
fontSize: 11.5,
color: Color(0xFF858C98),
),
),
],
),
),

const Icon(
Icons.arrow_forward_ios_rounded,
size: 13,
color: Color(0xFF9AA0AA),
),
],
),
),
),
);
}
}





