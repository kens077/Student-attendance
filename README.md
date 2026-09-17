# Student Attendance Management App

## 📌 Project Overview

The **Student Attendance Management App** is a Flutter-based mobile application designed to simplify student management and daily attendance tracking.

The application allows users to import student information from an Excel file, store the data locally using SQLite, record attendance, and view students who are absent on a selected date.

The goal of the project is to provide a simple and efficient digital alternative to manually maintaining attendance records.

## 🚀 Key Features

### 1. Excel Student Import

* Import student data directly from an `.xlsx` Excel file.
* Supports the following columns:

  * Student Name
  * Roll Number
  * Course Name
* Automatically ignores incomplete rows.
* Prevents duplicate student entries from the same Excel file.
* Importing a new Excel file replaces the previously imported student data.

### 2. Student Management

* View all registered students.
* Search students by name, roll number, or course.
* Manually add students.
* Delete individual student records.
* Clear all stored student and attendance data when required.

### 3. Attendance Management

* Select an attendance date.
* Mark students as **Present** or **Absent**.
* Attendance records are stored locally.
* Existing attendance data can be retrieved for a selected date.

### 4. Absentee List

* View students marked absent for a particular date.
* Displays:

  * Student Name
  * Roll Number
  * Course Name
  * Attendance Date
  * Attendance Status

### 5. Local Database

The application uses **SQLite** for local data storage.

The main database tables are:

**Students**

* `id`
* `student_name`
* `roll_number`
* `course_name`

**Attendance**

* `id`
* `student_id`
* `attendance_date`
* `status`

## 🛠️ Technology Stack

* **Flutter**
* **Dart**
* **SQLite**
* **sqflite**
* **Excel**
* **File Picker**
* **Material UI**

## 🏗️ Application Structure

```text
lib/
├── database/
│   └── database_helper.dart
│
├── models/
│   └── student.dart
│
├── screens/
│   ├── students_screen.dart
│   ├── attendance_screen.dart
│   └── absentees_screen.dart
│
└── main.dart
```

### Database Helper

Handles SQLite database creation and operations such as:

* Creating tables
* Adding students
* Retrieving students
* Deleting students
* Saving attendance
* Retrieving attendance
* Retrieving absentee records
* Clearing application data

### Student Model

Represents student information within the Flutter application.

### Students Screen

Provides:

* Excel import
* Student search
* Student list
* Manual student creation
* Student deletion
* Data clearing

### Attendance Screen

Provides the interface for recording daily attendance.

### Absentees Screen

Displays students who were marked absent for the selected date.

## 🔄 How the Application Works

```text
Excel File
    ↓
Excel Data Processing
    ↓
Student Validation & Duplicate Checking
    ↓
SQLite Students Table
    ↓
Attendance Entry
    ↓
SQLite Attendance Table
    ↓
Absentee List
```

## 💡 Problem Solved

Traditional attendance management often involves paper registers or manually maintained spreadsheets. This can make searching, updating, and identifying absentees time-consuming.

This application provides a centralized mobile solution where student data and attendance records can be managed digitally and accessed quickly.

## 🎯 Future Improvements

Possible future enhancements include:

* PDF attendance reports
* Excel export
* Attendance percentage calculation
* Monthly attendance reports
* Student profile pages
* Cloud database synchronization
* Authentication and user accounts
* Push notifications
* Dashboard with attendance statistics

## 👨‍💻 Project Purpose

This project was developed to gain practical experience in:

* Flutter mobile application development
* SQLite database integration
* CRUD operations
* Excel file processing
* UI development
* Local data management
* Application architecture
* Handling real-world data workflows

