import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

class AbsenteesScreen extends StatefulWidget {
  const AbsenteesScreen({super.key});

  @override
  State<AbsenteesScreen> createState() => _AbsenteesScreenState();
}

class _AbsenteesScreenState extends State<AbsenteesScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> absentees = [];

  bool isLoading = true;
  bool isPrinting = false;

  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(selectedDate);
  }

  String get displayDate {
    return DateFormat('dd MMM yyyy').format(selectedDate);
  }

  @override
  void initState() {
    super.initState();
    _loadAbsentees();
  }

  Future<void> _loadAbsentees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result =
      await _databaseHelper.getAbsenteesByDate(formattedDate);

      if (!mounted) return;

      setState(() {
        absentees = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading absentees: $e'),
        ),
      );
    }
  }

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

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });

      await _loadAbsentees();
    }
  }

  String _getInitials(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return '?';
    }

    final parts = trimmedName.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
        '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _generatePdf() async {
    if (absentees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No absentees to generate a report.'),
        ),
      );
      return;
    }

    setState(() {
      isPrinting = true;
    });

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              pw.Text(
                'STUDENT ATTENDANCE',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Text(
                'Absentee Report',
                style: const pw.TextStyle(
                  fontSize: 15,
                ),
              ),

              pw.SizedBox(height: 4),

              pw.Text(
                'Date: $displayDate',
                style: const pw.TextStyle(
                  fontSize: 11,
                ),
              ),

              pw.SizedBox(height: 22),

              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Absentees',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${absentees.length}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                headers: [
                  'No.',
                  'Student Name',
                  'Roll Number',
                  'Course',
                  'Status',
                ],
                data: List.generate(
                  absentees.length,
                      (index) {
                    final student = absentees[index];

                    return [
                      '${index + 1}',
                      student['student_name']?.toString() ?? '',
                      student['roll_number']?.toString() ?? '',
                      student['course_name']?.toString() ?? '',
                      'Absent',
                    ];
                  },
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 9,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(7),
              ),

              pw.SizedBox(height: 25),

              pw.Text(
                'Generated by Student Attendance App',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey,
                ),
              ),
            ];
          },
        ),
      );

      // Generate PDF bytes.
      final bytes = await pdf.save();

      // Get app documents directory.
      final directory =
      await getApplicationDocumentsDirectory();

      // Create reports folder.
      final reportsDirectory = Directory(
        '${directory.path}/attendance_reports',
      );

      if (!await reportsDirectory.exists()) {
        await reportsDirectory.create(
          recursive: true,
        );
      }

      // PDF file name.
      final filePath =
          '${reportsDirectory.path}/Absentee_Report_$formattedDate.pdf';

      // Save PDF.
      final file = File(filePath);

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      if (!mounted) return;

      setState(() {
        isPrinting = false;
      });

      // Share/open the generated PDF using Android's
      // native share sheet.
      await SharePlus.instance.share(
        ShareParams(
          text: 'Student Attendance - Absentee Report',
          subject: 'Absentee Report - $displayDate',
          files: [
            XFile(
              filePath,
              mimeType: 'application/pdf',
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isPrinting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error generating PDF: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,

        title: const Text(
          'Absentees & Reports',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loadAbsentees,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF172033),
        ),
      )
          : RefreshIndicator(
        color: const Color(0xFF172033),
        onRefresh: _loadAbsentees,

        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            110,
          ),

          children: [
            // DATE CARD
            Material(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(22),

              child: InkWell(
                onTap: _selectDate,
                borderRadius:
                BorderRadius.circular(22),

                child: Container(
                  padding:
                  const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(22),

                    border: Border.all(
                      color:
                      const Color(0xFFE8EAF0),
                    ),
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,

                        decoration:
                        BoxDecoration(
                          color:
                          const Color(0xFFF0F2F5),
                          borderRadius:
                          BorderRadius.circular(16),
                        ),

                        child: const Icon(
                          Icons
                              .calendar_month_rounded,
                          color:
                          Color(0xFF172033),
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [
                            const Text(
                              'Attendance date',
                              style: TextStyle(
                                color:
                                Color(0xFF858B97),
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              displayDate,
                              style:
                              const TextStyle(
                                color:
                                Color(0xFF172033),
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons
                            .chevron_right_rounded,
                        color:
                        Color(0xFF9BA1AC),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // SUMMARY CARD
            Container(
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: const Color(0xFF172033),
                borderRadius:
                BorderRadius.circular(22),
              ),

              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,

                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.10),
                      borderRadius:
                      BorderRadius.circular(16),
                    ),

                    child: const Icon(
                      Icons.person_off_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Total absentees',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Students absent today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '${absentees.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // EMPTY STATE
            if (absentees.isEmpty)
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 55,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(22),
                  border: Border.all(
                    color:
                    const Color(0xFFE8EAF0),
                  ),
                ),

                child: const Column(
                  children: [
                    Icon(
                      Icons
                          .check_circle_outline_rounded,
                      size: 62,
                      color:
                      Color(0xFF172033),
                    ),

                    SizedBox(height: 18),

                    Text(
                      'No absentees',
                      style: TextStyle(
                        color:
                        Color(0xFF172033),
                        fontSize: 20,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'All students were present on this date.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color:
                        Color(0xFF858B97),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )

            // ABSENTEE LIST
            else
              ...List.generate(
                absentees.length,
                    (index) {
                  final student =
                  absentees[index];

                  final name =
                      student['student_name']
                          ?.toString() ??
                          '';

                  final roll =
                      student['roll_number']
                          ?.toString() ??
                          '';

                  final course =
                      student['course_name']
                          ?.toString() ??
                          '';

                  return Container(
                    margin:
                    const EdgeInsets.only(
                      bottom: 12,
                    ),

                    padding:
                    const EdgeInsets.all(17),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                        color:
                        const Color(0xFFE8EAF0),
                      ),
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,

                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFF0F2F5,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(15),
                          ),

                          child: Center(
                            child: Text(
                              _getInitials(name),
                              style:
                              const TextStyle(
                                color:
                                Color(0xFF172033),
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            children: [
                              Text(
                                name,
                                style:
                                const TextStyle(
                                  color: Color(
                                      0xFF172033),
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),

                              const SizedBox(
                                  height: 5),

                              Text(
                                'Roll No. $roll',
                                style:
                                const TextStyle(
                                  color: Color(
                                      0xFF858B97),
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(
                                  height: 2),

                              Text(
                                course,
                                style:
                                const TextStyle(
                                  color: Color(
                                      0xFF858B97),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),

                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFF2F3F5,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(10),
                          ),

                          child: const Text(
                            'ABSENT',
                            style:
                            TextStyle(
                              color:
                              Color(0xFF172033),
                              fontSize: 10,
                              fontWeight:
                              FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),

      // EXPORT PDF BUTTON
      floatingActionButton: absentees.isEmpty
          ? null
          : FloatingActionButton.extended(
        onPressed:
        isPrinting ? null : _generatePdf,

        backgroundColor:
        const Color(0xFF172033),

        foregroundColor: Colors.white,

        icon: isPrinting
            ? const SizedBox(
          width: 19,
          height: 19,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(
          Icons.picture_as_pdf_rounded,
        ),

        label: Text(
          isPrinting
              ? 'Creating PDF...'
              : 'Export PDF',
        ),
      ),
    );
  }
}