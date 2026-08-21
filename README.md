# 🎓 EduMate

> A modern college management application built with Flutter, Firebase, and Supabase.

EduMate is a private college management application designed to connect **students, teachers, and administrators** through a single platform.

The application provides dedicated dashboards and academic management features including attendance, marks, timetable, notices, study materials, fee information, PPT submissions, and student management.

---

## 🔐 Access & Usage

**EduMate is a private application.**

The application and source code are **not intended for unrestricted public use, redistribution, or commercial use**.

If you would like to use, test, deploy, customize, or obtain access to EduMate, please **contact the developer and request permission first**.

### 📩 Request Access

**Developer:** Rohan Mondal

**GitHub:** https://github.com/Rohanmon80

Permission may be granted on a case-by-case basis.

---

## 📱 Screenshots

### Student

| Dashboard | Attendance |
|---|---|
| ![Student Dashboard](assets/screenshots/student_dashboard.png) | ![Student Attendance](assets/screenshots/student_attendance.png) |

| PPT Upload | Timetable |
|---|---|
| ![Student PPT Upload](assets/screenshots/student_ppt_upload.png) | ![Student Timetable](assets/screenshots/student_timetable.png) |

### Teacher

| Dashboard | Attendance |
|---|---|
| ![Teacher Dashboard](assets/screenshots/teacher_dashboard.png) | ![Teacher Attendance](assets/screenshots/teacher_attendance.png) |

| Marks | PPT Submissions |
|---|---|
| ![Teacher Marks](assets/screenshots/teacher_marks.png) | ![Teacher PPT Submissions](assets/screenshots/teacher_ppt_submissions.png) |

### Admin

| Dashboard | Student Management |
|---|---|
| ![Admin Dashboard](assets/screenshots/admin_dashboard.png) | ![Admin Student Management](assets/screenshots/admin_student_management.png) |

| Fee Management | Reports |
|---|---|
| ![Admin Fee Management](assets/screenshots/admin_fee_management.png) | ![Admin Reports](assets/screenshots/admin_reports.png) |

---

# ✨ Features

## 👨‍🎓 Student

- Student dashboard
- Student profile
- Attendance viewing
- Results and marks
- Timetable
- Notices
- Study materials
- Fee information
- Exam-related information
- Mid-examination PPT submission
- Teacher selection while submitting PPT
- PPT file upload using Supabase Storage

### 📑 PPT Submission

Students can:

1. Enter a PPT title.
2. Select the teacher who should receive the presentation.
3. Select a `.ppt` or `.pptx` file.
4. Submit the presentation.
5. Store submission details in Firestore.

The selected teacher is associated with the submission using the teacher's Firebase identity.

---

# 👨‍🏫 Teacher

- Teacher dashboard
- Attendance management
- Student roll-number list
- Present/Absent attendance marking
- Attendance history
- Marks management
- Timetable
- Notices
- Study materials
- Student PPT submissions

### 📑 PPT Submissions

Teachers can view PPTs submitted specifically to them.

The teacher page displays:

- Student name
- Roll number
- Department
- Year
- Semester
- Section
- PPT title
- PPT filename
- Submission date and time
- Submission status
- View PPT option

A teacher sees submissions assigned to their teacher account.

---

# 👨‍💼 Admin

- Admin dashboard
- Student management
- Teacher management
- Attendance management
- Fee management
- Reports
- Examination management
- Notice management

### 👨‍🎓 Student Management

The admin can manage student information and the student database.

---

# 🔐 Authentication

EduMate uses **Firebase Authentication** for user identity.

The application supports three main roles:

```text
Student
Teacher
Admin
```

Each role has a dedicated dashboard and role-specific functionality.

---

# 🏗️ Technology Stack

### Frontend

- Flutter
- Dart
- Material Design

### Authentication & Database

- Firebase Authentication
- Cloud Firestore

### File Storage

- Supabase Storage

Supabase Storage is used for uploaded files such as PowerPoint presentations and other supported documents.

---

# ☁️ Application Architecture

```text
                         EduMate
                            │
             ┌──────────────┼──────────────┐
             │              │              │
          Student        Teacher          Admin
             │              │              │
             └──────────────┼──────────────┘
                            │
                     Firebase Auth
                            │
                            ▼
                     User Identity
                            │
                            ▼
                     Cloud Firestore
                            │
             ┌──────────────┼──────────────┐
             │              │              │
          Students       Teachers      PPT Metadata
                                           │
                                           ▼
                                   Supabase Storage
                                           │
                                           ▼
                                      PPT Files
```

---

# 📑 PPT Submission Architecture

The PPT system uses three services:

```text
Firebase Auth
      ↓
Student / Teacher Identity

Firestore
      ↓
PPT Submission Metadata

Supabase Storage
      ↓
Actual .ppt / .pptx File
```

A submission stores information such as:

```text
studentUid
studentName
rollNumber

department
year
semester
section

pptTitle
fileName
fileUrl

teacherId
teacherUid
teacherName

submittedAt
status
```

The selected teacher's UID is stored with the submission so that the teacher application can display submissions assigned to that teacher.

---

# 📁 Project Structure

```text
EduMate/
│
├── README.md
├── COPYRIGHT.md
├── pubspec.yaml
│
├── assets/
│   └── screenshots/
│       ├── splash_screen.png
│       ├── role_selection.png
│       ├── student_dashboard.png
│       ├── student_attendance.png
│       ├── student_ppt_upload.png
│       ├── student_timetable.png
│       ├── teacher_dashboard.png
│       ├── teacher_attendance.png
│       ├── teacher_marks.png
│       ├── teacher_ppt_submissions.png
│       ├── teacher_materials.png
│       ├── admin_dashboard.png
│       ├── admin_student_management.png
│       ├── admin_fee_management.png
│       └── admin_reports.png
│
├── lib/
│   ├── student/
│   ├── teacher/
│   ├── admin/
│   ├── services/
│   ├── timetables/
│   ├── firebase_options.dart
│   ├── main.dart
│   └── splash_screen.dart
│
├── android/
├── ios/
└── web/
```

---

# 🚀 Getting Started

> Access to this project requires permission from the developer.

If access has been granted:

### 1. Clone the repository

```bash
git clone YOUR_REPOSITORY_URL
cd EduMate
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Configure Firebase for the required platform and ensure the generated Firebase configuration is available to the project.

### 4. Configure Supabase

Supabase is initialized in `main.dart`.

The PPT submission system uses the:

```text
student-ppts
```

Storage bucket for PowerPoint files.

### 5. Run the application

```bash
flutter run
```

---

# 📦 Build APK

To create a release APK:

```bash
flutter build apk --release
```

The APK will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

# 🔒 Security & Privacy

EduMate uses:

- Firebase Authentication for user identity
- Firestore for application and submission metadata
- Supabase Storage for uploaded files

Storage policies should be configured correctly before production deployment.

Access to the source code and application is restricted according to the terms in `COPYRIGHT.md`.

---

# 🔮 Future Improvements

Possible future improvements include:

- Push notifications
- Assignment management
- PPT grading and teacher feedback
- Student leave requests
- Online fee payment
- Advanced attendance analytics
- Exam result notifications
- Parent/guardian portal
- Online examinations
- Student-teacher communication
- Advanced administrative reports
- Private storage with signed URLs

---

# 👨‍💻 Developer

**Rohan Mondal**

B.Tech — Artificial Intelligence & Machine Learning

GitHub:  
https://github.com/Rohanmon80

---

# 📄 License & Copyright

EduMate is **proprietary software**.

See [`COPYRIGHT.md`](COPYRIGHT.md) for the usage and copyright terms.

**Unauthorized use, redistribution, or commercial use is not permitted without permission from the developer.**
