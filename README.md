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
- [x] **Day 2: Navigation, Forms, Validation, Assets and Theme**
  - Configured named route architecture (`AppRoutes`, `RouteGenerator`).
  - Implemented role-based navigation flow from Login to Student, Instructor, and Admin dashboards.
  - Added role dashboard shells (`StudentDashboardScreen`, `InstructorDashboardScreen`, `AdminDashboardScreen`).
  - Added reusable components (`ConfirmationDialog`, `SectionHeader`, `StatusBadge`, `AppMessageWidget`).
  - Configured assets folders (`assets/images/`, `assets/icons/`) in `pubspec.yaml`.
  - Added navigation & dialog tests in `widget_test.dart`.
- [x] **Day 3: Splash, Onboarding, Role Dashboards and Standard UI States**
  - Created animated `SplashScreen` with logo scaling and auto-timer navigation.
  - Built complete 3-screen `OnboardingScreen` using `PageView`, dot indicators, and PopScope back handling.
  - Created reusable Standard UI State widgets (`LoadingStateWidget`, `EmptyStateWidget`, `ErrorStateWidget`, `SuccessStateWidget`).
  - Added UI State simulator bar to `StudentDashboardScreen` for verifying loading, empty, and error views.
  - Added unit and widget tests in `widget_test.dart` for splash, onboarding, UI states, and login.
- [x] **Day 4: Docker Backend, Postman and Core API Setup**
  - Documented Docker container setup (`dckuma/flutter-lms-backend:v1.0.0`) and host port mapping (`5000:5000`).
  - Configured `AppConfig` with emulator base URL (`http://10.0.2.2:5000`) and network timeout definitions.
  - Implemented `ApiEndpoints` contract matching the complete Postman collection.
  - Built encrypted `TokenStorage` with `flutter_secure_storage` for access/refresh tokens and session persistence.
  - Built `ApiException` and `ApiResponse` for clean HTTP status code and validation error mapping.
  - Implemented `AuthInterceptor` with automated Bearer injection and single-retry refresh-token rotation.
  - Built `ApiClient` with Dio for GET, POST, PUT, PATCH, DELETE and multipart FormData upload.
  - Added unit test suite in `test/api_client_test.dart` (10/10 tests passing).
- [x] **Day 5: Authentication, Session Management, Password Recovery and Profiles**
  - Implemented `AuthProvider` with login, register (Student/Instructor), OTP email verification, forgot-password 3-step flow, logout, and session restore via `TokenStorage`.
  - Built `UserModel`, `AuthTokensModel`, `StudentProfileModel`, and `InstructorProfileModel` with full JSON serialization and `copyWith` support.
  - Built `ProfileProvider` with full profile fetch, role-specific profile update, multipart image upload/delete (`profileImage` key), and change-password flow.
  - Created `RegisterScreen` (tabbed Student/Instructor), `OtpVerificationScreen` (60 s countdown + resend), `ForgotPasswordScreen` (3-step indicator), and `ProfileScreen` (avatar camera upload, security settings).
  - Connected `LoginScreen` to `AuthProvider` with real backend call, role-based navigation, and offline demo fallback.
  - Added Profile icon to all three role dashboards navigating to `/profile`.
  - Expanded test suite to 16 tests across `widget_test.dart` and `api_client_test.dart` — all passing.
- [x] **Day 6: Course Browse, Enrollment, Curriculum, Lessons and Progress**
  - Implemented `CategoryModel`, `CourseModel`, `SectionModel`, `LessonModel` (with `LessonType` for TEXT, VIDEO, DOCUMENT), `EnrollmentModel`, and `CourseProgressModel`.
  - Built `CourseProvider` integrating backend API endpoints for categories, published courses, course details, curriculum sections, enrollments, and progress tracking.
  - Created `CourseCatalogScreen` with real-time search, dynamic category filter chips, difficulty level filter, and responsive course cards.
  - Created `CourseDetailScreen` with collapsible hero thumbnail, metadata overview, interactive curriculum accordion, and sticky bottom enrollment bar.
  - Created `LessonPlayerScreen` supporting all three lesson modalities: Video Player with progress slider, Text reading view with rich formatting, and Document view with download/view capabilities.
  - Implemented lesson progress tracking: automated lesson start marking and "Mark as Completed" with backend sync (`PATCH /api/v1/lessons/:id/complete`).
  - Created `MyCoursesScreen` displaying enrolled courses with completion percentages and direct resume actions.
  - Registered `CourseProvider` in `MultiProvider` and mapped all routes (`/courses`, `/course-detail`, `/lesson-player`, `/my-courses`) in `RouteGenerator`.
  - Expanded unit and widget test suite to 28 passing tests in total (`courses_test.dart`, `widget_test.dart`, and `api_client_test.dart`).
- [x] **Day 7: Quizzes, Assignments, Reviews, Notifications and Student Profile UX**
  - Implemented `QuizModel`, `QuizAttemptModel`, `AssignmentModel`, `AssignmentSubmissionModel`, and `NotificationModel`.
  - Built `QuizProvider`, `AssignmentProvider`, and `NotificationProvider` with real backend calls and demo fallbacks.
  - Created `QuizListScreen` and interactive `QuizAttemptScreen` with timer countdown, single/multi-choice questions, and score summary dialogs.
  - Created `AssignmentListScreen` and `AssignmentDetailScreen` with written answer submission, simulated file attachment, and graded status views.
  - Created `NotificationScreen` with mark-as-read and dismissible actions.
  - Added Day 7 test suite in `test/day7_assessment_test.dart`.
- [x] **Day 8: Instructor Course Building and Learner Management**
  - Implemented `InstructorDashboardModel` and comprehensive `InstructorProvider` covering course CRUD, section authoring, lesson uploads, quizzes, assignments, and learner grading.
  - Created `InstructorDashboardScreen` with live metrics, course status filters, and studio navigation.
  - Created `CourseCreateEditScreen` for course authoring with category selection and pricing settings.
  - Created `CourseStudioScreen` with a 3-tab experience (Curriculum sections/lessons, Assessments authoring, and Learners progress).
  - Created `InstructorSubmissionsScreen` for grading assignments with marks and instructor feedback.
  - Created `InstructorQuizAttemptsScreen` for inspecting student quiz scores.
  - Added Day 8 test suite in `test/day8_instructor_test.dart` (all passing).
- [x] **Day 9: Admin Management, State Management, Bottom Navigation and Animations**
  - Implemented `AdminDashboardModel` and `AdminProvider` with full state management for Users, Categories, Courses, Enrollments, and Reviews.
  - Created `AdminUserManagementScreen` with real-time search, role/status filter chips, and `AnimatedContainer` status badges.
  - Created `AdminCategoryManagementScreen` with category authoring, slug generation, editing, and active status toggle switches.
  - Created `AdminCourseModerationScreen` supporting inspection across DRAFT, PUBLISHED, ARCHIVED statuses and administrative archiving.
  - Created `AdminEnrollmentManagementScreen` for system-wide enrollment monitoring with course filters and completion progress.
  - Created `AdminReviewModerationScreen` featuring `AnimatedOpacity` for smooth public visibility moderation.
  - Built role-appropriate `BottomNavigationBar` navigation shells: `AdminMainScreen`, `StudentMainScreen`, and `InstructorMainScreen`.
  - Upgraded `AdminDashboardScreen` with live platform metrics and quick administrative action cards.
  - Added Day 9 test suite in `test/day9_admin_test.dart` (16/16 passing) bringing the project total to 63 passing tests.
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
