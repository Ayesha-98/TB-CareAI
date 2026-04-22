# TB-CareAI - Tuberculosis Management System

## 🌐 Live Web Dashboard
**Access the dashboard here:** https://tbcareappmain.web.app/?v=2

> **Note:** If you see a Firebase page, press `Ctrl + Shift + R` to hard refresh or open in Incognito mode.

## 📱 Mobile Apps (APK Downloads)
- [CHW App APK](./releases/chw_app.apk)
- [Patient App APK](./releases/patient_app.apk)

**Installation:** Download APK → Transfer to Android phone → Allow "Unknown Sources" → Install

## 🏗️ Project Structure
TB-CareAI/
├── mobile/
│ ├── chw_app/ # Community Health Worker App
│ └── patient_app/ # Patient Mobile App
├── web/
│ └── dashboard/ # Web Dashboard (CHW + Patient)
├── releases/ # APK files
└── README.md

## 🔧 Tech Stack
- **Frontend:** Flutter (Mobile + Web)
- **Backend:** Firebase Firestore
- **Authentication:** Firebase Auth
- **Hosting:** Firebase Hosting

## 🔐 Role-Based Access
| Role | Access |
|------|--------|
| CHW | Community Health Worker Dashboard |
| Patient | Patient Dashboard |

## 🚀 Local Development
```bash
# Mobile Apps
cd mobile/chw_app
flutter pub get
flutter run

# Web Dashboard
cd web/dashboard
flutter pub get
flutter run -d chrome
