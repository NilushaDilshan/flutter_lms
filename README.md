# Flutter LMS Mobile Application

A comprehensive Learning Management System (LMS) mobile application built with Flutter and integrated with a Node.js / MongoDB backend. Designed for three role-based experiences: **Student**, **Instructor**, and **Admin**.

---

## 📋 Project Overview

The **Flutter LMS** application provides a full-featured online learning and management experience:
- **Student**: Course discovery, enrollment, multimedia lessons (Video, Text, Document), interactive quizzes, assignment submissions (text/file uploads), and course reviews.
- **Instructor**: End-to-end course builder, section & lesson authoring, quiz/assignment creation, and grading student submissions.
- **Admin**: User lifecycle management (activate/suspend), category administration, review moderation, and overall platform monitoring.

---

## 🏗️ Architecture & Folder Structure

The project follows a clean, feature-based modular architecture:

```
lib/
├── core/
│   ├── api/             # Dio client, interceptors, error handling
│   ├── config/          # App constants, environment settings
│   ├── constants/       # AppColors, AppStrings, AppStyles
│   ├── storage/         # TokenStorage (flutter_secure_storage)
│   ├── theme/           # AppTheme (Material 3, Google Fonts)
│   └── widgets/         # Reusable CustomTextField, CustomButton, etc.
├── features/
│   ├── auth/            # Login, Registration, OTP, Password Reset
│   ├── dashboard/       # Student, Instructor & Admin dashboard shells
│   ├── courses/         # Course catalog, details, categories
│   ├── lessons/         # Video, Text, and Document lesson players
│   ├── assessments/     # Quizzes & Assignments
│   ├── profile/         # User profile management & photo upload
│   └── admin/           # Platform & user management
└── main.dart            # Application entry point
```

---

## 🐳 Docker Backend Setup

The backend is packaged as a pre-configured Docker image.

### Run Backend Container
```bash
docker pull dckuma/flutter-lms-backend:v1.0.0
docker run -d --name flutter-lms-backend --restart unless-stopped -p 5000:5000 dckuma/flutter-lms-backend:v1.0.0
```

### Health & Container Management
```bash
# Check status
docker ps
docker inspect --format "{{.State.Health.Status}}" flutter-lms-backend

# Logs
docker logs -f flutter-lms-backend

# Stop / Start / Restart
docker stop flutter-lms-backend
docker start flutter-lms-backend
docker restart flutter-lms-backend
```

---

## 🌐 Network Configuration

| Environment | Base URL | Note |
| :--- | :--- | :--- |
| **Postman (Windows Host)** | `http://localhost:5000` | Used for collection testing |
| **Android Emulator** | `http://10.0.2.2:5000` | Points to Windows host Docker container |

> **Note**: Do not append `/api/v1` to the base URL because endpoint routes include `/api/v1` (e.g. `http://10.0.2.2:5000/api/v1/auth/login`).

---

## 📦 Required Materials

- **Backend API Report**: [Google Drive Link](https://drive.google.com/file/d/1Ld_IvM_4GHhoaakGetEbuWAv5LH_aCf3/view?usp=sharing)
- **Mobile API Integration Guide**: [Google Drive Link](https://drive.google.com/file/d/18kwcNqfnkxLb0TZER_TNbocSUFs4Acl2/view?usp=sharing)
- **Postman Collection JSON**: [Google Drive Link](https://drive.google.com/file/d/16DjEWlX0f889g6Njln-8Iy38kxUlBXKc/view?usp=sharing)

---

## 📅 10-Day Implementation Progress

- [x] **Day 1: Setup, Project Initialization & Shared Login UI**
  - Flutter SDK & Android SDK verification via `flutter doctor`.
  - Initialized clean Flutter project with Material 3 styling.
  - Built shared `LoginScreen` with role switcher (Student, Instructor, Admin), form validation, and demo autofill.
  - Created reusable UI components (`CustomTextField`, `CustomButton`, `AppTheme`, `AppColors`).
  - Added smoke tests in `widget_test.dart`.
  - Configured git repository with Conventional Commits.
- [ ] **Day 2: Navigation, Forms, Validation, Assets and Theme**
- [ ] **Day 3: Splash, Onboarding, Role Dashboards and Standard UI States**
- [ ] **Day 4: Docker Backend, Postman and Core API Setup**
- [ ] **Day 5: Authentication, Session Management, Password Recovery and Profiles**
- [ ] **Day 6: Course Browse, Enrollment, Curriculum, Lessons and Progress**
- [ ] **Day 7: Quizzes, Assignments, Reviews, Notifications and Student Profile UX**
- [ ] **Day 8: Instructor Course Building and Learner Management**
- [ ] **Day 9: Admin Management, State Management, Bottom Navigation and Animations**
- [ ] **Day 10: Responsive Design, Full Testing, UI/UX Polish and Final Submission**

---

## 📜 Git Commit Message Standard

Commits adhere to the Conventional Commits specification:
`<type>(<optional-scope>): <short description>`

- `feat`: Adding new features (e.g., `feat(auth): implement student login UI`)
- `fix`: Bug fixes (e.g., `fix(ui): resolve overflow on small devices`)
- `docs`: Documentation updates (e.g., `docs: update setup instructions in README`)
- `style`: Formatting changes
- `refactor`: Code restructuring
