import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;

import '../database/database_helper.dart';
import '../models/student.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Student> students = [];
  List<Student> filteredStudents = [];

  bool isLoading = true;
  bool isImporting = false;

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadStudents();

    _searchController.addListener(() {
      _filterStudents(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD STUDENTS
  // ==========================================================

  Future<void> _loadStudents() async {
    try {
      final data = await _databaseHelper.getStudents();

      final loadedStudents = data.map((row) {
        return Student(
          id: row['id'] as int?,
          studentName: row['student_name'].toString(),
          rollNumber: row['roll_number'].toString(),
          courseName: row['course_name'].toString(),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        students = loadedStudents;
        filteredStudents = loadedStudents;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Unable to load student records.',
      );
    }
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  void _filterStudents(String query) {
    final search = query.trim().toLowerCase();

    if (search.isEmpty) {
      if (!mounted) return;

      setState(() {
        filteredStudents = students;
      });

      return;
    }

    final results = students.where((student) {
      return student.studentName
          .toLowerCase()
          .contains(search) ||
          student.rollNumber
              .toLowerCase()
              .contains(search) ||
          student.courseName
              .toLowerCase()
              .contains(search);
    }).toList();

    if (!mounted) return;

    setState(() {
      filteredStudents = results;
    });
  }

  // ==========================================================
  // ADD STUDENT
  // ==========================================================

  Future<void> _addStudent() async {
    final nameController = TextEditingController();
    final rollController = TextEditingController();
    final courseController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rollController,
                  decoration: const InputDecoration(
                    labelText: 'Roll Number',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    rollController.text.trim().isEmpty ||
                    courseController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(context, true);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final inserted =
      await _databaseHelper.insertStudent({
        'student_name': nameController.text.trim(),
        'roll_number': rollController.text.trim(),
        'course_name': courseController.text.trim(),
      });

      await _loadStudents();

      if (!mounted) return;

      if (inserted == 0) {
        _showMessage(
          'A student with the same roll number and course already exists.',
        );
      } else {
        _showMessage(
          'Student added successfully.',
        );
      }
    }

    nameController.dispose();
    rollController.dispose();
    courseController.dispose();
  }

  // ==========================================================
  // EXCEL CELL TEXT
  // ==========================================================

  String _getCellText(dynamic cell) {
    if (cell == null) {
      return '';
    }

    try {
      final value = cell.value;

      if (value == null) {
        return '';
      }

      return value.toString().trim();
    } catch (_) {
      return cell.toString().trim();
    }
  }

  // ==========================================================
  // IMPORT EXCEL
  // ==========================================================

  Future<void> _importExcel() async {
    if (isImporting) return;

    setState(() {
      isImporting = true;
    });

    try {
      // IMPORTANT:
      // Your installed file_picker uses the old API.
      final PlatformFile? file =
      await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (file == null) {
        return;
      }

      // Your file_picker version supports readAsBytes().
      final List<int> fileBytes =
      await file.readAsBytes();

      if (fileBytes.isEmpty) {
        throw Exception(
          'Unable to read the Excel file.',
        );
      }

      // ========================================================
      // DECODE EXCEL
      // ========================================================

      final excel.Excel excelData =
      excel.Excel.decodeBytes(fileBytes);

      if (excelData.tables.isEmpty) {
        throw Exception(
          'No worksheet found in the Excel file.',
        );
      }

      final String firstSheetName =
          excelData.tables.keys.first;

      final excel.Sheet? sheet =
      excelData.tables[firstSheetName];

      if (sheet == null) {
        throw Exception(
          'Unable to read the worksheet.',
        );
      }

      if (sheet.maxRows == 0) {
        throw Exception(
          'The Excel file is empty.',
        );
      }

      // ========================================================
      // FIND COLUMNS
      // ========================================================

      int nameColumn = -1;
      int rollColumn = -1;
      int courseColumn = -1;

      int headerRowIndex = -1;

      for (int rowIndex = 0;
      rowIndex < sheet.maxRows;
      rowIndex++) {
        final row = sheet.row(rowIndex);

        for (int columnIndex = 0;
        columnIndex < row.length;
        columnIndex++) {
          final String text =
          _getCellText(
            row[columnIndex],
          ).toLowerCase().trim();

          if (text == 'student name' ||
              text == 'student_name' ||
              text == 'name') {
            nameColumn = columnIndex;
          }

          if (text == 'roll number' ||
              text == 'roll_number' ||
              text == 'roll no' ||
              text == 'roll') {
            rollColumn = columnIndex;
          }

          if (text == 'course name' ||
              text == 'course_name' ||
              text == 'course') {
            courseColumn = columnIndex;
          }
        }

        if (nameColumn != -1 &&
            rollColumn != -1 &&
            courseColumn != -1) {
          headerRowIndex = rowIndex;
          break;
        }
      }

      if (nameColumn == -1 ||
          rollColumn == -1 ||
          courseColumn == -1) {
        throw Exception(
          'Required columns not found.\n\n'
              'Excel must contain:\n'
              'Student Name\n'
              'Roll Number\n'
              'Course Name',
        );
      }

      // ========================================================
      // READ STUDENT DATA
      // ========================================================

      final List<Map<String, String>>
      importedStudents = [];

      final Set<String> duplicateCheck = {};

      for (int rowIndex =
          headerRowIndex + 1;
      rowIndex < sheet.maxRows;
      rowIndex++) {
        final row = sheet.row(rowIndex);

        String studentName = '';
        String rollNumber = '';
        String courseName = '';

        if (nameColumn < row.length) {
          studentName =
              _getCellText(
                row[nameColumn],
              );
        }

        if (rollColumn < row.length) {
          rollNumber =
              _getCellText(
                row[rollColumn],
              );
        }

        if (courseColumn < row.length) {
          courseName =
              _getCellText(
                row[courseColumn],
              );
        }

        // Skip empty rows.
        if (studentName.isEmpty &&
            rollNumber.isEmpty &&
            courseName.isEmpty) {
          continue;
        }

        // Skip incomplete rows.
        if (studentName.isEmpty ||
            rollNumber.isEmpty ||
            courseName.isEmpty) {
          continue;
        }

        // ======================================================
        // DUPLICATE CHECK
        // ======================================================

        final String uniqueKey =
            '${rollNumber.toLowerCase().trim()}|'
            '${courseName.toLowerCase().trim()}';

        if (duplicateCheck.contains(uniqueKey)) {
          continue;
        }

        duplicateCheck.add(uniqueKey);

        importedStudents.add({
          'student_name': studentName.trim(),
          'roll_number': rollNumber.trim(),
          'course_name': courseName.trim(),
        });
      }

      if (importedStudents.isEmpty) {
        throw Exception(
          'No valid student records were found in the Excel file.',
        );
      }

      // ========================================================
      // CLEAR OLD DATA
      // ========================================================

      await _databaseHelper.clearAllData();

      // ========================================================
      // INSERT NEW DATA
      // ========================================================

      int importedCount = 0;

      for (final student in importedStudents) {
        final int inserted =
        await _databaseHelper.insertStudent(
          student,
        );

        if (inserted != 0) {
          importedCount++;
        }
      }

      // ========================================================
      // UPDATE SCREEN
      // ========================================================

      _searchController.clear();

      await _loadStudents();

      if (!mounted) return;

      _showMessage(
        '$importedCount student'
            '${importedCount == 1 ? '' : 's'} imported successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Excel import failed: $e',
        duration:
        const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          isImporting = false;
        });
      }
    }
  }

  // ==========================================================
  // CLEAR ALL DATA
  // ==========================================================

  Future<void> _clearAllData() async {
    if (isImporting) return;

    final bool? confirm =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Clear All Data',
          ),
          content: const Text(
            'This will remove all students and '
                'attendance records. This action cannot '
                'be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF111827),
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _databaseHelper.clearAllData();

      _searchController.clear();

      await _loadStudents();

      if (!mounted) return;

      _showMessage(
        'All student and attendance data cleared.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to clear data: $e',
        duration:
        const Duration(seconds: 4),
      );
    }
  }

  // ==========================================================
  // DELETE STUDENT
  // ==========================================================

  Future<void> _deleteStudent(
      Student student) async {
    if (student.id == null) return;

    final bool? confirm =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Remove Student',
          ),
          content: Text(
            'Remove ${student.studentName} '
                'from the student directory?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF111827),
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _databaseHelper.deleteStudent(
      student.id!,
    );

    await _loadStudents();

    if (!mounted) return;

    _showMessage(
      'Student record removed.',
    );
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showMessage(
      String message, {
        Duration duration =
        const Duration(seconds: 2),
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style:
            const TextStyle(
              fontSize: 12.5,
              fontWeight:
              FontWeight.w500,
            ),
          ),
          behavior:
          SnackBarBehavior.floating,
          duration: duration,
          margin:
          const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(13),
          ),
        ),
      );
  }

  // ==========================================================
  // STUDENT CARD
  // ==========================================================

  Widget _buildStudentCard(
      Student student) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 9,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border:
        Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                student.rollNumber,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF8A909B),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 1,
              height: 32,
              color:
              const Color(0xFFE7E9ED),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 14.5,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF171C26),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.courseName,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 11.5,
                      color:
                      Color(0xFF858C98),
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: () =>
                  _deleteStudent(student),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 19,
              ),
              color:
              const Color(0xFF8A909B),
              tooltip:
              'Remove student',
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    final bool isSearching =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 55,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border:
        Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFF3F4F6),
              borderRadius:
              BorderRadius.circular(17),
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 27,
              color:
              const Color(0xFF4B5563),
            ),
          ),

          const SizedBox(height: 17),

          Text(
            isSearching
                ? 'No Matching Records'
                : 'No Student Records',
            style:
            const TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF171C26),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            isSearching
                ? 'Try another name, roll number or course.'
                : 'Create a student record or import an Excel workbook.',
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              fontSize: 12,
              height: 1.5,
              color:
              Color(0xFF858C98),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6F8),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFFF5F6F8),
        foregroundColor:
        const Color(0xFF111827),
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Student Directory',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.w700,
            color:
            Color(0xFF111827),
          ),
        ),
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _addStudent,
        backgroundColor:
        const Color(0xFF111827),
        foregroundColor:
        Colors.white,
        elevation: 3,
        icon: const Icon(
          Icons.add_rounded,
          size: 20,
        ),
        label: const Text(
          'New Student',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
              color:
              Color(0xFF111827),
            ),
          ),
        )
            : RefreshIndicator(
          color:
          const Color(0xFF111827),
          onRefresh:
          _loadStudents,
          child:
          CustomScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding:
                const EdgeInsets
                    .fromLTRB(
                  22,
                  10,
                  22,
                  90,
                ),
                sliver:
                SliverList(
                  delegate:
                  SliverChildListDelegate(
                    [
                      // ==================================================
                      // HEADER
                      // ==================================================

                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child:
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STUDENT RECORDS',
                                  style:
                                  TextStyle(
                                    fontSize: 9.5,
                                    letterSpacing: 1.5,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    Color(0xFF8A909B),
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  'Directory',
                                  style:
                                  TextStyle(
                                    fontSize: 29,
                                    height: 1.05,
                                    fontWeight:
                                    FontWeight.w800,
                                    color:
                                    Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Manage student information and records.',
                                  style:
                                  TextStyle(
                                    fontSize: 12.5,
                                    color:
                                    Color(0xFF737A87),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 15),

                          Container(
                            width: 62,
                            padding:
                            const EdgeInsets
                                .symmetric(
                              vertical: 10,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              Colors.white,
                              borderRadius:
                              BorderRadius
                                  .circular(15),
                              border:
                              Border.all(
                                color:
                                const Color(
                                    0xFFE4E7EB),
                              ),
                            ),
                            child:
                            Column(
                              children: [
                                Text(
                                  '${students.length}',
                                  style:
                                  const TextStyle(
                                    fontSize: 19,
                                    height: 1,
                                    fontWeight:
                                    FontWeight.w800,
                                    color:
                                    Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'TOTAL',
                                  style:
                                  TextStyle(
                                    fontSize: 8,
                                    letterSpacing: 1,
                                    fontWeight:
                                    FontWeight.w600,
                                    color:
                                    Color(0xFF8A909B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 27),

                      // ==================================================
                      // SEARCH
                      // ==================================================

                      Container(
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.white,
                          borderRadius:
                          BorderRadius
                              .circular(16),
                          border:
                          Border.all(
                            color:
                            const Color(
                                0xFFE4E7EB),
                          ),
                        ),
                        child:
                        TextField(
                          controller:
                          _searchController,
                          style:
                          const TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w500,
                            color:
                            Color(0xFF171C26),
                          ),
                          decoration:
                          InputDecoration(
                            hintText:
                            'Search student records',
                            hintStyle:
                            const TextStyle(
                              fontSize: 12.5,
                              color:
                              Color(0xFF9AA0AA),
                            ),
                            prefixIcon:
                            const Icon(
                              Icons.search_rounded,
                              color:
                              Color(0xFF858C98),
                              size: 20,
                            ),
                            suffixIcon:
                            _searchController
                                .text
                                .isNotEmpty
                                ? IconButton(
                              onPressed:
                                  () {
                                _searchController
                                    .clear();
                              },
                              icon:
                              const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color:
                                Color(0xFF858C98),
                              ),
                            )
                                : null,
                            border:
                            InputBorder.none,
                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              vertical: 15,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // EXCEL IMPORT
                      // ==================================================

                      Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets.all(17),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                              0xFF111827),
                          borderRadius:
                          BorderRadius
                              .circular(19),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 43,
                              height: 43,
                              decoration:
                              BoxDecoration(
                                color:
                                Colors.white
                                    .withValues(
                                  alpha: 0.07,
                                ),
                                borderRadius:
                                BorderRadius
                                    .circular(13),
                              ),
                              child:
                              const Icon(
                                Icons
                                    .upload_file_outlined,
                                color:
                                Colors.white,
                                size: 21,
                              ),
                            ),

                            const SizedBox(width: 13),

                            const Expanded(
                              child:
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Import Records',
                                    style:
                                    TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.w700,
                                      color:
                                      Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Import student data from Excel',
                                    style:
                                    TextStyle(
                                      fontSize: 10.5,
                                      color:
                                      Color(0xFFAEB4BE),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 7),

                            // CLEAR
                            Tooltip(
                              message:
                              'Clear all data',
                              child:
                              SizedBox(
                                height: 37,
                                width: 42,
                                child:
                                OutlinedButton(
                                  onPressed:
                                  isImporting
                                      ? null
                                      : _clearAllData,
                                  style:
                                  OutlinedButton.styleFrom(
                                    foregroundColor:
                                    Colors.white,
                                    disabledForegroundColor:
                                    Colors.white38,
                                    side:
                                    BorderSide(
                                      color: Colors
                                          .white
                                          .withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                    padding:
                                    EdgeInsets.zero,
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          11),
                                    ),
                                  ),
                                  child:
                                  const Icon(
                                    Icons
                                        .refresh_rounded,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            // IMPORT
                            SizedBox(
                              height: 37,
                              child:
                              ElevatedButton(
                                onPressed:
                                isImporting
                                    ? null
                                    : _importExcel,
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Colors.white,
                                  foregroundColor:
                                  const Color(
                                      0xFF111827),
                                  disabledBackgroundColor:
                                  Colors.white24,
                                  disabledForegroundColor:
                                  Colors.white54,
                                  elevation: 0,
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal: 14,
                                  ),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        11),
                                  ),
                                ),
                                child:
                                isImporting
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  'Import',
                                  style:
                                  TextStyle(
                                    fontSize: 11.5,
                                    fontWeight:
                                    FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // DIRECTORY
                      // ==================================================

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Directory',
                              style:
                              TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(0xFF171C26),
                              ),
                            ),
                          ),
                          if (_searchController
                              .text
                              .isNotEmpty)
                            Text(
                              '${filteredStudents.length} results',
                              style:
                              const TextStyle(
                                fontSize: 10.5,
                                fontWeight:
                                FontWeight.w600,
                                color:
                                Color(0xFF858C98),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (filteredStudents.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredStudents.map(
                          _buildStudentCard,
                        ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration:
                            const BoxDecoration(
                              color:
                              Color(0xFF111827),
                              shape:
                              BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'STUDENT DIRECTORY',
                            style:
                            TextStyle(
                              fontSize: 8.5,
                              letterSpacing: 1.2,
                              fontWeight:
                              FontWeight.w600,
                              color:
                              Color(0xFF9AA0AA),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// DIALOG TEXT FIELD
// ======================================================================

class _DialogTextField
    extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(
      BuildContext context) {
    return TextField(
      controller: controller,
      style:
      const TextStyle(
        fontSize: 13,
        fontWeight:
        FontWeight.w500,
        color:
        Color(0xFF171C26),
      ),
      decoration:
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
        Icon(
          icon,
          size: 19,
          color:
          const Color(0xFF858C98),
        ),
        filled: true,
        fillColor:
        const Color(0xFFF5F6F8),
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(13),
          borderSide:
          BorderSide.none,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(13),
          borderSide:
          BorderSide.none,
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(13),
          borderSide:
          const BorderSide(
            color:
            Color(0xFF111827),
            width: 1,
          ),
        ),
      ),
    );
  }
}


