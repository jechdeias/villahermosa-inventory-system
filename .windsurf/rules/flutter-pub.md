---
trigger: model_decision
description: - The project is first set up 
- Dependencies are added/removed from pubspec.yaml 
- Dependency conflicts occur 
- Before running the app for the first time 
- After pulling changes that modify dependencies
---

Run once in workspace:

flutter pub get
flutter pub upgrade


